# FungiCapture 0.0.1 for Windows x64

This self-contained **non-SAM research preview** includes Python, Qt and the
scientific runtime. You do not need to install Python, uv or model weights.
Install for your own account, then open FungiCapture from the Start menu.
Windows 10 1809+ is the installer minimum; the automated native checks run on
Windows Server 2022, not every Windows desktop/graphics configuration.

**This first installer is unsigned.** Windows may display an unknown-publisher
or SmartScreen warning. Check that you downloaded it from the project's GitHub
release and verify SHA-256 against the accompanying checksum. A checksum is an
integrity check, not a code-signing identity guarantee. Follow your institution's
software policy; do not bypass institutional security controls.

## First run

Create a project in Documents or another writable research folder, outside the
installation directory. Choose the classical segmentation backend explicitly.
For a synthetic demonstration, copy `sample_dataset` from the installation
folder to Documents. It contains three generated plates, each with a 2 × 3 grid
(18 colonies total). Use plate-batch mode, 2 rows, 3 columns. These are synthetic
fixtures, not biological observations or evidence of scientific accuracy.

The GUI executable is `FungiCapture.exe`. For terminal use,
`FungiCapture-cli.exe` supports `--version`, `new`, `run`, `report` and `info`.
Upgrades reuse the application identity. Uninstall removes application files,
not projects stored outside the installation folder.

## SAM and scientific limitations

This build does not contain torch, Ultralytics, SAM code or weights. The
application's optional pip-based SAM setup is not supported in this frozen
build; do not use it. Use a separately supported source environment if you need
SAM. Obtain any weights through the official provider and review their terms.
No model licence is accepted on your behalf by this installer.

Inspect segmentation masks before interpreting measurements. Known saved-layout
and full-run setting-consistency limitations remain; prefer individual steps
with explicit settings and visually recheck layouts after reopening projects.
Synthetic automated checks do not validate biological accuracy.

## Licences and matching source

FungiCapture is AGPL-3.0-or-later; see LICENSE and NOTICE.md. The `_internal`
folder preserves collected dependency metadata/licence texts, including Qt,
OpenCV and codecs. The one-folder layout leaves shared libraries accessible.
The matching `FungiCapture-0.0.1-source.zip` release asset contains the application
source, lockfile, build scripts and build provenance. BUILD-INFO.json identifies
the precise source revision, Python, uv and Inno Setup versions. Python's licence
and bundled runtime notices are included with the application.

Support and source: https://github.com/achautha/FungiCapture
