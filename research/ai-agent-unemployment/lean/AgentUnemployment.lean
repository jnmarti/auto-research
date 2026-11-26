import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-! A marginal unit of expiring quota. The only uncertainty needed for the
expected payoffs is the probability of urgent demand and the conditional
probability of a feasible late start when urgent demand is absent. -/

namespace AgentUnemployment

inductive Policy where
  | now | hold | queue
  deriving DecidableEq

def value (p h b q k : ℝ) : Policy → ℝ
  | .now => b
  | .hold => p * h
  | .queue => p * h + (1 - p) * q * b - k

def idle (p q : ℝ) : Policy → ℝ
  | .now => 0
  | .hold => 1 - p
  | .queue => (1 - p) * (1 - q)

noncomputable def baseline (p h b : ℝ) : Policy :=
  if p * h ≤ b then .now else .hold

noncomputable def chosen (p h b q k : ℝ) : Policy :=
  if max b (p * h) < value p h b q k .queue then .queue else baseline p h b

theorem baseline_value (p h b q k : ℝ) :
    value p h b q k (baseline p h b) = max b (p * h) := by
  unfold baseline
  split
  next hb => exact (max_eq_left hb).symm
  next hb => exact (max_eq_right (le_of_not_ge hb)).symm

theorem optimal (p h b q k : ℝ) (a : Policy) :
    value p h b q k a ≤ value p h b q k (chosen p h b q k) := by
  unfold chosen
  split
  next hs =>
    cases a with
    | now => exact le_trans (le_max_left ..) hs.le
    | hold => exact le_trans (le_max_right ..) hs.le
    | queue => exact le_rfl
  next hs =>
    rw [baseline_value]
    cases a with
    | now => exact le_max_left ..
    | hold => exact le_max_right ..
    | queue => exact le_of_not_gt hs

theorem queue_iff (p h b q k : ℝ) (hgap : 0 < h - q*b) (hqb : 0 < q*b) :
    max b (p*h) < value p h b q k .queue ↔
      (b*(1-q)+k)/(h-q*b) < p ∧ p < 1-k/(q*b) := by
  rw [max_lt_iff, div_lt_iff₀ hgap]
  have hup : p < 1-k/(q*b) ↔ k < (1-p)*(q*b) := by
    have := div_lt_iff₀ (b := k) (c := q*b) (a := 1-p) hqb
    constructor
    · intro hp
      exact this.mp (by linarith)
    · intro hk
      have := this.mpr hk
      linarith
  rw [hup]
  dsimp [value]
  constructor <;> rintro ⟨ha, hc⟩ <;> constructor <;> linarith only [ha, hc]

theorem peak_gain (p h b q : ℝ) (hh : 0 < h) (hgap : 0 ≤ h-q*b)
    (hqb : 0 ≤ q*b) :
    value p h b q 0 .queue - max b (p*h) ≤ (1-b/h)*q*b := by
  have he : b/h*h = b := div_mul_cancel₀ b hh.ne'
  by_cases hp : p ≤ b/h
  · have hm := mul_le_mul_of_nonneg_right hp hgap
    have hb : p*h ≤ b := (le_div_iff₀ hh).mp hp
    rw [max_eq_left hb]
    dsimp [value]
    linarith only [hm, he]
  · have hm := mul_le_mul_of_nonneg_right (le_of_not_ge hp) hqb
    have hb : b ≤ p*h := (div_le_iff₀ hh).mp (le_of_not_ge hp)
    rw [max_eq_right hb]
    dsimp [value]
    linarith only [hm]

theorem gain_at_peak (h b q : ℝ) (hh : 0 < h) :
    value (b/h) h b q 0 .queue - max b (b/h*h) = (1-b/h)*q*b := by
  simp [value, div_mul_cancel₀ b hh.ne']

theorem idle_effect (p h b q k : ℝ) (hs : max b (p*h) < value p h b q k .queue) :
    idle p q (chosen p h b q k) - idle p q (baseline p h b) =
      if p*h ≤ b then (1-p)*(1-q) else -(1-p)*q := by
  simp only [chosen, if_pos hs, baseline]
  split <;> simp [idle]
  ring

theorem idle_signs (p q : ℝ) (hp : p < 1) (hq : 0 < q) (hlt : q < 1) :
    0 < (1-p)*(1-q) ∧ -(1-p)*q < 0 :=
  ⟨mul_pos (sub_pos.mpr hp) (sub_pos.mpr hlt),
   mul_neg_of_neg_of_pos (neg_neg_of_pos (sub_pos.mpr hp)) hq⟩

theorem nonadopter_idle (p h b q k : ℝ) (hs : value p h b q k .queue ≤ max b (p*h)) :
    idle p q (chosen p h b q k) = idle p q (baseline p h b) := by
  simp [chosen, not_lt.mpr hs]

-- For early users, any strict adopter has risk above the lower cutoff.
theorem early_effect_upper (ell p q : ℝ) (he : ell < p) (hq : q < 1) :
    (1-p)*(1-q) < (1-ell)*(1-q) :=
  mul_lt_mul_of_pos_right (by linarith) (sub_pos.mpr hq)

theorem early_frontier_gap (ell p q : ℝ) :
    (1-ell)*(1-q) - (1-p)*(1-q) = (p-ell)*(1-q) := by ring

-- Every normalized early-user response below the supremum is attained
-- by mixing a nonadopter with one risk strictly inside the adoption region.
theorem attainable_early_mean (ell p₀ q target : ℝ)
    (hcut : ell < p₀) (hq : q < 1) (ht : 0 ≤ target)
    (hb : target < (1-ell)*(1-q)) :
    ∃ p w : ℝ, ell < p ∧ p ≤ p₀ ∧ 0 ≤ w ∧ w ≤ 1 ∧
      w*((1-p)*(1-q)) = target := by
  have hq' : 0 < 1-q := sub_pos.mpr hq
  have hd := (div_lt_iff₀ hq').mpr hb
  let top := min p₀ (1 - target/(1-q))
  have htop : ell < top := lt_min hcut (by linarith)
  obtain ⟨p, hp, hp'⟩ := exists_between htop
  have ha : p < 1 - target/(1-q) := lt_of_lt_of_le hp' (min_le_right ..)
  have hpay : target < (1-p)*(1-q) := (div_lt_iff₀ hq').mp (by linarith)
  have hpos := lt_of_le_of_lt ht hpay
  refine ⟨p, target/((1-p)*(1-q)), hp, le_trans hp'.le (min_le_left ..),
    div_nonneg ht hpos.le, ?_, div_mul_cancel₀ target hpos.ne'⟩
  apply (div_le_iff₀ hpos).mpr
  simpa using hpay.le

-- The environment in both populations is identical, including the technology.
-- Only the low-risk half of the population differs.
noncomputable def oldIdle (p : ℝ) := idle p (1/2) (baseline p 10 4)
noncomputable def newIdle (p : ℝ) := idle p (1/2) (chosen p 10 4 (1/2) (1/2))

theorem same_baseline_opposite_effects :
    (oldIdle (7/20) + oldIdle (3/5))/2 = 1/5 ∧
    (oldIdle (1/5) + oldIdle (3/5))/2 = 1/5 ∧
    (newIdle (7/20) + newIdle (3/5))/2 = 21/80 ∧
    (newIdle (1/5) + newIdle (3/5))/2 = 1/10 := by
  norm_num [oldIdle, newIdle, idle, chosen, value, baseline, max_def]

theorem marginal_reservation (s h b q : ℝ) :
    h*s + q*b*(1-s) - b = (h-q*b)*s - (1-q)*b := by ring

end AgentUnemployment
