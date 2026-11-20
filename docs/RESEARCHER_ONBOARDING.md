# Researcher onboarding

Start with a small, representative set of plates, verify the segmentation
backend actually used, and inspect the masks before analysing a full experiment.
FungiCapture measures image-derived phenotypes; it does not perform GWAS or
establish the biological validity of those measurements.

This guide describes the current source branch. It does not announce available
desktop releases or a completed SAM installer for standalone builds. Read the
[licensing guidance](LICENSING.md) before enabling SAM or sharing an application
build. For detailed controls, see the [user guide](USER_GUIDE.md).

## 1. Install from a trusted source

- Obtain source or a release from the repository your lab has selected. Record
  its URL and exact commit or release version; distinguish this fork from upstream.
- For the current source distribution, use the SETUP file for Windows or Linux,
  then the corresponding START file. Python 3.12 or 3.13 is required. Setup
  needs internet access; Linux setup may request administrator permission for
  graphics libraries. Ask your administrator on managed computers.
- If a standalone build is supplied, follow that build's instructions and keep
  its application folder intact. Verify a published checksum if available.
  An unsigned executable is not proof of safety; do not bypass security warnings
  without verifying its source and your institution's policy.
- The default installation does not include SAM weights. Classical segmentation
  needs no model download. Additional dependency/model installation needs internet
  access; test your chosen workflow before moving to an offline machine.

## 2. Choose a segmentation method deliberately

| Method | Requirements | What to validate |
|---|---|---|
| Classical | Core application; no SAM weights or GPU | Thresholding can miss faint margins or merge background with colonies. |
| SAM 3 | Compatible PyTorch, torchvision and Ultralytics; locally obtained weights; Meta's terms | Prompts and masks must be checked on your organism, medium and imaging conditions. A GPU may improve speed. |

Neither method is universally better. Choose using representative images,
including faint, pigmented, small and irregular colonies. Preserve the comparison
and do not pool outputs from different methods without evaluating the effect.

**Current fallback behaviour:** `auto` tries SAM and falls back to classical when
SAM is unavailable, with a warning. It does not request approval first. Inspect
the Segment tab and run messages; do not infer the actual backend from whether
libraries or weights are installed.

For scripted runs, select a backend explicitly. These examples assume an existing
project named `my-project` and an activated source installation:

```bash copy Copy Classical Run
fungicapture run my-project --steps segment --backend classical
```

```bash copy Copy SAM Run
fungicapture run my-project --steps segment --backend sam3
```

An explicit `sam3` request reports an error instead of switching to classical
when the model is unavailable. Keep separate output/project folders when comparing
methods so one run does not overwrite another.

## 3. Enable SAM only if you need it

1. Read the [SAM licence](https://huggingface.co/facebook/sam3/blob/main/LICENSE)
   and [official model page](https://huggingface.co/facebook/sam3). Confirm that
   you are authorised to accept the terms for yourself or your institution.
   Research use is not an exemption from the terms.
2. Request access through the official model page. Once approved, download the
   checkpoint through your own authorised account using Meta's instructions.
   Do not obtain weights from an unofficial mirror or share account tokens.
3. In a **source/launcher installation**, open **2 Segment → Segmentation
   setup… → Install PyTorch + Ultralytics**. This installs libraries, not the
   checkpoint, and is not acceptance of Meta's licence on your behalf. Restart
   if prompted. Allow several gigabytes of storage; requirements vary by build.
4. Point `FUNGICAPTURE_SAM3_WEIGHTS` at the full path of your downloaded file
   before starting FungiCapture. This existing environment variable avoids
   ambiguity when several checkpoints are present. The app also searches its
   per-user model cache and the working directory for `sam3*.pt` files. Discovery
   does not guarantee that a checkpoint is compatible with the installed backend.
5. Recheck the environment and run a small pilot. Confirm that the run actually
   uses SAM, inspect the overlays, and record the checkpoint identity and SHA-256.

For a source installation, set the path in the same terminal that launches the
app. Replace the example path with your file. Linux (Bash):

```bash copy Copy Linux SAM Launch
export FUNGICAPTURE_SAM3_WEIGHTS="/absolute/path/to/sam3.pt"
sha256sum "$FUNGICAPTURE_SAM3_WEIGHTS"
fungicapture gui
```

Windows (PowerShell), with the source installation's Python environment active:

```powershell copy Copy Windows SAM Launch
$env:FUNGICAPTURE_SAM3_WEIGHTS = "C:\Models\sam3.pt"
Get-FileHash -Algorithm SHA256 -LiteralPath $env:FUNGICAPTURE_SAM3_WEIGHTS
fungicapture gui
```

These settings apply to that terminal and its child processes, not a separate
desktop shortcut. Keep the printed full hash with your methods record.

**Standalone limitation:** the frozen executable cannot install libraries into
itself using `pip`. Installing them in an unrelated Python environment does not
make them available to that executable. Use a source installation for optional
SAM setup unless your release explicitly supplies and documents a tested SAM
runtime. A separately managed runtime is a proposed packaging improvement, not
a feature promised by this guide.

Keep weights outside application archives and shared project exports. Follow
your institution's access and storage policy for any shared model store.

## 4. Complete a pilot before processing the experiment

- [ ] Preserve original photographs and record sample IDs, media, acquisition
  time points, biological replicates, plate layout and imaging conditions.
- [ ] Keep lighting, exposure, geometry and scale consistent. If comparing
  colour, record the calibration method and reference-card definition used.
- [ ] Create the correct imaging mode, check crop positions and verify that
  filenames or the plate map preserve sample identities.
- [ ] Run segmentation with the intended backend and inspect masks/overlays
  across representative conditions, including difficult colonies.
- [ ] Run feature extraction, then use Validate to record pass/fail decisions
  and reasons. Check which exclusions actually reach downstream tables.
- [ ] If generating PCA phenotypes, record retained features, missing-data
  handling, standardisation, media grouping, components and outlier decisions.
  Treat small-sample or unreliable PCA warnings as scientific limitations.
- [ ] Only then process the full experiment with the documented settings.

## 5. Preserve a methods record with the results

Archive the photographs or their controlled-access location, plate map, project
settings, run messages/history, masks, feature tables, QC decisions and final
phenotype tables. Check the exported files rather than assuming they contain
every field below. Supplement missing provenance manually:

- FungiCapture repository URL and release/commit; Python and dependency versions;
- actual segmentation backend, checkpoint source/revision and full SHA-256 if
  applicable, prompts, device and precision settings;
- crop layout, image scale/units, calibration, analysis settings and parameter hash;
- failed items, exclusions and reasons, PCA settings and downstream GWAS software.

The current application has parameter hashes and run records, but this guide does
not imply that it exports a complete methods record or full model hash everywhere.
A matching filename or parameter hash alone does not establish identical inputs,
models or environments.

## 6. Report only the methods actually used

Replace every bracketed field and remove inapplicable clauses before using this
example. It is a reporting template, not an automatically generated statement:

```text copy Copy Methods Template
Colony photographs were analysed with FungiCapture [version/commit; repository URL]. Images were acquired under [conditions] and calibrated using [method, or none]. Colonies were cropped using [layout] and segmented using [classical method, or SAM 3 with backend versions, checkpoint revision, SHA-256, prompts and device/precision]. Segmentation was checked using [QC procedure]; [number] colonies were excluded for [criteria]. Features were extracted using [settings and parameter hash]. [If applicable: PCA phenotypes were generated using the documented missing-data, standardisation, media-grouping, component-selection and outlier rules.] Outputs were used in [downstream analysis], with [replicate/batch handling and limitations].
```

For SAM-based work, acknowledge its use in the publication as required by Meta's
licence (§1.b.ii), and use the citation metadata supplied by the official model
repository. Suggested acknowledgement, to adapt to the work actually performed:

```text copy Copy SAM Acknowledgement
This research used Meta's Segment Anything Model 3 (SAM 3) for fungal colony segmentation through FungiCapture's SAM backend.
```

Cite the exact FungiCapture release/commit and its authors using available release
metadata; do not invent a paper or DOI. For the PCA-based phenotype approach,
consult Zhang et al. (2018), *PCA-Based Multiple-Trait GWAS Analysis: A Powerful
Model for Exploring Pleiotropy*, <https://doi.org/10.3390/ani8120239>.
Citation does not replace licence compliance, scientific validation or permissions
to share images, software or model files.
