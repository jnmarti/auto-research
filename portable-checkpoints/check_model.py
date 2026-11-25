"""Exact arithmetic for numerical claims, plus grid checks of the posted optimum."""
from fractions import Fraction as Q

V, k, a, s = map(Q, (".9", ".1", ".45", ".2"))

def evaluate(q, b):
    f = min(b, Q(1))  # uniform CDF
    rent = b * f - f**2 / 2
    r = max(0, a - rent)
    complete = q + (1 - q) * f
    payoff = s - r + f * (V - b) + (1 - f) * q * (V - k)
    return complete, payoff

for q, expected in [(Q(0), (Q(".9"), Q(".155"))),
                    (Q(".1"), (Q(".838"), Q(".1662")))]:
    assert evaluate(q, V - q * (V - k)) == expected
for j in range(21):
    q = Q(j, 20)
    b = V - q * (V - k)
    _, best = evaluate(q, b)
    assert all(best >= evaluate(q, Q(i, 100))[1] for i in range(151))

q = Q(".1")
informed_completion = q + (1-q)*V
info_gain = q*(1-q)*(V-k)**2/2
assert informed_completion == Q(".91")
assert info_gain == Q(".0288")
print("Verified exact example, information gain, and bonus against grid deviations.")
