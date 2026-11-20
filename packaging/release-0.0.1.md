Self-contained **Windows x64 non-SAM research preview**.

Download `FungiCapture-0.0.1-windows-x64-setup.exe`, verify its SHA-256 against
`SHA256SUMS.txt`, and install for your user account. No Python, uv or model
download is required. The installer adds a Start-menu shortcut and uninstaller.
It includes a labelled synthetic 18-colony sample and a console CLI alongside
the desktop application.

**Unsigned:** Windows may show unknown-publisher/SmartScreen warnings. Follow
your institution's security policy. This release has not been code-signed and
is not published through WinGet.

**SAM is not included.** Optional model installation from the frozen app is not
supported. Classical masks require visual QC; this is not a biologically
validated production release. Known saved-layout/full-run consistency limits
remain; use explicit settings and inspect reopened layouts.

The matching application source/build scripts are in
`FungiCapture-0.0.1-source.zip`; `BUILD-INFO.json` records the exact revision and
toolchain. Installer files include project/runtime licences and notices.

The release workflow tests the candidate before publication, then downloads the
published installer on a separate Windows runner and verifies its checksum,
silent installation, GUI launch, classical analysis, PDF export, reinstall and
uninstall. Check the workflow's final result for download-verification status:
publication happens before that final verification job.
