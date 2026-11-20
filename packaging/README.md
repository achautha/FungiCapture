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

**One-folder, not one-file.** This layout supports replacing PySide6/Qt shared
libraries as part of meeting LGPL obligations. It does not by itself establish
compliance; review the actual build and accompanying materials. One-file
packaging is not categorically prohibited in every circumstance.

**The SAM 3 weights are not bundled.** They are covered by Meta's restricted
SAM License and access process. Leaving them out is project policy, not a
blanket prohibition on redistribution in that licence. Direct users to Meta's
official page rather than mirroring weights in a release.

Before publishing, complete the [distribution checklist](../docs/LICENSING.md#before-a-maintainer-distributes-a-linux-or-windows-build)
and include the [researcher onboarding](../docs/RESEARCHER_ONBOARDING.md), user
guide and licensing guidance with the archive. These are release requirements,
not a claim that the current scripts already copy every required file.

The current frozen executable cannot install optional SAM dependencies into
itself through `pip`; do not advertise the source-installation setup button as
a working standalone SAM installer. See the onboarding guide for current limits.

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
