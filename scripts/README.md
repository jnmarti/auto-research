# Lean proof checks

Install [Elan](https://github.com/leanprover/elan) and run this command at the repository root:

```sh
lake env python3 scripts/check_lean.py --fetch-cache
```

Omit `--fetch-cache` once the required Mathlib dependencies are built or cached.
The script verifies the Lean version against `lean-toolchain`, compiles every
`.lean` source under `research/`, and audits the compiled declarations. Lake
locks Mathlib and transitive dependencies in `lake-manifest.json`. The cache
step downloads only the imports needed by the current proofs. Each research
source is a standalone module with at least one named theorem, and may import
the bundled libraries and the pinned Mathlib packages but not other research
files. Use ASCII module names such as `PortableCheckpoints.lean`.

Warnings are fatal. The audit rejects nonstandard axioms in every theorem's transitive
dependencies, allowing only `propext`, `Classical.choice`, and `Quot.sound`; this includes
`sorryAx` and trusted native evaluation. The required companion cannot silently
disappear. The check only establishes the stated Lean theorems, not the
faithfulness of their statements to the economic argument.

The GitHub workflow runs for pushes, PRs, and manual dispatch on a GitHub-hosted
runner with a read-only token and no persisted checkout credentials. Mark
`Check Lean proofs` as required in repository rules if you want it to block
merges; the workflow alone does not set branch protection.
