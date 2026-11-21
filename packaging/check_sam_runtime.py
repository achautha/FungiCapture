"""Build-time smoke check, no weights, downloads or readiness claims."""

import hashlib
import importlib.metadata
import os
from pathlib import Path

os.environ["YOLO_AUTOINSTALL"] = "false"
os.environ["YOLO_OFFLINE"] = "true"


def main():
    import cv2
    import torch
    import torchvision
    import ultralytics
    import fungicapture
    from ultralytics.models.sam.build_sam3 import build_sam3_image_model
    from ultralytics.models.sam.predict import SAM3SemanticPredictor
    from ultralytics.models.sam.sam3.tokenizer_ve import SimpleTokenizer
    from ultralytics.models.sam.sam3.vitdet import Block

    assert torch.version.cuda is None, "Build must use CPU torch, not CUDA"
    assert "+cpu" in torch.__version__, "Build must use CPU torch wheels"
    assert "+cpu" in torchvision.__version__, "Build must use CPU torchvision"
    for package in ("torch", "torchvision", "ultralytics", "ftfy", "regex", "iopath", "timm"):
        assert importlib.metadata.version(package), f"Missing metadata for {package}"
    for name in ("opencv-python", "opencv-contrib-python", "opencv-contrib-python-headless"):
        try:
            importlib.metadata.version(name)
        except importlib.metadata.PackageNotFoundError:
            continue
        raise RuntimeError(f"Remove conflicting OpenCV distribution: {name}")
    importlib.metadata.version("opencv-python-headless")
    assert "GUI:                           NONE" in cv2.getBuildInformation()
    path = Path(fungicapture.__file__).resolve().parent / "resources/bpe_simple_vocab_16e6.txt.gz"
    assert hashlib.sha256(path.read_bytes()).hexdigest() == (
        "924691ac288e54409236115652ad4aa250f48203de50a9e4722a6ecd48d6804a"
    ), "Unexpected tokenizer bytes"
    predictor = SAM3SemanticPredictor(
        overrides={"model": "sam3.pt", "device": "cpu"}, bpe_path=str(path)
    )
    assert predictor.bpe_path == str(path)
    assert predictor.model is None, "Constructor must not load weights"
    tokens = SimpleTokenizer(bpe_path=str(path))(["fungal colony", "fine fungal filaments"])
    assert tuple(tokens.shape) == (2, 77)
    assert not torch.equal(tokens[0], tokens[1])
    with torch.inference_mode():
        result = Block(dim=64, num_heads=4)(torch.ones((1, 3, 5, 64)))
    assert result.shape == (1, 3, 5, 64) and torch.isfinite(result).all()
    keep = torchvision.ops.nms(
        torch.tensor([[0., 0., 8., 8.], [1., 1., 7., 7.], [20., 1., 24., 4.]]),
        torch.tensor([.9, .8, .7]), .5,
    )
    assert keep.tolist() == [0, 2]
    assert callable(build_sam3_image_model) and callable(SAM3SemanticPredictor)
    print(f"CPU SAM imports/tokenizer/operators OK: torch {torch.__version__}, "
          f"torchvision {torchvision.__version__}, ultralytics {ultralytics.__version__}")
    print("No checkpoint loaded; trained SAM inference NOT tested.")


if __name__ == "__main__":
    main()
