"""Transactional local model setup and isolated SAM checks, without Qt.

The worker is also dispatched by the frozen entry point. Model loading can
exhaust memory or crash native libraries; neither should take down setup.
"""

from __future__ import annotations

import importlib.metadata
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

from .segment import find_model, model_cache_dir

RUNTIME_PACKAGES = (
    "torch",
    "torchvision",
    "ultralytics",
    "ftfy",
    "regex",
    "iopath",
    "timm",
)


class SetupCancelled(RuntimeError):
    pass


def runtime_available() -> bool:
    """Presence only. Ready requires a successful model inference check."""
    return all(importlib.util.find_spec(name) is not None for name in RUNTIME_PACKAGES)


def _signature(path: Path) -> dict:
    stat = path.stat()
    return {
        "path": str(path.resolve()),
        "size": stat.st_size,
        "mtime_ns": stat.st_mtime_ns,
        "runtime": {
            name: importlib.metadata.version(name) for name in RUNTIME_PACKAGES
        },
    }


def model_ready(path: Path | None = None) -> bool:
    path = path or find_model()
    if path is None:
        return False
    tokenizer = (
        Path(__file__).resolve().parents[1]
        / "resources"
        / "bpe_simple_vocab_16e6.txt.gz"
    )
    if not tokenizer.is_file():
        return False
    try:
        receipt = json.loads((model_cache_dir() / "verified.json").read_text())
        return receipt["signature"] == _signature(path)
    except (OSError, ValueError, KeyError, importlib.metadata.PackageNotFoundError):
        return False


def _continue(progress, done=0, total=0, message=""):
    if progress(done, total, message) is False:
        raise SetupCancelled("Setup cancelled. The original model file is unchanged.")


def run_model_check(
    weights: Path,
    *,
    image: Path | None = None,
    params=None,
    progress=lambda *args: True,
) -> dict:
    """Load and infer in a child process; cancel/timeout kills only that child."""
    with tempfile.TemporaryDirectory(
        prefix="check-", dir=model_cache_dir()
    ) as directory:
        root = Path(directory)
        request = root / "request.json"
        output = root / "result.json"
        request.write_text(
            json.dumps(
                {
                    "weights": str(weights.resolve()),
                    "image": str(image.resolve()) if image else None,
                    "params": params or {},
                }
            ),
            encoding="utf-8",
        )
        command = [sys.executable]
        if getattr(sys, "frozen", False):
            command += ["--sam-worker"]
        else:
            command += ["-m", "fungicapture.core.sam_setup"]
        command += [str(request), str(output)]
        env = dict(os.environ, YOLO_AUTOINSTALL="false", YOLO_OFFLINE="true")
        # On Windows the child uses our own frozen runtime, so retain its DLL
        # search environment. No system Python or external installer is launched.
        with (root / "worker.log").open("w", encoding="utf-8") as log:
            child = subprocess.Popen(
                command,
                stdout=log,
                stderr=log,
                env=env,
                creationflags=subprocess.CREATE_NO_WINDOW
                if sys.platform == "win32"
                else 0,
            )
            try:
                started = time.monotonic()
                while child.poll() is None:
                    _continue(
                        progress,
                        message="Loading model and running local CPU inference…",
                    )
                    if time.monotonic() - started > 1800:
                        raise RuntimeError(
                            "SAM check timed out after 30 minutes. Keep Classical or try a machine with more memory."
                        )
                    time.sleep(0.1)
            finally:
                if child.poll() is None:
                    child.kill()
                child.wait()
        if not output.exists():
            raise RuntimeError(
                f"SAM check stopped (exit {child.returncode}). The runtime may have failed "
                "or the computer may have insufficient memory. Classical remains available."
            )
        result = json.loads(output.read_text(encoding="utf-8"))
        if "error" in result:
            raise RuntimeError(result["error"])
        if child.returncode != 0:
            raise RuntimeError(f"SAM check failed (exit {child.returncode}).")
        _continue(progress)
        if image:
            import numpy as np

            result["mask"] = np.load(root / "mask.npy", allow_pickle=False)
        return result


def import_model(source: str | Path, *, progress=lambda *args: True) -> Path:
    """Copy, verify, then atomically publish. A failed replacement keeps the old model."""
    source = Path(source).expanduser().resolve()
    if not source.is_file() or source.suffix.lower() != ".pt":
        raise ValueError(
            "Choose an authorised sam3.pt file from the official model page."
        )
    if source.stat().st_size == 0:
        raise ValueError(
            "The model file is empty. Download the complete sam3.pt file first."
        )
    override = os.environ.get("FUNGICAPTURE_SAM3_WEIGHTS")
    if override and Path(override).expanduser().resolve() != source:
        raise ValueError(
            "FUNGICAPTURE_SAM3_WEIGHTS selects a different model. Check that file "
            "instead, or clear the environment override before importing another model."
        )
    destination = source if override else model_cache_dir() / "sam3.pt"
    copying = source != destination.resolve()
    if copying and shutil.disk_usage(destination.parent).free < source.stat().st_size:
        raise OSError(
            "Not enough free space for the imported model copy. Free disk space and try again."
        )
    with tempfile.TemporaryDirectory(
        prefix="import-", dir=model_cache_dir()
    ) as directory:
        staged = source
        if copying:
            staged = Path(directory) / "sam3.pt"
            size, done = source.stat().st_size, 0
            with source.open("rb") as incoming, staged.open("wb") as outgoing:
                _continue(progress, 0, size, "Copying model…")
                while block := incoming.read(4 * 1024 * 1024):
                    outgoing.write(block)
                    done += len(block)
                    _continue(progress, done, size, "Copying model…")
        run_model_check(staged, progress=progress)
        _continue(progress)
        # Resolve metadata and write the receipt before touching an existing
        # model, so a missing package or full disk cannot destroy a good import.
        signature = _signature(staged)
        signature["path"] = str(destination.resolve())
        temporary = Path(directory) / "verified.json"
        temporary.write_text(json.dumps({"signature": signature}), encoding="utf-8")
        if copying:
            os.replace(staged, destination)
        os.replace(temporary, model_cache_dir() / "verified.json")
    return destination


def worker_main(arguments: list[str]) -> int:
    """Internal source/frozen worker entry. Never creates a GUI or downloads weights."""
    request_path, output_path = map(Path, arguments)
    try:
        from .params import SegmentationParams
        from .segment import Sam3Segmenter
        from .features.regions import load_rgb
        import numpy as np
        from PIL import Image

        request = json.loads(request_path.read_text(encoding="utf-8"))
        image = request.get("image")
        if not image:
            yy, xx = np.ogrid[:96, :128]
            rgb = np.full((96, 128, 3), 220, np.uint8)
            rgb[(xx - 60) ** 2 + (yy - 45) ** 2 < 25**2] = (100, 80, 45)
            image = str(output_path.parent / "check.png")
            Image.fromarray(rgb).save(image)
        params = SegmentationParams(**dict(request.get("params", {}), device="cpu"))
        segmenter = Sam3Segmenter(params, request["weights"])
        result = segmenter.segment(image)
        rgb = load_rgb(image)
        if result.mask.shape != rgb.shape[:2] or result.mask.dtype != np.bool_:
            raise ValueError("SAM returned an invalid mask shape or type.")
        np.save(output_path.parent / "mask.npy", result.mask, allow_pickle=False)
        output = {"checksum": result.model_checksum, "warnings": result.warnings}
        code = 0
    except Exception as error:
        output = {
            "error": f"Model load/inference failed: {error}\nUse the official sam3.pt and ensure enough memory is available."
        }
        code = 1
    output_path.write_text(json.dumps(output), encoding="utf-8")
    return code


if __name__ == "__main__":
    raise SystemExit(worker_main(sys.argv[1:]))
