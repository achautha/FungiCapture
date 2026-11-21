# Windows SAM upgrade and setup design

Keep FungiCapture's existing Qt tabs, Settings group, buttons and Segmentation setup dialog. Bundle the CPU runtime in a SAM-enabled installer and import model weights separately. Classical remains selected until the user explicitly chooses SAM for a project.

**Status:** Proposed design, not implemented or approved for implementation. Committing this design does not add SAM support to the Windows installer. No Windows upgrade or trained-model inference test has been performed.

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
7. **Preview:** Inspect an outline on a project crop and adjust the prompt without changing saved masks. The prototype's outline is synthetic. A dedicated preview is a proposed addition, not existing functionality.
8. **Confirm project switch:** Explicitly select SAM without starting segmentation. Explain that a later re-run replaces masks and requires regenerating dependent features and phenotypes. Switching back to Classical does not uninstall the model.

## Reuse the current components

Paths below are relative to `src/fungicapture/`.

| Existing owner | Proposed change |
| --- | --- |
| `gui/main_window.py` | One-time post-upgrade notice; retain menus, project header and workflow tabs. |
| `gui/tabs/simple_tabs.py` | Retain the Settings form and setup/model buttons. Use readable method labels, separate readiness and persistent explicit project choices. |
| `gui/tabs/setup_dialog.py` | Adapt the existing 720 × 620 dialog to add/import/check/ready/error states. The bundled-runtime build should not offer pip-based PyTorch installation. Keep technical details expandable. |
| Existing background-worker pattern | Copy and verify without blocking Qt; define cancellation cleanup and model publication behavior. |

Use platform fonts, pale gray dialog backgrounds, thin group-box borders and ordinary Qt controls. Do not introduce a dashboard, side navigation or new theme. The HTML approximates Qt rather than rendering actual Qt widgets. At narrow review widths, the header and controls wrap; the production target remains Windows desktop.

Accessibility expectations include labelled controls, normal keyboard traversal, visible focus, text accompanying status dots, accessible progress descriptions and focus restoration after dialog transitions.

## Feasibility findings and implementation limits

- The released `0.0.1` frozen executable excludes the SAM runtime and disables dependency installation. Model weights alone cannot add SAM to that executable.
- Source-mode code already has local SAM integration and manual model import. It is not an automatic model downloader or an isolated runtime worker.
- Intended in-place upgrade behavior must be validated on Windows, including preservation of projects and preferences. The design is not evidence that upgrade behavior works.
- Runtime packaging needs the dependencies identified in the spike, including `ftfy`, `regex`, `iopath` and `timm`, plus the tokenizer asset and an explicit usable tokenizer path. Windows DLL handling and prerequisites still need validation.
- The Linux feasibility checks did not establish Windows or trained-SAM compatibility. No authorised weights were available for an inference test.
- Candidate CPU SAM-only wheels were approximately 292 MB extra. Final installer size and extraction/install time remain unmeasured. The separate model is 3,450,062,241 bytes, approximately 3.45 GB.
- The existing `auto` backend behavior differs from this proposal. Installing weights must not silently convert projects. Explicit method persistence and legacy-project migration need implementation decisions.
- Check existing output-writing behavior before finalising the re-run replacement warning. Preserving prior result versions is additional scope, not promised here.
- A dedicated preview adds work beyond bundling the runtime and importing weights. It can be deferred for a strictly minimal first release; verification and explicit activation should remain.
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

## Thread review references

- [SAM setup screens](https://ampcode.com/artifacts/visuals/sam-setup-screens-7d5feadb-8d7d-4202-9b06-1340685a49b9)
- [Design handoff](https://ampcode.com/artifacts/sam-setup-design-9e564864-5e15-4591-ab76-9ee6cfac9ffd)
- [Earlier feasibility assessment](https://ampcode.com/artifacts/sam-support-assessment-52b4e43e-fdbb-4190-bbb4-85ce4322299b)

Artifact links follow the thread's access permissions; the committed HTML and this document are the repository handoff. The earlier assessment includes alternative approaches; the bundled-runtime/manual-import flow above is the latest design direction. Design approval and implementation are still pending.
