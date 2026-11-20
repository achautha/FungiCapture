#!/usr/bin/env bash
# Build FungiCapture for the current platform.
#
# Run from the repository root:  bash packaging/build.sh
set -euo pipefail

echo "==> Synchronizing the locked non-SAM build environment"
export UV_PROJECT_ENVIRONMENT=.venv-build
uv sync --locked --extra gui --group build
uv run --no-sync python --version
uv run --no-sync python -c 'import importlib.util; assert all(importlib.util.find_spec(p) is None for p in ("torch", "torchvision", "ultralytics")), "Build environment must not contain SAM dependencies"'

echo "==> Recording third-party licences"
uv run --no-sync python -m piplicenses --format=markdown --with-urls --output-file THIRD_PARTY_LICENSES.md
echo "    wrote THIRD_PARTY_LICENSES.md"

echo "==> Running tests"
QT_QPA_PLATFORM=offscreen uv run --no-sync python -m pytest -ra

echo "==> Building"
uv run --no-sync python -m PyInstaller packaging/fungicapture.spec --noconfirm

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
echo "Done. This is a non-SAM build: no model runtime or weights are bundled."
echo "Optional SAM setup in frozen applications is not yet supported."
