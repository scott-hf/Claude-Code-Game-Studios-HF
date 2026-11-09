# Skill Test Spec: /scenario-run

## Skill Summary

`/scenario-run <manifest> [--seed N] [--repeat N] [--captures] [--analyze] [--scenario Class]`
resolves `unreal.project_root`, `unreal.hf_automation_root` and the scenario class
(`--scenario`, else the manifest's `scenario`, else `unreal.gameflow_scenario`), refuses
`duration_s` above 60 (pointing to `/soak-test`), runs ONE background command
`python -I <hf_automation_root>/tools/wi-helpers/run_scenario.py --project <root> --map <map>
--scenario <class> --args @<manifest> --budget-s 60`, then reads `report.txt`,
`result.json` and `trace.jsonl`. It reports verdict per pass predicate and checkpoint, seed,
wall time, trace path, fail screenshot path, and with `--repeat` the `TRACE-DIFF` line.

Verdicts: `PASS`, `FAIL`, `NOT ASSESSED`. Ranking: `FAIL` over `NOT ASSESSED` over `PASS`.
No report (exit 3) and refused (exit 2) are `NOT ASSESSED`, never `PASS`.

---

## Static Assertions (Structural)

- [ ] Frontmatter has `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`, `model: sonnet`
- [ ] Contains verdict keywords `PASS`, `FAIL`, `NOT ASSESSED` and a ranking statement
- [ ] Names each missing-input stop: `unreal.project_root`, `unreal.hf_automation_root`, `unreal.gameflow_scenario`
- [ ] States the 60 s cap and names `/soak-test`
- [ ] States "judge by report.txt, not the exit code"
- [ ] States that Functional Testing and Gauntlet are out of scope, and that it never drives the editor step by step nor starts a headless Claude session
- [ ] States `--analyze` is exploration, labelled, and never changes a verdict
- [ ] `allowed-tools` has no `Write`, `Edit` and only the `run_scenario.py` Bash pattern
- [ ] Every flag it passes exists in `run_scenario.py`: `--project --map --scenario --args --budget-s --seed --runs --captures`

---

## Director Gate Checks

None.

---

## Fixture Defaults

`modes.automation: collaborative`; `project.local.yaml` with the three `unreal.*` keys set and a
valid manifest, unless the case says otherwise.

---

## Test Cases

### Case 1: Happy path - PASS with all entries covered

**Fixture:** manifest with 2 checkpoints and 3 pass predicates; the run writes `CHECK` lines for all 5
and `RESULT: PASS`, `SEED 1709`, `TRACE ... rows=40`.

**Expected behavior:** one background command (not two), verdict `PASS`, a line `Manifest entries: 5 / CHECK lines
found: 5`, the `DEVIATION: gameplay-loop tier <= 60 s` line, seed, wall time, trace path, `Fail screenshot: none - no failed check`,
`Repeat: n/a (single run)`, and the scope line.

**Assertions:**
- [ ] Exactly one `run_scenario.py` invocation
- [ ] Entry count and CHECK line count are printed and equal
- [ ] The scope line about Functional Testing and Gauntlet is present

### Case 2: FAIL with screenshot

**Fixture:** `event_before` predicate fails; `FAIL-SHOT <path>` present.

**Expected behavior:** verdict `FAIL`, the failing predicate named with the CHECK detail, the screenshot path
printed and the image read. Passing predicates still listed as PASS.

**Assertions:**
- [ ] Verdict is FAIL even if the exit code was 0
- [ ] The failed predicate is named, not summarized as "some checks failed"

### Case 3: NOT ASSESSED - missing config key (silent-skip check)

**Fixture:** `project.local.yaml` has no `unreal.hf_automation_root`.

**Expected behavior:** `STOPPED: unreal.hf_automation_root - ...`; no command runs; no default root is tried.

**Assertions:**
- [ ] The key is named in the output
- [ ] No `run_scenario.py` call was made
- [ ] No verdict of PASS is printed

### Case 4: NOT ASSESSED - no report

**Fixture:** runner exits 3 and `report.txt` is missing.

**Expected behavior:** verdict `NOT ASSESSED (no report)`; the runner's printed reason is quoted; verdict is not FAIL and not PASS.

**Assertions:**
- [ ] The reason is stated
- [ ] "PASS" does not appear as a verdict

### Case 5: NOT ASSESSED - manifest entry with no CHECK line

**Fixture:** report shows `RESULT: PASS`, 4 of the 5 manifest entries have CHECK lines.

**Expected behavior:** that entry is `NOT ASSESSED (no CHECK line ...)`, the run verdict is `NOT ASSESSED`, `Manifest entries: 5 / CHECK lines found: 4`.

**Assertions:**
- [ ] The run is not reported as PASS
- [ ] The missing entry is named

### Case 6: Refused - duration above 60

**Fixture:** manifest `duration_s: 300`.

**Expected behavior:** `REFUSED: duration_s 300 exceeds the 60 s gameplay-loop tier - use /soak-test`, verdict `NOT ASSESSED (refused)`, no command runs.

### Case 7: Repeat - TRACE-DIFF handling

**Input:** `--repeat 2`, with the runner printing `TRACE-DIFF runs=2 events=0 EMPTY (no event rows; equality proves nothing)`.

**Expected behavior:** `Repeat:` quotes the line verbatim and the repeatability is `NOT ASSESSED (repeatability unknown)`, never "identical".

**Assertions:**
- [ ] `EMPTY` and `UNAVAILABLE` never read as identical
- [ ] The `identical` line is quoted verbatim when it appears

### Case 8: --analyze never changes the verdict

**Input:** `--analyze` on a FAIL run.

**Expected behavior:** the verdict block is printed first; the section is labelled `ANALYSIS (exploration, not evidence)`; the verdict is unchanged. Without the flag: `Analysis: not requested`.

---

## Protocol Compliance

- [ ] No file is written by this skill
- [ ] Every `NOT ASSESSED` names its reason
- [ ] A skipped optional step (diagnosis, analysis) is named as not attempted or not requested
