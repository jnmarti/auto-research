import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

/-!
# Portable checkpoints can reduce completion

Main economic model, with real prices and a probability distribution of costs.
The cost distribution is a Borel probability measure on the reals concentrated
on nonnegative values. We prove optimality among all feasible posted contracts,
surplus accounting and monotonicity, the exact finite-change reversal condition,
and the information result for contractible replacement availability. No
smoothness is required for these results.
-/

noncomputable section
open MeasureTheory Set

namespace PortableCheckpoints

variable (μ : Measure ℝ) [IsProbabilityMeasure μ]

def cdf (b : ℝ) : ℝ := μ.real (Iic b)

def rent (b : ℝ) : ℝ := ∫ c, max 0 (b - c) ∂μ

theorem cdf_le_one (b : ℝ) : cdf μ b ≤ 1 := by
  simpa [cdf] using (measureReal_mono (μ := μ) (subset_univ (Iic b)))

omit [IsProbabilityMeasure μ] in
theorem cdf_nonneg (b : ℝ) : 0 ≤ cdf μ b := measureReal_nonneg

theorem cdf_mono : Monotone (cdf μ) := by
  intro b d h
  exact measureReal_mono (Iic_subset_Iic.mpr h)

private theorem integrable_positivePart (hC : ∀ᵐ c ∂μ, 0 ≤ c) (b : ℝ) :
    Integrable (fun c => max 0 (b - c)) μ := by
  apply (integrable_const (max (0 : ℝ) b)).mono'
  · exact (continuous_const.max (continuous_const.sub continuous_id)).aestronglyMeasurable
  · filter_upwards [hC] with c hc
    rw [Real.norm_eq_abs, abs_of_nonneg (le_max_left _ _)]
    exact max_le_max le_rfl (sub_le_self _ hc)

theorem rent_mono (hC : ∀ᵐ c ∂μ, 0 ≤ c) : Monotone (rent μ) := by
  intro b d h
  exact integral_mono (integrable_positivePart μ hC b) (integrable_positivePart μ hC d)
    (fun c => max_le_max le_rfl (sub_le_sub_right h c))

private theorem positivePart_support (b d c : ℝ) :
    max 0 (b - c) - max 0 (d - c) ≤ (Iic b).indicator (fun _ => b - d) c := by
  by_cases h : c ≤ b
  · have hh : c ∈ Iic b := h
    rw [indicator_of_mem hh, max_eq_right (sub_nonneg.mpr h)]
    linarith [le_max_right (0 : ℝ) (d - c)]
  · have hh : c ∉ Iic b := h
    rw [indicator_of_not_mem hh, max_eq_left (sub_nonpos.mpr (le_of_not_ge h))]
    linarith [le_max_left (0 : ℝ) (d - c)]

/-- The bound underlying optimal posted bonuses, derived from the expected
positive-part rent. It holds also for atoms, with continuation at indifference. -/
theorem rent_support (hC : ∀ᵐ c ∂μ, 0 ≤ c) (b d : ℝ) :
    rent μ b - rent μ d ≤ (b - d) * cdf μ b := by
  have hb := integrable_positivePart μ hC b
  have hd := integrable_positivePart μ hC d
  have hi : Integrable ((Iic b).indicator (fun _ : ℝ => b - d)) μ :=
    (integrable_const _).indicator measurableSet_Iic
  have h := integral_mono (hb.sub hd) hi (positivePart_support b d)
  simp only [Pi.sub_apply] at h
  rw [integral_sub hb hd, integral_indicator_const _ measurableSet_Iic] at h
  simpa [rent, cdf, smul_eq_mul, mul_comm] using h

def fallback (V k q : ℝ) : ℝ := q * (V - k)
def cutoff (V k q : ℝ) : ℝ := V - fallback V k q
def buyer (s V k q b r : ℝ) : ℝ :=
  s + (V - b) * cdf μ b + fallback V k q * (1 - cdf μ b) - r

theorem cutoff_bounds (V k q : ℝ) (hk0 : 0 ≤ k) (hkV : k ≤ V)
    (hq0 : 0 ≤ q) (hq1 : q ≤ 1) :
    0 ≤ cutoff V k q ∧ cutoff V k q ≤ V := by
  have h := mul_nonneg hq0 (sub_nonneg.mpr hkV)
  have h' := mul_nonneg (sub_nonneg.mpr hq1) (sub_nonneg.mpr hkV)
  dsimp [cutoff, fallback]
  constructor <;> nlinarith

/-- Proposition 1: the posted contract binds participation and is optimal
against every feasible bonus and checkpoint payment, without bounding the
alternatives above by V. -/
theorem optimal_contract (hC : ∀ᵐ c ∂μ, 0 ≤ c)
    (s V k q a : ℝ) (hk0 : 0 ≤ k) (hkV : k ≤ V) (hq0 : 0 ≤ q) (hq1 : q ≤ 1)
    (ha : rent μ V ≤ a) :
    let K := cutoff V k q
    let r₀ := a - rent μ K
    0 ≤ K ∧ 0 ≤ r₀ ∧ r₀ + rent μ K = a ∧
      ∀ b r : ℝ, 0 ≤ b → 0 ≤ r → a ≤ r + rent μ b →
        buyer μ s V k q b r ≤ buyer μ s V k q K r₀ := by
  dsimp only
  have hK := cutoff_bounds V k q hk0 hkV hq0 hq1
  refine ⟨hK.1, sub_nonneg.mpr ((rent_mono μ hC hK.2).trans ha), by ring, ?_⟩
  intro b r _ _ hIR
  have hs := rent_support μ hC b (cutoff V k q)
  dsimp [buyer, cutoff, fallback] at *
  linarith [show
    (V - b) * cdf μ b + q * (V - k) * (1 - cdf μ b) -
        ((V - (V - q * (V - k))) * cdf μ (V - q * (V - k)) +
         q * (V - k) * (1 - cdf μ (V - q * (V - k)))) =
      -((b - (V - q * (V - k))) * cdf μ b) by ring]

def surplus (s a V k q : ℝ) : ℝ :=
  s - a + fallback V k q + rent μ (cutoff V k q)

omit [IsProbabilityMeasure μ] in
/-- Buyer payoff at the binding cutoff as in Proposition 1. -/
theorem binding_payoff (s V k q a : ℝ) :
    buyer μ s V k q (cutoff V k q) (a - rent μ (cutoff V k q)) =
      surplus μ s a V k q := by
  unfold buyer surplus cutoff
  ring

/-- Social continuation payoff: net value after real opportunity costs. -/
def socialContinuation (V k q b c : ℝ) : ℝ :=
  if c ≤ b then V - c else fallback V k q

/-- The buyer captures the expected social surplus under binding participation
and a replacement payment equal to the replacement's opportunity cost. -/
theorem surplus_is_social (hC : ∀ᵐ c ∂μ, 0 ≤ c) (s V k q a : ℝ) :
    s - a + (∫ c, socialContinuation V k q (cutoff V k q) c ∂μ) =
      surplus μ s a V k q := by
  have hp : (fun c => socialContinuation V k q (cutoff V k q) c) =
      fun c => fallback V k q + max 0 (cutoff V k q - c) := by
    funext c
    by_cases h : c ≤ cutoff V k q
    · rw [socialContinuation, if_pos h, max_eq_right (sub_nonneg.mpr h)]
      unfold cutoff
      ring
    · rw [socialContinuation, if_neg h, max_eq_left (sub_nonpos.mpr (le_of_not_ge h)), add_zero]
  rw [hp, integral_add (integrable_const _) (integrable_positivePart μ hC _), integral_const]
  simp [surplus, rent, add_assoc]

/-- Expected surplus is nondecreasing in replacement availability. -/
theorem surplus_mono (hC : ∀ᵐ c ∂μ, 0 ≤ c)
    (s a V k q₁ q₂ : ℝ) (hkV : k ≤ V) (hq : q₁ ≤ q₂) :
    surplus μ s a V k q₁ ≤ surplus μ s a V k q₂ := by
  have hN : 0 ≤ (q₂ - q₁) * (V - k) := mul_nonneg (sub_nonneg.mpr hq) (sub_nonneg.mpr hkV)
  have hs := rent_support μ hC (cutoff V k q₁) (cutoff V k q₂)
  have hc := mul_le_mul_of_nonneg_left (cdf_le_one μ (cutoff V k q₁)) hN
  have hK : cutoff V k q₁ - cutoff V k q₂ = (q₂ - q₁) * (V - k) := by
    unfold cutoff fallback
    ring
  rw [hK] at hs
  simp only [mul_one] at hc
  unfold surplus fallback
  linarith [show (q₂ - q₁) * (V - k) = q₂ * (V - k) - q₁ * (V - k) by ring]

/-- Strict increase whenever there is positive initial exit probability. -/
theorem surplus_strict (hC : ∀ᵐ c ∂μ, 0 ≤ c)
    (s a V k q₁ q₂ : ℝ) (hkV : k < V) (hq : q₁ < q₂)
    (hExit : cdf μ (cutoff V k q₁) < 1) :
    surplus μ s a V k q₁ < surplus μ s a V k q₂ := by
  have hN : 0 < (q₂ - q₁) * (V - k) := mul_pos (sub_pos.mpr hq) (sub_pos.mpr hkV)
  have hs := rent_support μ hC (cutoff V k q₁) (cutoff V k q₂)
  have hc := mul_lt_mul_of_pos_left hExit hN
  have hK : cutoff V k q₁ - cutoff V k q₂ = (q₂ - q₁) * (V - k) := by
    unfold cutoff fallback
    ring
  rw [hK] at hs
  simp only [mul_one] at hc
  unfold surplus fallback
  linarith [show (q₂ - q₁) * (V - k) = q₂ * (V - k) - q₁ * (V - k) by ring]

/-- The paper's profitability condition ensures that the outside option of
not commissioning the checkpoint is dominated for all feasible q. -/
theorem surplus_positive (hC : ∀ᵐ c ∂μ, 0 ≤ c)
    (s a V k q : ℝ) (hkV : k ≤ V) (hq0 : 0 ≤ q)
    (hStart : 0 < s - a + rent μ V) :
    0 < surplus μ s a V k q := by
  have h := surplus_mono μ hC s a V k 0 q hkV hq0
  simpa [surplus, cutoff, fallback] using
    (show 0 < surplus μ s a V k q from
      (show 0 < surplus μ s a V k 0 by simpa [surplus, cutoff, fallback] using hStart).trans_le h)

def lateCompletion (V k q : ℝ) : ℝ := q + (1 - q) * cdf μ (cutoff V k q)

omit [IsProbabilityMeasure μ] in
/-- Finite change version of the direct-versus-indirect comparison. -/
theorem completion_falls_iff (V k q₁ q₂ : ℝ) :
    lateCompletion μ V k q₂ < lateCompletion μ V k q₁ ↔
      (q₂ - q₁) * (1 - cdf μ (cutoff V k q₁)) <
        (1 - q₂) * (cdf μ (cutoff V k q₁) - cdf μ (cutoff V k q₂)) := by
  unfold lateCompletion
  constructor <;> intro h <;> nlinarith

def earlyCompletion (V q : ℝ) : ℝ := q + (1 - q) * cdf μ V

theorem early_completion_mono (V : ℝ) : Monotone (earlyCompletion μ V) := by
  intro q₁ q₂ hq
  have h := mul_nonneg (sub_nonneg.mpr hq) (sub_nonneg.mpr (cdf_le_one μ V))
  unfold earlyCompletion
  nlinarith

/-- State-contingent contract. The incumbent's rent enters ex ante IR with the
same state weights as the buyer's profits. -/
def earlyBuyer (s V k q b₀ b₁ r : ℝ) : ℝ :=
  s + (1 - q) * ((V - b₀) * cdf μ b₀) +
    q * ((V - k) + (k - b₁) * cdf μ b₁) - r

theorem early_optimal (hC : ∀ᵐ c ∂μ, 0 ≤ c)
    (s V k q a : ℝ) (hk0 : 0 ≤ k) (hkV : k ≤ V) (hq0 : 0 ≤ q) (hq1 : q ≤ 1)
    (ha : rent μ V ≤ a) :
    let r₀ := a - ((1 - q) * rent μ V + q * rent μ k)
    0 ≤ V ∧ 0 ≤ k ∧ 0 ≤ r₀ ∧ r₀ + ((1 - q) * rent μ V + q * rent μ k) = a ∧
      ∀ b₀ b₁ r : ℝ, 0 ≤ b₀ → 0 ≤ b₁ → 0 ≤ r →
        a ≤ r + ((1 - q) * rent μ b₀ + q * rent μ b₁) →
        earlyBuyer μ s V k q b₀ b₁ r ≤ earlyBuyer μ s V k q V k r₀ := by
  dsimp only
  have hn : 0 ≤ 1 - q := sub_nonneg.mpr hq1
  have hr := mul_le_mul_of_nonneg_left (rent_mono μ hC hkV) hq0
  refine ⟨hk0.trans hkV, hk0, by nlinarith, by ring, ?_⟩
  intro b₀ b₁ r _ _ _ hIR
  have h₀ := mul_le_mul_of_nonneg_left (rent_support μ hC b₀ V) hn
  have h₁ := mul_le_mul_of_nonneg_left (rent_support μ hC b₁ k) hq0
  unfold earlyBuyer
  nlinarith

private def rentGap (V k q c : ℝ) : ℝ :=
  (1 - q) * max 0 (V - c) + q * max 0 (k - c) - max 0 (cutoff V k q - c)

private theorem rentGap_nonneg (V k q c : ℝ) (hq0 : 0 ≤ q) (hq1 : q ≤ 1) :
    0 ≤ rentGap V k q c := by
  have hn : 0 ≤ 1 - q := sub_nonneg.mpr hq1
  unfold rentGap
  apply sub_nonneg.mpr
  apply max_le
  · exact add_nonneg (mul_nonneg hn (le_max_left _ _)) (mul_nonneg hq0 (le_max_left _ _))
  · have h₀ := mul_le_mul_of_nonneg_left (le_max_right (0 : ℝ) (V - c)) hn
    have h₁ := mul_le_mul_of_nonneg_left (le_max_right (0 : ℝ) (k - c)) hq0
    unfold cutoff fallback
    nlinarith

private theorem integrable_rentGap (hC : ∀ᵐ c ∂μ, 0 ≤ c) (V k q : ℝ) :
    Integrable (rentGap V k q) μ :=
  (((integrable_positivePart μ hC V).const_mul (1 - q)).add
    ((integrable_positivePart μ hC k).const_mul q)).sub
      (integrable_positivePart μ hC (cutoff V k q))

private theorem integral_rentGap (hC : ∀ᵐ c ∂μ, 0 ≤ c) (V k q : ℝ) :
    (∫ c, rentGap V k q c ∂μ) =
      (1 - q) * rent μ V + q * rent μ k - rent μ (cutoff V k q) := by
  have hV := (integrable_positivePart μ hC V).const_mul (1 - q)
  have hk := (integrable_positivePart μ hC k).const_mul q
  unfold rentGap rent
  calc
    _ = (∫ c, ((fun x => (1 - q) * max 0 (V - x)) +
          (fun x => q * max 0 (k - x))) c ∂μ) -
          (∫ c, max 0 (cutoff V k q - c) ∂μ) := by
      simpa only [Pi.add_apply] using
        integral_sub (hV.add hk) (integrable_positivePart μ hC (cutoff V k q))
    _ = _ := by
      simp only [Pi.add_apply]
      rw [integral_add hV hk, integral_const_mul, integral_const_mul]

/-- State-contingent availability never reduces the expected continuation
rent that the buyer can extract with the checkpoint payment. -/
theorem contractible_rent (hC : ∀ᵐ c ∂μ, 0 ≤ c)
    (V k q : ℝ) (hq0 : 0 ≤ q) (hq1 : q ≤ 1) :
    rent μ (cutoff V k q) ≤ (1 - q) * rent μ V + q * rent μ k := by
  have h : 0 ≤ ∫ c, rentGap V k q c ∂μ :=
    integral_nonneg (fun c => rentGap_nonneg V k q c hq0 hq1)
  rw [integral_rentGap μ hC] at h
  linarith

/-- For 0 < q < 1, any positive probability of a cost strictly between k and
V makes the information value strictly positive. This mass condition follows
from the paper's positive density assumption. -/
theorem contractible_rent_strict (hC : ∀ᵐ c ∂μ, 0 ≤ c)
    (V k q : ℝ) (hq0 : 0 < q) (hq1 : q < 1) (hmass : 0 < μ (Ioo k V)) :
    rent μ (cutoff V k q) < (1 - q) * rent μ V + q * rent μ k := by
  have hSub : Ioo k V ⊆ Function.support (rentGap V k q) := by
    intro c hc
    apply Function.mem_support.mpr
    apply ne_of_gt
    have hcK : k < c := hc.1
    have hcV : c < V := hc.2
    unfold rentGap
    rw [max_eq_right (sub_nonneg.mpr hcV.le), max_eq_left (sub_nonpos.mpr hcK.le)]
    by_cases h : c ≤ cutoff V k q
    · rw [max_eq_right (sub_nonneg.mpr h)]
      have hh := mul_pos hq0 (sub_pos.mpr hcK)
      unfold cutoff fallback
      nlinarith
    · rw [max_eq_left (sub_nonpos.mpr (le_of_not_ge h)), mul_zero, add_zero, sub_zero]
      exact mul_pos (sub_pos.mpr hq1) (sub_pos.mpr hcV)
  have h := (integral_pos_iff_support_of_nonneg (fun c =>
    rentGap_nonneg V k q c hq0.le hq1.le) (integrable_rentGap μ hC V k q)).mpr
      (hmass.trans_le (measure_mono hSub))
  rw [integral_rentGap μ hC] at h
  linarith

omit [IsProbabilityMeasure μ] in
/-- The value of contractibility in the paper is exactly the rent Jensen gap. -/
theorem value_of_information (s V k q a : ℝ) :
    earlyBuyer μ s V k q V k (a - ((1 - q) * rent μ V + q * rent μ k)) -
      surplus μ s a V k q =
      (1 - q) * rent μ V + q * rent μ k - rent μ (cutoff V k q) := by
  unfold earlyBuyer surplus fallback
  ring

/-- Twice M times the uniform-law buyer payoff, net of constants, with
`A² = 2*M*a`. The two quadratics coincide at the limited-liability kink. -/
def uniformScore (K A b : ℝ) : ℝ :=
  min (2 * K * b - b ^ 2 - A ^ 2) (2 * K * b - 2 * b ^ 2)

def uniformCutoff (K A : ℝ) : ℝ := max (K / 2) (min A K)

private theorem uniformScore_lower {K A b : ℝ} (hb : 0 ≤ b) (h : b ≤ A) :
    uniformScore K A b = 2 * K * b - b ^ 2 - A ^ 2 := by
  unfold uniformScore
  refine min_eq_left ?_
  nlinarith [mul_nonneg (sub_nonneg.mpr h) (show 0 ≤ A + b by linarith)]

private theorem uniformScore_upper {K A b : ℝ} (hA : 0 ≤ A) (h : A ≤ b) :
    uniformScore K A b = 2 * K * b - 2 * b ^ 2 := by
  unfold uniformScore
  refine min_eq_right ?_
  nlinarith [mul_nonneg (sub_nonneg.mpr h) (show 0 ≤ b + A by linarith)]

/-- Closed-form cutoff for arbitrary nonnegative initial cost under the
Uniform model, conditional on initiation. The score formula is valid at
cutoffs in the support. The paper separately excludes b > V. -/
theorem uniform_optimal (K A b : ℝ) (hK : 0 ≤ K) (hA : 0 ≤ A) (hb : 0 ≤ b) :
    uniformScore K A b ≤ uniformScore K A (uniformCutoff K A) := by
  by_cases h₁ : K ≤ A
  · have hHalf : K / 2 ≤ K := by linarith
    rw [uniformCutoff, min_eq_right h₁, max_eq_right hHalf, uniformScore_lower hK h₁]
    exact (min_le_left _ _).trans (by nlinarith [sq_nonneg (b - K)])
  · have hAK : A ≤ K := le_of_lt (lt_of_not_ge h₁)
    by_cases h₂ : A ≤ K / 2
    · rw [uniformCutoff, min_eq_left hAK, max_eq_left h₂, uniformScore_upper hA h₂]
      exact (min_le_right _ _).trans (by nlinarith [sq_nonneg (b - K / 2)])
    · have hh : K / 2 ≤ A := le_of_lt (lt_of_not_ge h₂)
      rw [uniformCutoff, min_eq_left hAK, max_eq_right hh]
      by_cases h : b ≤ A
      · rw [uniformScore_lower hb h, uniformScore_lower hA le_rfl]
        nlinarith [mul_nonneg (sub_nonneg.mpr h) (show 0 ≤ 2 * K - (A + b) by linarith)]
      · have h' : A ≤ b := le_of_lt (lt_of_not_ge h)
        rw [uniformScore_upper hA h', uniformScore_upper hA le_rfl]
        nlinarith [mul_nonneg (sub_nonneg.mpr h') (show 0 ≤ A + b - K by linarith)]

/-- Exact arithmetic for the example under the standard Uniform[0,1]
formulas F(b)=b and R(b)=b²/2 at cutoffs in [0,1]. -/
theorem paper_example :
    let V : ℝ := 9 / 10
    let k : ℝ := 1 / 10
    let a : ℝ := 45 / 100
    let s : ℝ := 2 / 10
    let q : ℝ := 1 / 10
    let b₀ := cutoff V k 0
    let b₁ := cutoff V k q
    let p₀ := b₀
    let p₁ := q + (1 - q) * b₁
    let w₀ := s - a + b₀ ^ 2 / 2
    let w₁ := s - a + q * (V - k) + b₁ ^ 2 / 2
    b₀ = 90 / 100 ∧ b₁ = 82 / 100 ∧
      p₀ = 90 / 100 ∧ p₁ = 838 / 1000 ∧
      w₀ = 155 / 1000 ∧ w₁ = 1662 / 10000 ∧
      p₁ < p₀ ∧ w₀ < w₁ := by
  norm_num [cutoff, fallback]

end PortableCheckpoints
