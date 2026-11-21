#!/usr/bin/env bash
# Build FungiCapture for the current platform.
#
# Run from the repository root:  bash packaging/build.sh
set -euo pipefail

echo "==> Checking Python"
python3 --version

echo "==> Installing build dependencies"
python3 -m pip install --upgrade pip
# Windows has a pinned CPU build and preflight in BUILD WINDOWS EXE.bat.
# On macOS the normal PyPI wheels are CPU/MPS; Linux uses the CPU index.
export YOLO_AUTOINSTALL=false
if [[ "$(uname -s)" == Darwin ]]; then
    python3 -m pip install torch torchvision
else
    python3 -m pip install --upgrade --force-reinstall torch torchvision --index-url https://download.pytorch.org/whl/cpu
fi
python3 -m pip install -e ".[gui,model]"
python3 -m pip uninstall -y opencv-python opencv-contrib-python opencv-contrib-python-headless opencv-python-headless
python3 -m pip install --force-reinstall --no-deps 'opencv-python-headless>=4.8'
python3 -m pip install 'pyinstaller>=6,<7' 'pyinstaller-hooks-contrib>=2025.0' pip-licenses 'pytest>=7.4'

echo "==> Recording third-party licences"
pip-licenses --format=markdown --with-urls --output-file THIRD_PARTY_LICENSES.md
echo "    wrote THIRD_PARTY_LICENSES.md"

echo "==> Running tests"
python3 -m pytest -q

echo "==> Building"
pyinstaller packaging/fungicapture.spec --noconfirm

case "$(uname -s)" in
  Darwin)
    echo "==> Creating a disk image"
    hdiutil create -volname FungiCapture -srcfolder dist/FungiCapture.app \
            -ov -format UDZO dist/FungiCapture-macos.dmg
    echo "    dist/FungiCapture-macos.dmg"
    echo
    echo "    NOTE: unsigned. On first launch macOS will warn. Either"
    echo "    right-click the app and choose Open, or sign it with an"
    echo "    Apple Developer ID (99 USD/year)."
    ;;
  Linux)
    echo "==> Creating a tarball"
    (cd dist && tar czf FungiCapture-linux-x86_64.tar.gz FungiCapture)
    echo "    dist/FungiCapture-linux-x86_64.tar.gz"
    ;;
  *)
    echo "==> Windows: zip dist/FungiCapture, or build an installer with Inno Setup"
    ;;
esac

echo
echo "Done. The SAM 3 weights are NOT bundled. Users must obtain authorised"
echo "weights from Meta and import them separately. No in-app pip is bundled."
