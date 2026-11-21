# FungiCapture 0.1.0-rc.1

Release candidate for optional local SAM 3 on Windows. This version is prepared
in source, not yet published as a downloadable Windows installer.

Python package and application version: `0.1.0rc1` (PEP 440).
Planned Git tag / GitHub prerelease name: `v0.1.0-rc.1`.
Planned installer: `FungiCapture-0.1.0rc1-windows-x64-setup.exe`.

## What changed

- Windows packaging includes the CPU SAM runtime and tokenizer. Model weights
  are not bundled; obtain authorised `sam3.pt` weights from Meta's official page.
- Native setup supports model import, copy progress, cancellation, local
  inference verification, error recovery and a one-crop preview.
- Classical remains the default. Importing a model does not switch a project
  to SAM: activation requires confirmation and the method is saved per project.
- A re-run warns before replacing existing masks; regenerate features and
  phenotypes after segmentation changes. Preview leaves saved masks untouched.
- The packaged application does not install Python dependencies at runtime.
- About/version output and new run provenance use the application version.

## Upgrading from Windows 0.0.1

1. Back up project folders and close FungiCapture.
2. Once a tested installer is published, download it from this repository's
   GitHub Releases. Run it as the same Windows user who installed 0.0.1.
3. Install over the existing application. Do not uninstall 0.0.1 first.
   The installer retains its AppId, per-user scope and previous install path.
4. Open an existing project and confirm its folders and settings. Projects
   without a saved method use Classical. Existing results are not regenerated.
5. Optionally choose Segmentation setup, import and verify the model, preview
   a crop and confirm SAM for that project. Classical needs no model download.

Projects, preferences and cached models are intended to be preserved. Actual
0.0.1 in-place upgrade and uninstall-preservation checks are still required on
Windows. There is no automatic update checker or background model downloader.

## Validation and release blockers

Linux tests, no-weights CPU runtime/tokenizer checks, native Qt interaction
checks and a Linux frozen build passed. Ready/preview UI captures used fixtures,
not trained SAM output. A frozen model-loading probe exceeded the orb's roughly
4 GB memory limit; CPU requirements and timings remain unmeasured.

Before publishing the Windows prerelease:

- [ ] Build on Windows x64 using `BUILD WINDOWS EXE.bat`.
- [ ] Compile `packaging/windows.iss` with `/DAppVersion=0.1.0rc1`.
- [ ] Launch on a clean Windows machine without Python; verify native DLLs.
- [ ] Upgrade 0.0.1 in place; verify projects, preferences and one app entry.
- [ ] Test Classical, import/cancel/retry and authorised-weight SAM inference.
- [ ] Verify offline inference and crop preview with real weights.
- [ ] Check uninstall preserves external projects, preferences and models.
- [ ] Measure model memory use, CPU performance, installer size and install time.

Creating this document does not create a Git tag or publish a GitHub release.

## Versioning policy

Use `major.minor.patch`. Patch releases fix bugs without changing project
formats or scientific behavior. Minor releases add capabilities; before 1.0,
they may also introduce documented breaking changes. Clearly identify changes
to segmentation or measurements that affect scientific results. Reserve 1.0.0
for a stable release with a defined compatibility policy.

Use GitHub prereleases for release candidates (`v0.1.0-rc.1`, then `rc.2` as
needed); use PEP 440 spellings (`0.1.0rc1`) in Python and installer metadata.
Promote to `v0.1.0` / `0.1.0` only after the release checks pass. Keep the Windows
AppId constant across versions. The macOS numeric bundle short version remains
`0.1.0`; this release candidate targets Windows validation.
