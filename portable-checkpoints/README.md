# Portable Checkpoints Can Reduce Completion

**TL;DR.** Letting a new contributor finish someone else's AI-assisted work makes backup more likely to be available. That can prompt the sponsor to reduce the original contributor's bonus. When backup availability is uncertain, more originals can quit than backups can replace, so fewer projects finish even as net surplus rises. In the model, confirming backup capacity first eliminates the reversal.

**Contribution.** Dynamic procurement already studies exit rights and research contracts already study milestones. This note isolates a different comparative static: a portable, verifiable work product can change a sponsor's optimal bonus enough to reverse the mechanical gain in completion. Two backup-information regimes give opposite predictions. The model is motivated by expiring AI subscriptions but applies beyond AI. It does not propose buying or transferring accounts or quotas.

**Status.** Short internal theory draft. See [PDF](paper.pdf), [TeX](paper.tex), [checks](check_model.py), and [venue and provenance notes](SUBMISSION.md).

**Reproduce.** From this directory, with Python 3, Make, latexmk and a standard pdfLaTeX distribution (geometry, AMS packages, natbib, hyperref), run `make check` and `make -B`. No external data or network access is needed. The script tests the example with exact rational arithmetic and checks grid deviations; it does not replace the proofs. The build uses a fixed source timestamp; PDF bytes may differ across TeX versions.
