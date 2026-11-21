"""Qt public behavior with model inference stubbed; no weights or GPU required."""

import os

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

import pytest

pytest.importorskip("PySide6")
from PySide6.QtWidgets import QApplication, QMessageBox

from fungicapture.core.project import ImagingMode, Project
from fungicapture.gui.tabs import setup_dialog
from fungicapture.gui.tabs.simple_tabs import SegmentTab


@pytest.fixture(scope="module")
def app():
    return QApplication.instance() or QApplication([])


def test_setup_does_not_switch_project_until_explicit_confirmation(
    app, tmp_path, monkeypatch
):
    project = Project.create(tmp_path / "project", "study", ImagingMode.SINGLE_DISH)
    monkeypatch.setattr(setup_dialog, "runtime_available", lambda: True)
    monkeypatch.setattr(setup_dialog, "model_ready", lambda: True)
    monkeypatch.setattr(setup_dialog, "find_model", lambda: tmp_path / "sam3.pt")
    dialog = setup_dialog.SegmentationSetupDialog(project=project)
    assert dialog.use_button.isEnabled()
    assert Project.load(project.root).params.segmentation.backend == "classical"
    assert not dialog.sam_selected
    monkeypatch.setattr(QMessageBox, "question", lambda *a, **k: QMessageBox.No)
    dialog.use_button.click()
    assert not dialog.sam_selected
    monkeypatch.setattr(QMessageBox, "question", lambda *a, **k: QMessageBox.Yes)
    dialog.use_button.click()
    assert dialog.sam_selected
    # The caller applies the confirmed choice; setup itself never runs a job.
    assert Project.load(project.root).params.segmentation.backend == "classical"


def test_failed_setup_leaves_project_and_run_settings_classical(
    app, tmp_path, monkeypatch
):
    project = Project.create(tmp_path / "project", "study", ImagingMode.SINGLE_DISH)
    monkeypatch.setattr(setup_dialog, "runtime_available", lambda: True)
    monkeypatch.setattr(setup_dialog, "model_ready", lambda: False)
    monkeypatch.setattr(setup_dialog, "find_model", lambda: None)
    dialog = setup_dialog.SegmentationSetupDialog(project=project)
    dialog._failed("incompatible checkpoint", "example technical detail")
    assert not dialog.use_button.isEnabled()
    assert "incompatible checkpoint" in dialog.report.toPlainText()
    assert dialog.choose_button.isEnabled()
    tab = SegmentTab()
    tab.set_project(project)
    assert tab.collect()["backend"] == "classical"
    assert Project.load(project.root).params.segmentation.backend == "classical"


def test_copy_progress_handles_model_larger_than_qt_int(app, tmp_path):
    from fungicapture.gui.workers import PipelineWorker

    dialog = setup_dialog.SegmentationSetupDialog()
    worker = PipelineWorker(lambda progress: None)
    worker.progressed.connect(dialog._progress)
    worker._progress(3_000_000_000, 3_450_062_241, "Copying model")
    assert dialog.progress.maximum() == 1000
    assert dialog.progress.value() == 869
    assert dialog.status.text() == "Copying model"
