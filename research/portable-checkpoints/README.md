# Portable Checkpoints Can Reduce Completion

**TL;DR.** A buyer can hire a replacement to finish a project if its incumbent exits. More reliable replacement lowers the optimal completion bonus and can induce enough additional exits to reduce completion, even as expected surplus rises. If replacement availability is observable and contractible before exit, the reversal disappears.

**Contribution.** Search and procurement models already establish reservation cutoffs and their implementation by a payment difference. Here a replacement can finish after the incumbent exits. The note characterizes when more reliable replacement reduces completion by either supplier even as surplus rises, and shows how a nonnegative checkpoint payment limits the reversal in the uniform-cost case. Expiring AI compute allowances motivate the model, but the comparative static does not require quota expiration.

**Status.** Public working paper. See [PDF](paper.pdf), [TeX](paper.tex), [checks](check_model.py), and [venue and provenance notes](SUBMISSION.md).

**Reproduce.** From this directory, with Python 3, Make, latexmk and a standard pdfLaTeX distribution (geometry, AMS packages, natbib, hyperref), run `make check` and `make -B`. No external data or network access is needed. The script tests the example with exact rational arithmetic and checks grid deviations; it does not replace the proofs. The build uses a fixed source timestamp; PDF bytes may differ across TeX versions.

**Lean companion.** See [the proofs and their scope](lean/). The companion checks the posted contracts, the surplus and completion comparisons, and the uniform example. With the pinned toolchain, run `lake env python3 scripts/check_lean.py --fetch-cache` from the repository root.
