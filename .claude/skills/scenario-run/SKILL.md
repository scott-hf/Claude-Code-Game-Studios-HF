---
name: scenario-run
description: "Run a gameflow scenario manifest as one short seeded PIE scenario and report the verdict per pass predicate and checkpoint, the seed, the event trace and the fail screenshot."
argument-hint: "<manifest> [--seed N] [--repeat N] [--captures] [--analyze] [--scenario Class]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Agent, Bash(python -I */tools/wi-helpers/run_scenario.py *)
model: sonnet
---

# Scenario Run

Runs ONE manifest (`hf.gameflow.manifest/1`, written by `/gameflow`) through
`run_scenario.py` as a single PIE scenario played by a StateTree player surrogate, then
reads what the game wrote and reports it. The game judges; this skill reads the report.

**Scope (stated in every report):** single-process PIE scenarios only. Functional Testing and
Gauntlet are out of scope. This skill never drives the editor step by step and never starts a
headless Claude session. LLM-driven play is not offered.

**Verdict vocabulary:** `PASS`, `FAIL`, `NOT ASSESSED`. `NOT ASSESSED` means the run could not
establish the answer (no report, refused, missing predicate line). It is never reported as
`PASS` and never as `FAIL`; the reason is named. Ranking for the run as a whole:
`FAIL` outranks `NOT ASSESSED`, and `NOT ASSESSED` outranks `PASS`. One predicate that could not
be assessed makes the run `NOT ASSESSED` even when every other predicate passed.

---

## Phase 1: Resolve inputs (stop at the first missing one)

Each stop prints `STOPPED: <name> - <what to do>` and ends the skill. No value is defaulted.

| Input | Source | If absent |
|---|---|---|
| manifest | first argument; absolute, or relative to the project root, or to the current folder | `STOPPED: manifest` |
| `unreal.project_root` | `project.local.yaml` (Read it) | `STOPPED: unreal.project_root` |
| `unreal.hf_automation_root` | `project.local.yaml` | `STOPPED: unreal.hf_automation_root` |
| scenario class | `--scenario` argument, else the manifest's `scenario` key, else `unreal.gameflow_scenario` in `project.local.yaml` | `STOPPED: unreal.gameflow_scenario` (name the key; the generic HF_Common class is `UHF_GameflowScenario`, a project subclass such as `EfzGameflowScenario` is usual) |

Then check the files exist: `<hf_automation_root>/tools/wi-helpers/run_scenario.py` and the manifest.
A missing one is `STOPPED: <path> does not exist`.

Read the manifest. These fields must be present and non-empty, else the verdict is
`NOT ASSESSED (manifest incomplete: <field>)` and nothing runs:
`schema` equal to `hf.gameflow.manifest/1`, `id`, `map`, `duration_s`, `surrogate.state_tree`,
at least one `pass` entry. A `/gameflow` stub with `""` values lands here by design.

**Duration cap:** `duration_s` above 60 is refused: `REFUSED: duration_s <n> exceeds the 60 s
gameplay-loop tier - use /soak-test for longer runs.` Verdict `NOT ASSESSED (refused)`.

If `--seed` is not given, the manifest `seed` is used. If neither exists, the run has no seed
and the report says `Seed: NONE (run is not repeatable)`.

## Phase 2: Run (one command)

ONE background Bash call (`run_in_background: true`); the runner waits for itself and prints
escalating progress. Do not poll, do not run it twice to "check":

```bash
python -I <hf_automation_root>/tools/wi-helpers/run_scenario.py --project <project_root> --map <manifest map> --scenario <class> --args @<manifest> --budget-s 60 [--seed N] [--runs N] [--captures]
```

`--repeat N` maps to `--runs N`; `--seed N` maps to `--seed N`; `--captures` maps to `--captures`.
The 60 s budget is a stated deviation from the 20 s checks-only standard (DOC-0148): print
`DEVIATION: gameplay-loop tier <= 60 s (20 s checks-only budget)` in the report.

## Phase 3: Read the evidence

Take the output folder from the last `SCENARIO-RESULT: ... dir=<path>` line. With `--repeat N`
the per-run folders are `run_1` ... `run_N` inside it; read each.

| Exit code | Meaning here |
|---|---|
| 2 | refused (another UE process, runner lock, failed map open, missing restore save) -> `NOT ASSESSED (refused)` with the printed reason |
| 3 | no report or no valid runtime proof (crash, compile error, timeout) -> `NOT ASSESSED (no report)` |
| 0 or 1 | read the report; the exit code does not decide the verdict |

Judge by `report.txt`, not the exit code. Read `report.txt`, `result.json`, `trace.jsonl` in each
run folder. A missing `report.txt` is `NOT ASSESSED (no report)` whatever the exit code says.

From `report.txt`:
- `RESULT: PASS|FAIL`; `SEED <n>`; `WALL <s> s`; `TRACE <path> rows=<n>`; `FAIL-SHOT <path>`;
  `RESTORED-SAVE <name>`; `CHECKPOINT <name> <t> s`; `TIMING-BUDGET` lines on stdout.
- `CHECK <id> checkpoint_<name>: PASS|FAIL` per manifest checkpoint and
  `CHECK <id> <event_count|event_order|no_event|event_before>: PASS|FAIL` per pass predicate
  (`UHF_GameflowScenario` writes them; ids from 100 and from 200).
- `CHECK 1 manifest_valid` and `CHECK 2 surrogate_running`: a FAIL here means the loop never ran.

**Derive the covered set from the manifest, not from the report.** For every `checkpoints[i]` and
`pass[i]` in the manifest, find its CHECK line. A manifest entry with no CHECK line is
`NOT ASSESSED (no CHECK line - the scenario did not evaluate it)`. The count of manifest entries
is printed next to the count of CHECK lines found; they must be equal for a `PASS`.

If `trace.jsonl` is missing or has no `kind:event` row, say `Trace: EMPTY` and the run cannot
be `PASS` (a predicate such as `no_event` passes on nothing; an empty trace proves nothing).

## Phase 4: Report

```
Scenario run: <manifest id>   Class: <class>   Map: <map>
Verdict: PASS | FAIL | NOT ASSESSED (<reason>)
Seed: <n | NONE>   Wall: <s> s (budget 60)   Runs: <n>
DEVIATION: gameplay-loop tier <= 60 s (20 s checks-only budget)
Manifest entries: <checkpoints+pass> / CHECK lines found: <n>
Checkpoints: <name> <PASS|FAIL|NOT ASSESSED> at <t> s (by <by_s> s)
Predicates:  <kind> <PASS|FAIL|NOT ASSESSED> <detail from the CHECK line>
Trace: <path> rows=<n>
Fail screenshot: <path | none - no failed check | NOT TAKEN (<reason>)>
Repeat: <TRACE-DIFF line verbatim | n/a (single run)>
Scope: single-process PIE only; Functional Testing and Gauntlet out of scope.
```

With `--repeat N`, the `TRACE-DIFF` line is quoted as printed. `identical` = same event sequence.
`DIFFERENT` is reported with the `first_diff` it names. `EMPTY` or `UNAVAILABLE` is
`NOT ASSESSED (repeatability unknown)`: never "identical".

Read the fail screenshot when `FAIL-SHOT` is present (one image; do not open the others).

### Diagnosing a NOT ASSESSED or surrogate failure (optional delegation)

When the cause is not in the runner's printed reason (surrogate did not start, restore point
missing, setup hook absent), ask the `ue-scenario-automation` agent to find the cause: goal is
a one-paragraph diagnosis. Pass it the run folder path and the manifest path as inputs. It
reads only; do not let it rerun the scenario or edit files. Verify the cause it names against
`report.txt` or `trace.jsonl` before quoting it (re-check, never relay). If it is not used, write
`Diagnosis: NOT ATTEMPTED`.

## Phase 5: `--analyze` (optional)

Only with `--analyze`, and only after Phase 4 is printed. Read `trace.jsonl` and note timing gaps,
repeated events, long idle stretches and which checkpoint ran closest to its `by_s`. Label the
section `ANALYSIS (exploration, not evidence)`. It never changes a verdict, a predicate or the
seed. Without the flag print `Analysis: not requested`.

---

## Recommended Next Steps

- `FAIL`: open the fail screenshot and `trace.jsonl` around the first failed check, then `/gameflow <loop>` to revise the hypothesis or fix the loop
- `NOT ASSESSED`: fix the named cause (key, missing event, missing restore point) and run again; do not treat it as a pass
- `PASS` with `--repeat`: confirm the `TRACE-DIFF` line says `identical` before calling the run repeatable
