# Windows SAM upgrade and setup design

Keep FungiCapture's existing Qt tabs, Settings group, buttons and Segmentation setup dialog. Bundle the CPU runtime in a SAM-enabled installer and import model weights separately. Classical remains selected until the user explicitly chooses SAM for a project.

**Status:** Implemented in source for `0.1.0rc1`: bundled CPU runtime packaging, model import and verification, native Qt setup/preview, and explicit per-project activation. Not released. Linux checks and a frozen Linux build have run; Windows upgrade and trained-model inference remain unverified. See [release notes](RELEASE_NOTES_0.1.0-rc.1.md) for the upgrade instructions and release checklist.

## Review the prototype

Open [the self-contained HTML prototype](design/sam-setup.html) in a browser. It needs no server, build or dependencies. Use the Review screen menu to inspect individual states, follow the buttons through the flow, or choose Reset flow.

All file operations, checks, progress and colony imagery are simulated. Choose file does not read a file. The simulated transition buttons are review controls, not proposed production buttons. The official model-page link opens an external website; the prototype itself does not download anything.

## Upgrade and setup flow

1. **Upgrade notice:** After the SAM-enabled installer completes, show that the CPU runtime is installed, weights are missing and the project method is unchanged. Offer Set up SAM or Keep using Classical. This is an application notice, not a replacement installer wizard.
2. **Segment settings:** Retain the Backend selector, Segmentation setup and Install weights entry points. Show model readiness separately from the project's method. Selecting unavailable SAM opens setup rather than silently running Classical.
3. **Add model:** Link to [Meta's official SAM 3 model page](https://huggingface.co/facebook/sam3). Explain account/licence approval, approximately 3.45 GB for `sam3.pt`, browser download, trusted-file requirements and space for the imported copy. No in-app background downloader in this minimal version.
4. **Copy and verify:** Check available disk space, then copy off the UI thread to temporary per-user storage with real byte progress. Cancel removes the incomplete imported copy, not the source. Load the model and run a small local inference check before publishing it as ready.
5. **Failure and recovery:** Explain the actual failed stage. Offer retry, another file or Classical. The prototype illustrates an incompatible checkpoint; disk-full and insufficient-memory failures need specific recovery messages.
6. **Ready:** SAM can run locally on CPU, but the project still uses Classical. Warn that CPU processing may be slow; do not promise unmeasured timings.
7. **Preview:** Inspect a mask overlay on a project crop and adjust the prompt without changing saved masks. The native dialog runs the same isolated local inference worker. The prototype and ready-state UI test fixtures use synthetic imagery, not trained inference.
8. **Confirm project switch:** Explicitly select SAM without starting segmentation. Explain that a later re-run replaces masks and requires regenerating dependent features and phenotypes. Switching back to Classical does not uninstall the model.

## Reuse the current components

Paths below are relative to `src/fungicapture/`.

| Existing owner | Implemented change |
| --- | --- |
| `gui/main_window.py` | One-time post-upgrade notice; retain menus, project header and workflow tabs. |
| `gui/tabs/simple_tabs.py` | Retain the Settings form and setup/model buttons. Use readable method labels, separate readiness and persistent explicit project choices. |
| `gui/tabs/setup_dialog.py` | Adapt the existing 720 × 620 dialog to add/import/check/ready/error states. The bundled-runtime build should not offer pip-based PyTorch installation. Keep technical details expandable. |
| Existing background-worker pattern | Copy and verify without blocking Qt; define cancellation cleanup and model publication behavior. |

Use platform fonts, pale gray dialog backgrounds, thin group-box borders and ordinary Qt controls. Do not introduce a dashboard, side navigation or new theme. The HTML approximates Qt rather than rendering actual Qt widgets. At narrow review widths, the header and controls wrap; the production target remains Windows desktop.

Accessibility expectations include labelled controls, normal keyboard traversal, visible focus, text accompanying status dots, accessible progress descriptions and focus restoration after dialog transitions.

## Feasibility findings and implementation limits

- The released `0.0.1` frozen executable excludes the SAM runtime and disables dependency installation. Model weights alone cannot add SAM to that executable.
- Local SAM integration now uses an explicit bundled tokenizer, disables upstream autoinstall, and propagates inference errors. Model setup and preview run in an isolated worker; no automatic model downloader is included.
- Intended in-place upgrade behavior must be validated on Windows, including preservation of projects and preferences. The design is not evidence that upgrade behavior works.
- Runtime packaging includes `ftfy`, `regex`, `iopath`, `timm`, the tokenizer and its attribution, and dependency metadata. Windows builds pin the CPU runtime and run a no-weights preflight. Windows DLL handling and prerequisites still need validation.
- The Linux feasibility checks did not establish Windows or trained-SAM compatibility. No authorised weights were available for an inference test.
- Candidate CPU SAM-only wheels were approximately 292 MB extra. Final installer size and extraction/install time remain unmeasured. The separate model is 3,450,062,241 bytes, approximately 3.45 GB.
- New and legacy projects without a saved choice use Classical. Explicit choices persist in project TOML; the CLI follows that choice unless overridden. Explicit CLI `--backend auto` remains available.
- Existing masks/overlays can be replaced by segmentation. The GUI warns before re-running into existing mask output. Preserving prior result versions is outside scope.
- Background downloads, public APIs, remote execution, GPU installation and automatic updates are outside this design's minimal scope.

## Validation performed on the prototype

Browser interaction checks established that:

- Failure or cancellation leaves Classical usable.
- Selecting SAM before setup opens setup.
- Successful model setup alone leaves Classical selected.
- Activation selects SAM without starting segmentation.
- Switching back to Classical keeps the verified model available.
- At a 360 px review width, the document width was 360 px with no horizontal overflow.

Desktop and narrow screenshots were inspected. A narrow header-spacing issue was corrected and recaptured. Browser errors returned no entries. A recorded clickthrough covered setup, import, failure/retry, readiness, preview and confirmation. These checks validate the mockup only, not real file operations, runtime packaging or inference.

## Implementation validation

- `PYTHONPATH=src QT_QPA_PLATFORM=offscreen python -m pytest tests -q`: 10 passed, including failed replacement, cancellation, disk-full preflight, metadata failure, legacy persistence, real Classical segmentation with weights present, real isolated missing-file errors and Qt activation controls. Test inference success is stubbed.
- `PYTHONPATH=src python packaging/check_sam_runtime.py`: CPU SAM imports, tokenizer, predictor construction without weights, a small vision block and torchvision NMS passed. The same dependency check passed with socket/DNS access forbidden.
- Wheel/sdist inspections confirmed tokenizer, attribution and model-extra dependencies. A full Linux PyInstaller build completed; frozen `--sam-worker` dispatch returned a structured missing-model error without launching the GUI.
- A further frozen invalid-checkpoint probe was killed by the orb's approximately 4 GB memory limit before producing a result. It is not a passing inference test or evidence of a minimum Windows RAM requirement. Real model loading, peak memory and timings need measurement on the target Windows machine.
- Native Qt screenshots were inspected for Classical, import, progress, failure, ready and preview states. Ready/preview screenshots are explicitly synthetic UI fixtures. A recorded real pointer/keyboard interaction confirmed that selecting unavailable SAM opens setup and cancellation returns to Classical.
- The Windows installer uses the 0.0.1 AppId and per-user install scope, but actual installation, upgrade, uninstall preservation and Windows DLL loading have not been exercised. Follow the checklist in `packaging/README.md` before release.

Setup never treats file presence as readiness. A successful local load/inference check creates a receipt bound to model path, size, modification time and runtime versions. A changed model/runtime or missing tokenizer requires another check. This is readiness bookkeeping, not a cryptographic authenticity check: obtain weights only from the official source.

Cancellation and failed verification retain the previous imported model and leave the download untouched. Copying uses temporary cache storage and atomic model publication. Models live outside the installation folder; choosing Classical does not remove them. The frozen app never launches pip; source installations retain the runtime installer.

## Thread review references

- [SAM setup screens](https://ampcode.com/artifacts/visuals/sam-setup-screens-7d5feadb-8d7d-4202-9b06-1340685a49b9)
- [Design handoff](https://ampcode.com/artifacts/sam-setup-design-9e564864-5e15-4591-ab76-9ee6cfac9ffd)
- [Earlier feasibility assessment](https://ampcode.com/artifacts/sam-support-assessment-52b4e43e-fdbb-4190-bbb4-85ce4322299b)

Artifact links follow the thread's access permissions. The HTML remains a simulated review prototype; the native implementation is the production code path. The earlier assessment includes alternative approaches; the bundled-runtime/manual-import flow above is the implemented direction, pending Windows and authorised-weight validation.
