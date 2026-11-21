"""Local setup's transaction and project-choice contracts, without gated weights."""

from dataclasses import replace

import pytest

from fungicapture.core import sam_setup, segment
from fungicapture.core.params import AnalysisParams
from fungicapture.core.project import ImagingMode, Project


@pytest.fixture
def cache(tmp_path, monkeypatch):
    root = tmp_path / "models"
    root.mkdir()
    monkeypatch.setattr(segment, "model_cache_dir", lambda: root)
    monkeypatch.setattr(sam_setup, "model_cache_dir", lambda: root)
    monkeypatch.setattr(
        sam_setup,
        "find_model",
        lambda: root / "sam3.pt" if (root / "sam3.pt").exists() else None,
    )
    monkeypatch.setattr(
        sam_setup.importlib.metadata, "version", lambda name: "test-runtime"
    )
    return root


def test_import_requires_check_and_preserves_verified_model_on_failure(
    cache, tmp_path, monkeypatch
):
    source = tmp_path / "download.pt"
    source.write_bytes(b"example checkpoint bytes")
    monkeypatch.setattr(sam_setup, "run_model_check", lambda *a, **k: {})
    destination = sam_setup.import_model(source)
    assert destination.read_bytes() == source.read_bytes()
    assert sam_setup.model_ready()

    replacement = tmp_path / "replacement.pt"
    replacement.write_bytes(b"incompatible replacement")

    with monkeypatch.context() as missing_metadata:

        def unavailable(name):
            raise sam_setup.importlib.metadata.PackageNotFoundError(name)

        missing_metadata.setattr(sam_setup.importlib.metadata, "version", unavailable)
        with pytest.raises(sam_setup.importlib.metadata.PackageNotFoundError):
            sam_setup.import_model(replacement)
    assert destination.read_bytes() == b"example checkpoint bytes"
    assert sam_setup.model_ready()

    def fail(*args, **kwargs):
        raise RuntimeError("incompatible checkpoint")

    monkeypatch.setattr(sam_setup, "run_model_check", fail)
    with pytest.raises(RuntimeError, match="incompatible"):
        sam_setup.import_model(replacement)
    assert destination.read_bytes() == b"example checkpoint bytes"
    assert replacement.read_bytes() == b"incompatible replacement"
    assert sam_setup.model_ready()
    assert not list(cache.glob("import-*"))

    destination.write_bytes(b"changed after verification")
    assert not sam_setup.model_ready()


def test_cancelled_copy_never_publishes_model(cache, tmp_path):
    source = tmp_path / "sam3.pt"
    source.write_bytes(b"download" * 100)
    with pytest.raises(sam_setup.SetupCancelled):
        sam_setup.import_model(source, progress=lambda done, total, message: done == 0)
    assert source.read_bytes() == b"download" * 100
    assert not (cache / "sam3.pt").exists()
    assert not sam_setup.model_ready()
    assert not list(cache.glob("import-*"))


def test_low_disk_space_leaves_existing_model_unchanged(cache, tmp_path, monkeypatch):
    from collections import namedtuple

    destination = cache / "sam3.pt"
    destination.write_bytes(b"old model")
    source = tmp_path / "download.pt"
    source.write_bytes(b"new model")
    usage = namedtuple("Usage", "total used free")
    monkeypatch.setattr(sam_setup.shutil, "disk_usage", lambda path: usage(100, 100, 0))
    with pytest.raises(OSError, match="free space"):
        sam_setup.import_model(source)
    assert destination.read_bytes() == b"old model"


def test_legacy_project_stays_classical_and_explicit_sam_survives_reload(tmp_path):
    project = Project.create(tmp_path / "project", "test", ImagingMode.SINGLE_DISH)
    text = project.config_path.read_text()
    project.config_path.write_text(text.replace('backend = "classical"\n', ""))
    loaded = Project.load(project.root)
    assert loaded.params.segmentation.backend == "classical"
    loaded.params = loaded.params.with_changes(
        segmentation=replace(loaded.params.segmentation, backend="sam3")
    )
    loaded.save()
    assert Project.load(project.root).params.segmentation.backend == "sam3"
    assert AnalysisParams.from_dict({}).segmentation.backend == "classical"


def test_pipeline_uses_saved_classical_choice_even_when_sam_weights_exist(
    tmp_path, monkeypatch
):
    import numpy as np
    from PIL import Image
    from fungicapture.core.pipeline import segment_crops

    project = Project.create(tmp_path / "project", "test", ImagingMode.SINGLE_DISH)
    rgb = np.full((60, 80, 3), 220, dtype=np.uint8)
    rgb[15:42, 20:58] = (80, 45, 15)
    Image.fromarray(rgb).save(project.crops_dir / "colony.png")
    model = tmp_path / "sam3.pt"
    model.write_bytes(b"weights exist, not activated")
    monkeypatch.setattr(segment, "find_model", lambda: model)
    result = segment_crops(project, save_overlays=False)
    assert result.data["backend"] == "classical"
    assert result.n_outputs == 1
    assert result.errors == []
    with Image.open(result.outputs[0]) as mask:
        assert np.count_nonzero(np.asarray(mask)) == 27 * 38


def test_isolated_check_reports_missing_weights_and_cleans_up(cache, tmp_path):
    with pytest.raises(RuntimeError, match="weights not found"):
        sam_setup.run_model_check(tmp_path / "missing-sam3.pt")
    assert not list(cache.glob("check-*"))


def test_cancelled_child_check_exits_and_cleans_up(cache, tmp_path):
    with pytest.raises(sam_setup.SetupCancelled):
        sam_setup.run_model_check(
            tmp_path / "missing-sam3.pt", progress=lambda *args: False
        )
    assert not list(cache.glob("check-*"))
