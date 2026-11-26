"""Reproduce Table 2 and the two-population example using exact arithmetic."""

from fractions import Fraction as F
from typing import NamedTuple


class Outcome(NamedTuple):
    policy: str
    value: F
    idle: F


def evaluate(policy, p, h, b, q, k):
    """Enumerate urgent, quiet/feasible, and quiet/infeasible states."""
    states = [(p, True, False), ((1-p)*q, False, True),
              ((1-p)*(1-q), False, False)]
    value = -k if policy == "queue" else F(0)
    idle = F(0)
    for probability, urgent, feasible in states:
        if policy == "run":
            value += probability * b
        elif urgent:
            value += probability * h
        elif policy == "queue" and feasible:
            value += probability * b
        else:
            idle += probability
    return Outcome(policy, value, idle)


def choices(p, h, b, q, k):
    # max returns the first maximizer: run wins the baseline tie, and a
    # baseline policy wins a tie with the queue, as in the manuscript.
    policies = [evaluate(a, p, h, b, q, k) for a in ("run", "hold", "queue")]
    return (max(policies[:2], key=lambda a: a.value),
            max(policies, key=lambda a: a.value))


def main():
    h, b, q, k = F(10), F(4), F(1, 2), F(1, 2)
    lower = ((1-q)*b+k)/(h-q*b)
    upper = 1-k/(q*b)
    assert (lower, b/h, upper) == (F(5, 16), F(2, 5), F(3, 4))
    rows = {}
    expected = {
        F(1, 5):  (("run", 4, 0), ("run", 4, 0)),
        F(7, 20): (("run", 4, 0), ("queue", F(43, 10), F(13, 40))),
        F(3, 5):  (("hold", 6, F(2, 5)), ("queue", F(63, 10), F(1, 5))),
    }
    for p, reference in expected.items():
        rows[p] = choices(p, h, b, q, k)
        assert rows[p] == reference
        print(f"p = {p}: {rows[p]}")

    for early, new_idle, gain in [(F(7, 20), F(21, 80), F(3, 10)),
                                  (F(1, 5), F(1, 10), F(3, 20))]:
        group = [rows[early], rows[F(3, 5)]]
        assert sum(old.idle for old, _ in group)/2 == F(1, 5)
        assert sum(new.idle for _, new in group)/2 == new_idle
        assert sum(new.value-old.value for old, new in group)/2 == gain
    m = F(1, 2)
    holder_quiet_mass = (1-m)*(1-F(3, 5))
    floor = F(1, 5) - q * holder_quiet_mass
    ceiling = floor + m*(1-q)*(1-lower)
    assert (floor, ceiling) == (F(1, 10), F(87, 320))
    old, new = rows[F(3, 5)]
    assert (new.value-old.value)/(old.idle-new.idle) == F(3, 2)

    # Include both indifference points, full dispatch and no dispatch.
    for risk in [F(i, 80) for i in range(81)]:
        old, new = choices(risk, h, b, q, k)
        assert (new.policy == "queue") == (lower < risk < upper)
        if new.policy == "queue":
            change = (1-risk)*(1-q) if old.policy == "run" else -(1-risk)*q
            assert new.idle-old.idle == change
        assert choices(risk, h, b, F(0), k)[1] == old
        assert choices(risk, h, b, F(1), k)[1].idle <= old.idle
    print(f"New expiry range: [{floor}, {ceiling}). All checks passed.")


if __name__ == "__main__":
    main()
