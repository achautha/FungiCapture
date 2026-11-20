# Licensing and responsible distribution

FungiCapture is AGPL-3.0-or-later; optional backend software and SAM materials
have their own terms. Our distribution policy is to leave SAM weights out of
application downloads and direct researchers to Meta's official access process.
This policy reduces redistribution complexity; it is not a claim that Meta
prohibits all redistribution.

This is practical guidance, not legal advice or a compliance certification.
Licence texts govern. Ask your institution's legal or research-software office
to review unresolved questions before distributing builds or providing a service.

## The licences apply to different materials

| Material | Terms and practical consequence |
|---|---|
| FungiCapture source and modifications | [AGPL-3.0-or-later](../LICENSE). Preserve notices and comply with the applicable source/conveyance requirements when sharing software. |
| Ultralytics SAM integration | AGPL-licensed backend; inspect the licence of the exact installed version. Installing it does not license Meta's weights. See [Ultralytics licensing](https://www.ultralytics.com/license). |
| Meta SAM materials | [SAM License](https://huggingface.co/facebook/sam3/blob/main/LICENSE), including applicable Meta-distributed model code and weights. These are not automatically relicensed under FungiCapture's AGPL. |
| PySide6/Qt and other dependencies | Their own licences, including LGPL and permissive licences; retain required notices and satisfy applicable distribution obligations. See [NOTICE.md](../NOTICE.md) as an inventory starting point, not proof of a compliant build. |
| Research photographs and data | Rights, consent, privacy, institutional and funder requirements must be checked separately. An application licence does not grant rights to input data. |

Using FungiCapture to produce tables does not by itself mean every input image,
result or manuscript must be released under AGPL. Sharing application binaries,
modified software, model materials or a network service raises different
questions. Assess the actual materials and activity rather than assuming one
licence covers everything.

## What Meta's SAM licence says

Checked on **19 November 2026** against the official SAM 3 licence page, whose
text is marked **Last Updated: November 19, 2025**. Recheck the terms and model
revision used before a release; this date is not a promise that terms never change.

- **§1.a permits use, copying, modification and distribution**, subject to the
  agreement. SAM is not simply “research-only” or “non-commercial-only.” Do not
  infer permission for a particular use without reading all the terms.
- **§1.b.i requires redistribution under the SAM agreement and a copy of that
  agreement with SAM materials or derivatives** made available to third parties.
- **§1.b.ii requires acknowledging SAM use in publications** of research performed
  on, using or otherwise in connection with SAM materials. It does not specify
  that acknowledgement must appear in a particular manuscript section.
- **§1.b.iii–v impose legal, privacy, trade-control and other use restrictions**,
  including restrictions concerning reverse engineering and specified end uses.
  Read the full terms; this list is not exhaustive.
- The agreement also contains warranty, liability, termination and amendment
  provisions. Being a researcher or clicking an app checkbox does not waive them.

The [official setup instructions](https://github.com/facebookresearch/sam3#getting-started)
ask users to request checkpoint access on
[Hugging Face](https://huggingface.co/facebook/sam3), then authenticate to download
after approval. Access approval, package installation and licence obligations are
distinct. Do not bypass the official access process or redistribute credentials.

## Before a researcher enables SAM

- [ ] Read the licence and model page for the checkpoint you will use. Confirm
  who is accepting the terms and whether they can bind the institution.
- [ ] Obtain weights through your authorised account and preserve their source,
  revision and checksum. Do not place tokens in projects, logs or support tickets.
- [ ] Follow institutional rules for shared machines and model storage. Do not
  assume one person's access authorises every collaborator's use.
- [ ] Validate segmentation for your experiment and record the backend actually
  used. Include the required acknowledgement when publishing SAM-based research.
- [ ] Share reproducibility metadata and acquisition instructions rather than
  adding weights to a project archive by default. Review the terms before any
  redistribution of weights or derivatives, including fine-tuned checkpoints.

See [researcher onboarding](RESEARCHER_ONBOARDING.md) for current installation
limitations, the first-run checklist and methods/acknowledgement templates.

## Before a maintainer distributes a Linux or Windows build

This is a release checklist, not a statement that the current build scripts
already satisfy it. No licence or copyright ownership is changed by this guide.

- [ ] **Exclude SAM weights from downloads.** Inspect the actual archive,
  including model caches and sample projects. Publish official acquisition
  instructions instead of hosting a weights mirror. This is project policy.
- [ ] **Audit the exact dependency set.** Even without weights, an archive may
  contain Meta-licensed code or other third-party materials. Review compatibility
  between SAM's additional restrictions and AGPL obligations with qualified
  counsel before combining or distributing them. A separate process/environment
  is not, on its own, a legal compatibility determination.
- [ ] **Supply matching source and build information.** Meet the applicable AGPL
  conveyance requirements for the chosen distribution method, retain copyright
  and modification notices, and identify the exact source revision. A generic
  repository-homepage link is not a substitute for checking those requirements.
  If offering modified software over a network, assess AGPL §13 as well.
- [ ] **Ship actual required licence texts and notices.** Include FungiCapture's
  LICENSE and NOTICE, and the applicable third-party texts for the shipped
  versions. If SAM materials are distributed after review, include their agreement.
  A generated dependency-name/URL list alone is not sufficient.
- [ ] **Review LGPL obligations for native libraries.** Keep replaceable shared
  libraries and provide the required notices and other materials for the specific
  build. The current one-folder PyInstaller layout supports replacement; that
  layout alone is not a full compliance guarantee, nor is one-file packaging
  categorically prohibited by LGPL in every circumstance.
- [ ] **Document what the build can actually do.** Do not advertise working SAM
  setup in a frozen executable until a tested runtime exists. State the supported
  backend, platform requirements and remaining limitations.
- [ ] **Provide versioned archives, checksums and matching documentation.**
  Keep provenance and citation guidance with the release; test without locally
  cached weights so the default experience matches a new researcher's machine.

## Primary references

- [FungiCapture licence](../LICENSE) and [third-party inventory](../NOTICE.md).
- [GNU AGPL v3](https://www.gnu.org/licenses/agpl-3.0.html), especially §§4–6
  on conveyance and §13 on remote network interaction.
- [GNU LGPL v3](https://www.gnu.org/licenses/lgpl-3.0.html), including §4 on
  combined works, and [Qt licensing](https://doc.qt.io/qt-6/licensing.html).
- [Meta SAM 3 licence](https://huggingface.co/facebook/sam3/blob/main/LICENSE)
  and [official repository](https://github.com/facebookresearch/sam3).
- [Ultralytics licensing](https://www.ultralytics.com/license).
