# Reproducible non-SAM development and builds

Use uv 0.12.9 and the committed `uv.lock` for contributor environments and
release builds. The default profile does not install torch, torchvision,
Ultralytics or model weights. Desktop installers will not require researchers
to install uv or Python.

## Toolchain and support boundary

Install **uv 0.12.9** using the instructions at
<https://docs.astral.sh/uv/getting-started/installation/>; choose the versioned
installer or `pipx install uv==0.12.9`. `pyproject.toml` rejects other uv versions
so a tool upgrade is an explicit change.

`.python-version` pins **CPython 3.13.15** for development and native builds.
uv downloads that interpreter if needed. Source-package metadata accepts
Python 3.12 and 3.13; CI also checks 3.12.14 on Linux. Python 3.10/3.11 and
3.14+ are outside this release profile. In particular, 3.14+ image-codec
compatibility has not been validated. The range does not promise every old
patch release works; use patched interpreters.

CI targets Ubuntu 24.04, Windows Server 2022 and macOS 15 (Apple Silicon) with
the pinned Python. Passing these source-install checks does not validate frozen packages,
all desktop OS versions or every CPU architecture.

## Set up and run without SAM

From the repository root:

```bash
uv sync --locked --extra gui
uv run --no-sync fungicapture --help
uv run --no-sync fungicapture-gui
```

The default `dev` dependency group supplies the existing test tools. For a
runtime-only desktop environment, use `uv sync --locked --no-dev --extra gui`.
For a headless CLI environment, omit `--extra gui` as well. The default sync is
exact: packages outside the requested profile are removed from the managed
environment. Use a separate environment for experimental SAM work.

Run tests (Bash/Linux/macOS):

```bash
QT_QPA_PLATFORM=offscreen uv run --no-sync python -m pytest -ra
```

PowerShell:

```powershell
$env:QT_QPA_PLATFORM = "offscreen"
uv run --no-sync python -m pytest -ra
```

The suite includes synthetic classical cropping, segmentation, feature
extraction, phenotype scoring and QC/PDF reports. Synthetic success is not
biological validation. CI explicitly rejects installed SAM dependencies and
competing OpenCV distributions, and opens/closes the Qt main window offscreen.

## Build with the same dependency versions

Install the locked build group, then build the wheel and source distribution:

```bash
uv sync --locked --extra gui --group build
uv build --python .venv --no-build-isolation
```

The build group locks PyInstaller, setuptools and wheel; the dev profile
provides the licence inventory tool. `--no-build-isolation` makes the package
build use these installed tools; `--python .venv` explicitly selects that
environment (use its actual path if overriding `UV_PROJECT_ENVIRONMENT`).
Editable installation's isolated build tools
are separately constrained in `tool.uv.build-constraint-dependencies`; keep
those pins aligned with the lockfile when upgrading.

For native frozen builds, run `bash packaging/build.sh` on Linux/macOS or
`BUILD WINDOWS EXE.bat` on Windows. Both synchronize a separate `.venv-build`
environment from the lockfile, reject SAM packages, and run tests before
freezing. They do not install packages into the system Python. Do not run two
builds concurrently in the same checkout.

**These are not production-ready installers yet.** Existing packaging tasks
remain, including missing macOS icon/sample inputs, release-material assembly,
signing/notarization and clean-machine lifecycle tests. The legacy researcher
SETUP/START launchers still use their existing pip-based installation flow;
they are not the locked maintainer workflow described here. See the release
checklist before distributing frozen artifacts.

## Optional local SAM is a separate, unvalidated profile

`uv.lock` resolves optional extras too, so model-package names appear in the
lockfile even though the commands above never install them. Do not use
`--all-extras`, `--extra all` or `--extra model` for a classical build.

For a deliberate local-model experiment, set `UV_PROJECT_ENVIRONMENT` to a
separate directory such as `.venv-sam`, then run
`uv sync --locked --no-dev --extra gui --extra model`. This selects the locked
model dependencies, but **does not establish inference readiness or select a
validated CPU/CUDA/MPS runtime**. This milestone does not test SAM or download
weights. Obtain checkpoints through the approved source and record their
source, model version and SHA-256 separately; a Python lockfile cannot lock
external weights or accept licence terms for a researcher.

The uv configuration excludes `opencv-python` because it and
`opencv-python-headless` both own `cv2`; headless already supplies the API used
by this application. This is an explicit uv resolver exception for
Ultralytics' desktop-OpenCV requirement. It does not apply to downstream pip
installs or the application's pip-based setup screen, and SAM compatibility
with this policy still needs inference tests. Do not mix those install paths
into a uv-managed environment. PyPI package consumers do not automatically
inherit `uv.lock` or uv exclusions.

## Update intentionally

1. Change supported ranges or tooling pins only as needed. Update
   `.python-version` and CI's Python/uv selections together when applicable.
2. Run `uv lock --upgrade-package PACKAGE` for a focused dependency update, or
   `uv lock --upgrade` for a deliberate full refresh. Review versions, hashes,
   licence changes and transitive dependencies in `uv.lock`.
3. If setuptools/wheel change, update the isolated build constraints too.
   Re-sync with `--locked` and rerun tests, image-format checks and source/wheel
   installation checks on the CI matrix. Test the exact frozen artifacts
   separately before releasing.
4. Commit `pyproject.toml`, `uv.lock`, interpreter/tool pins and related CI/docs
   together. Never regenerate a lockfile automatically in a release job.

A lockfile controls dependency selection, not bit-identical native binaries,
model masks or numerical results across hardware and operating systems.
