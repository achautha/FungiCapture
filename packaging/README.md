# Packaging FungiCapture

## Build for the current platform

```bash
bash packaging/build.sh
```

Outputs land in `dist/`.

## Standard Windows CPU SAM build

Run `BUILD WINDOWS EXE.bat` on Windows x64 with 64-bit Python 3.10–3.13
(3.12 recommended). It installs `.[gui,model]`, pins CPU-only
`torch==2.7.1+cpu` / `torchvision==0.22.1+cpu` from PyTorch's CPU index and
`ultralytics==8.3.237`. The SAM dependencies `ftfy==6.3.1`,
`regex==2025.11.3`, `iopath==0.1.10` and `timm==1.0.22` are pinned in
`windows-constraints.txt`. The source `model` extra also declares these four
dependencies (with minimum versions), because Ultralytics does not declare
them in its base metadata. Changing the pins requires repeating SAM API and
operator checks. This is not a complete transitive dependency lock.

Ultralytics declares desktop `opencv-python`, which conflicts with headless
OpenCV in the same `cv2` tree. The build removes all installed OpenCV variants
and reinstalls **only** `opencv-python-headless`, without dependencies. A
subsequent model-extra install can reinstall desktop OpenCV; repeat the repair
afterwards. `pip check` will report Ultralytics' missing desktop distribution
even though its `cv2` API is supplied by headless. Do not "fix" this by bundling
both distributions.

The build runs `packaging/check_sam_runtime.py` before PyInstaller. It checks
CPU torch/torchvision, headless OpenCV, SAM3 imports, tokenizer integrity and
tokenization, a small SAM vision block and torchvision NMS. It does **not**
load weights or establish trained-model readiness. PyInstaller collects lazy
SAM/timm modules, package data and optional-dependency metadata; standard
PyInstaller torch/torchvision hooks handle native libraries. A runtime hook
forces `YOLO_AUTOINSTALL=false` and `YOLO_OFFLINE=true` (including no import-time
DNS probe), and pip/ensurepip are excluded. The application
must also reject dependency installation when frozen (owned by core setup).

### Tokenizer contract (no runtime download)

The committed asset is
`src/fungicapture/resources/bpe_simple_vocab_16e6.txt.gz`. It is the unchanged
OpenAI CLIP vocabulary, not SAM weights; source, SHA-256 and MIT copyright/
licence are in `packaging/tokenizer-LICENSE.txt`. The licence is included in
source/wheel distributions via setuptools data-files and in the frozen bundle.

The spec places the asset at `fungicapture/resources/` under PyInstaller's
internal content root (`dist/FungiCapture/_internal/` with PyInstaller 6).
From `core/segment.py`, source and frozen code both resolve it as:

```python
Path(__file__).resolve().parents[1] / "resources" / "bpe_simple_vocab_16e6.txt.gz"
```

Inspected Ultralytics **8.3.237** APIs:

* `ultralytics.models.sam.predict.SAM3SemanticPredictor(cfg=DEFAULT_CFG,
  overrides=None, _callbacks=None, bpe_path=None)` stores `bpe_path` and passes
  it into `build_sam3_image_model` in `get_model()`.
* `ultralytics.models.sam.build_sam3.build_sam3_image_model(checkpoint_path,
  bpe_path, enable_segmentation=True, compile=False)` constructs
  `SimpleTokenizer(bpe_path=bpe_path)`.
* `ultralytics.models.sam.sam3.tokenizer_ve.SimpleTokenizer(bpe_path,
  additional_special_tokens=None, context_length=77, clean="lower")` opens
  that local gzip through `iopath.common.file_io.g_pathmgr`, using ftfy and
  regex. It does not need to fetch a vocabulary. Pass a verified local path,
  never `None` or a URL. Missing/corrupt assets must be reported, not downloaded.

### Installer / in-place upgrade

The prepared release candidate is `0.1.0rc1` in package/application metadata,
with planned Git tag `v0.1.0-rc.1`. See the [release notes and Windows release
checklist](../docs/RELEASE_NOTES_0.1.0-rc.1.md) before publication.

After the folder build, install Inno Setup 6.3+ and compile locally, supplying
the actual release version (no upload or publication is part of this command):

```bat
ISCC.exe /DAppVersion=0.1.0rc1 packaging\windows.iss
```

Output: `dist/installer/FungiCapture-<version>-windows-x64-setup.exe`.
The installer retains release AppId
`{B4B45D16-18AB-4F51-88C5-83A50C765F6C}`, per-user scope and default directory
`{localappdata}\Programs\FungiCapture`, reuses the prior installation path and
overwrites program files without uninstalling first. There are no recursive
cleanup rules for projects, preferences or imported models. Obsolete program
files are deliberately not swept recursively, to avoid deleting user data.

Before releasing, test on Windows: install 0.0.1 as a normal user, create a
project and preferences, upgrade with this installer, check preservation and
one installed-app entry, start Classical, then run the packaged SAM probe and
authorised-weight inference offline. Also test uninstall preserves external
projects/preferences/models, and clean-machine native DLL loading. These
Windows checks and installer size/timing are not established by Linux smoke
tests.

## What gets built

| Platform | Output | Notes |
|---|---|---|
| Windows | `dist/FungiCapture/` | CPU SAM runtime; `windows.iss` wraps it with Inno Setup |
| macOS | `dist/FungiCapture-macos.dmg` | Unsigned — see below |
| Linux | `dist/FungiCapture-linux-x86_64.tar.gz` | Runs on most distributions |

## Two things that are deliberate

**One-folder, not one-file.** PySide6 is LGPL-3.0, which obliges us to let a
user replace the Qt libraries. A one-file bundle unpacks to a temporary
directory and makes that impossible. This is a licence requirement, not a
preference.

**The SAM 3 weights are not bundled.** They are covered by Meta's restricted
SAM License and are gated behind an access request, so the application sends
the user to Meta's own page and caches the file locally. Never mirror the
weights in a release. See `docs/LICENSING.md`.

## macOS signing

Without an Apple Developer ID (99 USD/year), Gatekeeper shows a warning on
first launch. Users can right-click the app and choose Open to get past it, but
for a conference release signing is worth the money.

With a certificate:

```bash
codesign --deep --force --options runtime \
         --sign "Developer ID Application: YOUR NAME (TEAMID)" \
         dist/FungiCapture.app
xcrun notarytool submit dist/FungiCapture-macos.dmg \
      --apple-id YOU@EXAMPLE.COM --team-id TEAMID --wait
xcrun stapler staple dist/FungiCapture-macos.dmg
```

## Size

Final CPU SAM bundle/installer size is unmeasured. The standard specification
requires the model runtime and tokenizer, but never bundles model weights.
A classical-only distribution would need a separate specification; do not
silently omit SAM from the standard Windows build.
