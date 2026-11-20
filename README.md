# FungiCapture

High-throughput, image-based phenotyping of fungal colonies — from an agar
plate photograph to GWAS-ready phenotype scores, in one desktop application.

**New researchers:** start with [researcher onboarding](docs/RESEARCHER_ONBOARDING.md)
for installation choices, a pilot-run checklist and publication templates.
Read [licensing guidance](docs/LICENSING.md) before enabling SAM or sharing builds.

---

## What it does

Fungal colonies carry a lot of measurable biology in their shape, texture and
colour. Reading that by eye is slow and subjective. FungiCapture measures it.

```
plate photograph
      │
 1 Plates      cut the plate into one image per colony
      │        an interactive grid for big plates, or hand-placed boxes for dishes
      ▼
 2 Segment     find the colony outline with SAM 3, using text prompts for both
      │        the dense core and the faint filamentous margin
      ▼
 3 Features    ~504 numbers per colony: shape, brightness, GLCM + LBP texture,
      │        and colour including melanization — interior and boundary ring
      ▼
 4 Validate    check every colony, mark pass/fail, export a PDF report
      │
      ▼
 5 Phenotypes  clean → standardise → PCA → GWAS-ready table  (optional)
```

### Four imaging modes

The application asks one question at the start: **what does one photograph
contain?**

| Mode | One photo holds | Layout you place |
|---|---|---|
| **Single dish** | one round plate, one or more colonies | one box by default; add a box per colony |
| **Dish batch** | a folder of round plates | boxes, reused for every plate |
| **Gridded plate** | one large plate, many colonies | a grid |
| **Plate batch** | many large plates, same layout | a grid, set once |

---

## Why colour is the point


FungiCapture measures colour directly in RGB, HSV and CIE-Lab, for the colony
interior and its boundary ring, and derives named melanization indices from Lab
lightness and browning. It also measures **radial zonation** — whether colour
changes from the centre outwards — which catches concentric ring structure no
summary statistic can see.

**Colour numbers are only comparable if the lighting was.** Three calibration
methods are built in and stack: EXIF drift warnings, agar background
normalisation, and correction against a colour reference card you supply. On
test scenes, card correction cuts colony colour error from ΔE 12.8 to ΔE 1.0.

FungiCapture ships **no card values of its own** — upload a definition of the
card you own and any card works.

---

## Install

### From a release

| System | File | First launch |
|---|---|---|
| Windows | `FungiCapture-windows.zip` | Unzip, run `FungiCapture.exe` |
| macOS | `FungiCapture-macos.dmg` | Drag to Applications, **right-click → Open** once |
| Linux | `FungiCapture-linux-x86_64.tar.gz` | Unpack, run `FungiCapture` |

### From source with locked dependencies

Contributors and maintainers should use uv 0.12.9 and the pinned Python:

```bash
uv sync --locked --extra gui
uv run --no-sync fungicapture-gui
```

This installs the non-SAM application and development tools, without torch,
Ultralytics or model weights. See [reproducible setup and builds](docs/DEVELOPMENT.md)
for runtime-only/CLI profiles, tests, platform limits and dependency updates.

### The SAM 3 weights are not bundled

Leaving weights out is our distribution policy, not a blanket prohibition in
Meta's licence. Obtain weights through [Meta's official access process](https://huggingface.co/facebook/sam3)
and follow the [SAM setup and licensing guidance](docs/RESEARCHER_ONBOARDING.md#3-enable-sam-only-if-you-need-it).
The setup button installs backend libraries, not weights; optional SAM setup in
a frozen standalone executable is not currently supported by that installer.
**It works without weights** using a classical segmenter. Validate its results
on your images and record the backend actually used.

---


## Command line

```bash
fungicapture new PROJECT --mode plate_batch --images DIR --rows 8 --cols 12
fungicapture run PROJECT [--steps crop,segment,features,phenotypes]
fungicapture report PROJECT --mode full|failures|contact_sheet
fungicapture info PROJECT          # settings, params hash, run history
fungicapture gui [PROJECT]
```

---

##GWAS phenotypes using PCA is based on 
Zhang, W., Gao, X., Shi, X., Zhu, B., Wang, Z., Gao, H., Xu, L., Zhang, L., Li, J., & Chen, Y. (2018). PCA-Based Multiple-Trait GWAS Analysis: A Powerful Model for Exploring Pleiotropy. Animals, 8(12), 239. https://doi.org/10.3390/ani8120239
