# Lean companion

These files accompany [Portable Checkpoints Can Reduce Completion](../paper.pdf). The main model uses real-valued payments and a probability measure over nonnegative opportunity costs. Continuation rent is defined as the expectation of the positive part of the bonus minus cost.

| Manuscript claim | Lean theorem |
| --- | --- |
| Optimal posted contract and binding ex ante participation | `optimal_contract`, `binding_payoff` |
| Buyer payoff equals expected surplus; surplus rises with replacement availability | `surplus_is_social`, `surplus_mono`, `surplus_strict` |
| Completion can fall even as surplus rises | `completion_falls_iff`, `lateCompletion_deriv_neg_iff`, `rent_hasDerivAt`, `lateValue_deriv_pos`, `paper_example` |
| Contractible replacement availability changes the optimal bonuses and restores monotonic completion | `early_optimal`, `early_completion_mono` |
| Value of early information | `value_of_information`, `contractible_rent`, `contractible_rent_strict` |
| Uniform-model optimum with nonnegative checkpoint payments | `uniform_optimal`, `uniformFixed_deriv_pos`, `uniformHalf_deriv_pos` |

[PortableCheckpoints.lean](PortableCheckpoints.lean) proves the distribution-level results directly from expected rent. [CompletionCalculus.lean](CompletionCalculus.lean) checks the derivative formulas at the cutoff. In the main model, `rent_hasDerivAt` derives the rent derivative from continuity of the actual CDF. The uniform results use the paper’s closed-form uniform expressions; the proof does not independently derive those expressions from a uniform probability measure. The normalized uniform objective is checked on the range where the closed forms apply; the manuscript handles bonuses beyond that range. The completion formulas encode the disjoint incumbent and replacement outcomes under the assumed independence. The project timing and contracting assumptions are inputs, not conclusions.

To check, follow the root [Lean instructions](../../../scripts/).
