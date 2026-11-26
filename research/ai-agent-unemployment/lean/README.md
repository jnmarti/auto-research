# Formal statements and economic scope

[AgentUnemployment.lean](AgentUnemployment.lean) uses real-valued payoffs and probabilities with the names in the manuscript. The three policies and their expected private values are defined by the rows of Table 1. The baseline breaks ties toward early use. The queue is selected only on a strict gain.

| Manuscript claim | Lean declarations and scope |
| --- | --- |
| Optimal allocation in Table 1 | `baseline_value` and `optimal` prove the value of the baseline rule and weak optimality against every available policy. |
| Proposition 1 | `queue_iff` solves the two strict participation inequalities. `peak_gain` bounds the gross gain over all real risks, and `gain_at_peak` attains the bound at the baseline cutoff. The proof of uniqueness via the two strict slopes is in the text. |
| Proposition 2 | `idle_effect`, `idle_signs`, and `nonadopter_idle` give the signed expiry changes conditional on the subscriber's optimal choice. Strict private gain is the selection condition in `chosen`. |
| Sharp range from baseline records | `early_effect_upper` bounds each early adopter's change. `early_frontier_gap` gives the distance to the limiting response. `attainable_early_mean` constructs an interior risk and mixture weight for every normalized early-group response between zero (inclusive) and the supremum (exclusive). The identification of holder risks and aggregation over the fixed holder group are given in the manuscript. |
| Identical baseline records and opposite effects | `same_baseline_opposite_effects` evaluates baseline and post-offer means for the two specified populations using the optimal rule. |
| Several units | `marginal_reservation` verifies the algebra of the incremental return given the urgent-demand tail probability. The derivation from the random count and the optimal integer reserve rule are in the text. |

The parameter restrictions in the paper imply the denominator and sign assumptions used in Lean. Results which use fewer restrictions are valid over a larger algebraic domain. Expected payoffs and expiry probabilities are model definitions in Lean. The probability-tree interpretation, integral aggregation for arbitrary distributions, manual fallback and metering variants, provider costs, and empirical design are argued in the manuscript. The formalization uses the repository's pinned Lean and Mathlib versions.

From the repository root:

~~~sh
lake env python3 scripts/check_lean.py --fetch-cache
~~~
