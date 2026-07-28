# Case study: directing an AI agent with auditable correction

## Executive summary

This project is not presented as evidence that an AI agent can generate a
complete simulator without supervision. It demonstrates the opposite:
effective AI-assisted delivery depends on domain judgement, explicit
guardrails, repeatable verification and a durable record of corrections.

The clearest example is the operator-access model. The agent implemented an
elevated cabin and ladder. The project owner recognised from factory-floor
experience that the selected overhead crane should be operated from a
ground-level pendant. The earlier decision was retained in the architecture
log and explicitly superseded before the implementation and tests were
updated.

## Evidence map

| Claim | Evidence |
|---|---|
| The original design used a cabin and ladder | `DECISIONS.md`, `DEC-006`; commit `f4d6975` |
| A human domain correction changed the interaction model | `DECISIONS.md`, `DEC-014` |
| The corrected design is a ground-level pendant | `core/machine_access.gd`, `core/settings.gd`, `core/world_builder.gd` |
| The correction was implemented as a traceable change | Commit `4d6a0c7` |
| Pendulum period matches the analytical solution within 0.15% | `logs/MODULE_TEST_RESULTS.json`, check `period_matches_theory` |
| Module verification passes | `logs/MODULE_TEST_RESULTS.json`: 14/14 |
| End-to-end scene verification passes | `logs/SELFTEST_RESULTS.json`: 21/21 |
| Reset behaviour is deterministic | `logs/SELFTEST_RESULTS.json`, check `reset_deterministic` |
| Cross-run hashes were compared | `logs/TEST_LOG.md`, test `T-003` |

## 1. Governance before generation

The repository contains a small governance layer rather than relying on one
large prompt:

- `.claude/agents/` separates implementation, physics, research and QA roles.
- `.claude/rules/` scopes evidence, physics, localisation and release rules.
- `.claude/hooks/guard_tool.py` blocks unsafe tool patterns.
- `DECISIONS.md` records accepted, superseded and deferred decisions.
- `PROJECT_STATE.md` and `SESSION_HANDOFF.md` keep continuation state explicit.
- Test results are saved as JSON so a passing claim can be checked by a person
  or another agent.

The purpose is not ceremony. Each layer reduces a different failure mode:
unbounded scope, silent factual drift, destructive operations, unverifiable
claims or an unresumable handoff.

## 2. The factual error

`DEC-006` described a fixed elevated operator cabin with a ladder. The model
treated that choice as physically correct and implemented it across access,
camera and test modules.

The project owner challenged the assumption using prior factory-floor
experience: for the selected crane, the operator works from the ground with a
pendant or remote control and watches the load from a safe position.

This was not a cosmetic preference. It changed:

- the operator state machine;
- the access point and safety reasoning;
- the default camera model;
- the factory geometry;
- tutorial and interface language;
- end-to-end test expectations.

## 3. The auditable correction

The project did not delete the wrong reasoning. Instead:

1. `DEC-006` remains in the record with status **superseded**.
2. `DEC-014` identifies the correction, evidence, alternatives and affected
   files.
3. The control station moved to `x=1.0`, outside the bridge's reachable range
   beginning at `x=2.0`.
4. Climb states and cabin camera behaviour were removed.
5. The scene tests were renamed and updated from cabin entry/exit to pendant
   pickup/putdown.
6. All automated checks were rerun.

This provides a reviewable chain from assumption to correction to verified
implementation without exposing private model reasoning.

## 4. Verification instead of trust

### Numerical physics

The four-metre cable test measures a period of `4.0188 s`; the analytical
solution `2π√(L/g)` gives `4.0128 s`, a difference of **0.15%**.

### Automated checks

| Suite | Passing | Coverage examples |
|---|---:|---|
| Module and physics checks | 14/14 | Pendulum, wind, determinism, objectives, access, collision, impact, safety radius |
| Scene self-test | 21/21 | Walking collision, pendant pickup, inspection gate, crane response, cameras, HUD, telemetry, reset |
| Total | **35/35** | Numerical and integrated behaviour |

### Determinism

The module suite compares seeded trajectory hashes. The scene self-test also
repeats a scripted sequence around resets and produces the same hash:

```text
da72cb6efc291dc441ff15ca4680f571
```

The append-only test log records the earlier cross-process comparison rather
than presenting only the final successful run.

## 5. What the tests caught

The verification layer found errors that appeared plausible during
implementation:

- an input press and release occurring within one test tick, invisible to the
  scene's edge detector;
- camera modes reading uninitialised simulation references;
- a 0.5 m mismatch between the cable attachment point and load-box centre;
- type-inference failures caused by values read from dictionaries;
- a test schedule that measured the hoist before acceleration had settled.

These failures are kept in `logs/TEST_LOG.md`. A portfolio claim is stronger
when it shows how defects were discovered and corrected, not only the final
green result.

## 6. Honest boundaries

- Automated behavioural checks do not prove visual polish or usability.
- The project does not grant or replace any legal crane qualification.
- Restitution and damping values still need tuning against a physical
  reference or documented design target.
- Placeholder geometry remains; a production art pass has not been completed.
- The project demonstrates human direction of AI-assisted development, not
  individual authorship of every line.

## Interview-ready summary

> I directed an AI coding agent to build a deterministic overhead-crane
> simulator, but I did not treat its output as authoritative. When it designed
> an elevated cabin, my factory experience told me the operational model was
> wrong. I replaced it with a ground-level pendant, superseded the original
> architecture decision instead of hiding it, and reran 35 automated checks.
> The pendulum period is within 0.15% of the analytical solution, and repeat
> executions produce matching trajectory hashes.
