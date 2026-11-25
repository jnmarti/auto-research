import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Tactic.Ring

/-!
# Portable checkpoints: derivative calculations

The continuous results use the paper's CDF and rent derivatives as hypotheses
at the relevant cutoff. This file checks the comparative statics using the
chain and product rules; it does not derive those hypotheses from a probability
measure.
-/

namespace PortableCheckpoints.Calculus

def bonus (V k q : ℝ) : ℝ := V - q * (V - k)

def lateCompletion (F : ℝ → ℝ) (V k q : ℝ) : ℝ :=
  q + (1 - q) * F (bonus V k q)

theorem bonus_hasDerivAt (V k q : ℝ) :
    HasDerivAt (bonus V k) (-(V - k)) q := by
  simpa [bonus] using
    (HasDerivAt.const_sub V ((hasDerivAt_id q).mul_const (V - k)))

theorem lateCompletion_hasDerivAt (F : ℝ → ℝ) (V k q density : ℝ)
    (hF : HasDerivAt F density (bonus V k q)) :
    HasDerivAt (lateCompletion F V k)
      (1 - F (bonus V k q) - (1 - q) * (V - k) * density) q := by
  have hComp := hF.comp q (bonus_hasDerivAt V k q)
  have hProd := (HasDerivAt.const_sub 1 (hasDerivAt_id q)).mul hComp
  have hSum := (hasDerivAt_id q).add hProd
  convert hSum using 1
  simp only [id_eq, Function.comp_apply]
  ring

theorem lateCompletion_deriv_neg_iff (F : ℝ → ℝ) (V k q density : ℝ)
    (hF : HasDerivAt F density (bonus V k q)) :
    deriv (lateCompletion F V k) q < 0 ↔
      1 - F (bonus V k q) < (1 - q) * (V - k) * density := by
  rw [(lateCompletion_hasDerivAt F V k q density hF).deriv]
  exact sub_neg

def lateValue (R : ℝ → ℝ) (s a V k q : ℝ) : ℝ :=
  s - a + q * (V - k) + R (bonus V k q)

theorem lateValue_hasDerivAt (R : ℝ → ℝ) (s a V k q cdf : ℝ)
    (hR : HasDerivAt R cdf (bonus V k q)) :
    HasDerivAt (lateValue R s a V k) ((V - k) * (1 - cdf)) q := by
  have hComp := hR.comp q (bonus_hasDerivAt V k q)
  have hBase := (hasDerivAt_const q (s - a)).add ((hasDerivAt_id q).mul_const (V - k))
  convert hBase.add hComp using 1
  ring

theorem lateValue_deriv_pos (R : ℝ → ℝ) (s a V k q cdf : ℝ)
    (hR : HasDerivAt R cdf (bonus V k q))
    (hk : k < V) (hF : cdf < 1) :
    0 < deriv (lateValue R s a V k) q := by
  rw [(lateValue_hasDerivAt R s a V k q cdf hR).deriv]
  exact mul_pos (sub_pos.mpr hk) (sub_pos.mpr hF)

/-- In the constant-bonus branch of the uniform example, use this
formula on any open interval where the bonus is A. -/
theorem uniformFixed_deriv_pos (M A q : ℝ) (hM : 0 < M) (hA : A < M) :
    0 < deriv (fun t => t + (1 - t) * (A / M)) q := by
  have h : HasDerivAt (fun t => t + (1 - t) * (A / M)) (1 + -1 * (A / M)) q :=
    (hasDerivAt_id q).add ((HasDerivAt.const_sub 1 (hasDerivAt_id q)).mul_const (A / M))
  rw [h.deriv]
  simpa using (sub_pos.mpr ((div_lt_one hM).mpr hA))

/-- In the half-cutoff branch, the reoptimized bonus is K/2. This is
the completion derivative of that formula away from its branch boundaries. -/
theorem uniformHalf_hasDerivAt (V k M q : ℝ) :
    HasDerivAt (fun t => t + (1 - t) * (bonus V k t / (2 * M)))
      (1 - (k + 2 * (1 - q) * (V - k)) / (2 * M)) q := by
  have hF : HasDerivAt (fun x : ℝ => x * (2 * M)⁻¹) (1 * (2 * M)⁻¹) (bonus V k q) :=
    (hasDerivAt_id (bonus V k q)).mul_const _
  simpa only [div_eq_mul_inv, one_mul] using
    ((lateCompletion_hasDerivAt (fun x => x * (2 * M)⁻¹) V k q _ hF).congr_deriv
      (by unfold bonus; ring))

theorem uniformHalf_deriv_pos (V k M q : ℝ)
    (hk0 : 0 ≤ k) (hkV : k ≤ V) (hVM : V < M) (hq : 0 ≤ q) :
    0 < deriv (fun t => t + (1 - t) * (bonus V k t / (2 * M))) q := by
  rw [(uniformHalf_hasDerivAt V k M q).deriv]
  have hM : 0 < 2 * M := mul_pos (by norm_num) (lt_of_le_of_lt (hk0.trans hkV) hVM)
  apply sub_pos.mpr
  apply (div_lt_one hM).mpr
  nlinarith [mul_nonneg hq (sub_nonneg.mpr hkV)]

end PortableCheckpoints.Calculus
