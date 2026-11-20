# Packaging FungiCapture

## Build for the current platform

Install uv 0.12.9 first; see [the maintainer setup guide](../docs/DEVELOPMENT.md).
Both native build scripts synchronize `.venv-build` from `uv.lock`, provision
the Python pinned in `.python-version`, and run the test suite before freezing.
They build the non-SAM profile without installing torch or model weights.

```bash
bash packaging/build.sh
```

On Windows, run `BUILD WINDOWS EXE.bat` instead.

Outputs land in `dist/`.

## What gets built

| Platform | Output | Notes |
|---|---|---|
| Windows | `dist/FungiCapture/` | Zip it, or wrap with Inno Setup for an installer |
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

Measure the final archive for each target; no fixed size is guaranteed. The
current build scripts intentionally omit PyTorch and the `model` extra.
