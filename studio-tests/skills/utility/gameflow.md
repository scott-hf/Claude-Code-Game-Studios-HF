# Skill Test Spec: /gameflow

## Skill Summary

`/gameflow <loop-name> [concept-doc-path]` maps ONE loop as `design/gameflow/<loop>.md`
(Goals, Actions, Feedback, Resources, Progression, Failure, Recovery, and a Hypotheses
table: id, statement, observable events, pass condition, manifest path, status). Each
assessable hypothesis becomes a manifest stub `hf.gameflow.manifest/1` at
`<unreal.project_root>/Tools/Gameflow/scenarios/<loop>-<H#>.json` when that key resolves,
else `design/gameflow/manifests/`. A hypothesis with no observable event is
`NOT ASSESSED` and gets no manifest. It drafts, shows, and asks before each write.

Verdicts: `MAPPED`, `MAPPED WITH GAPS`, `REDIRECTED`. Statuses per hypothesis: `READY`,
`STUB`, `NOT ASSESSED`.

---

## Static Assertions (Structural)

- [ ] Frontmatter has `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`, `model: sonnet`
- [ ] Has at least 2 phase headings
- [ ] Contains verdict keywords `MAPPED`, `MAPPED WITH GAPS`, `REDIRECTED` and the status words `READY`, `STUB`, `NOT ASSESSED`
- [ ] Contains "May I write" language, once for the map and once per manifest
- [ ] Ends with a "Recommended Next Steps" section naming `/scenario-run`
- [ ] Names the `unreal.project_root` key and says what happens when it is absent (manifests to `design/gameflow/manifests/`, announced)
- [ ] States that Functional Testing and Gauntlet are out of scope
- [ ] `allowed-tools` has no `Bash` pattern other than `yaml-helper.sh resolve_config`

---

## Director Gate Checks

None. The skill resolves `automation` and `workflow`, not `review_mode`, and runs no director gate.

---

## Fixture Defaults

Every case sets `modes.rigor: minimal` and `modes.automation: collaborative`, with a
`project.local.yaml` that has `unreal.project_root` pointing at an existing folder holding a
`*.uproject`, unless the case says otherwise.

---

## Test Cases

### Case 1: Happy path - two hypotheses, one ready

**Fixture:** `design/gdd/game-concept.md` has a Core Loop section. The project's `Script/` contains an
`Emit("supply.short", ...)` call and an `Emit("project.completed", ...)` call.

**Input:** `/gameflow hub_supply`

**Expected behavior:**
1. Resolves `unreal.project_root` and prints `RESOLVED <path>`; reads the concept doc Core Loop
2. Asks the seven sections; drafts the map; the hypotheses table carries H1 with events `supply.short`, `project.completed` and status `READY`
3. Shows the full draft, asks `[A]/[B]/[C]`, then "May I write this to `design/gameflow/hub_supply.md`?"
4. Shows the H1 manifest JSON, asks "May I write `<root>/Tools/Gameflow/scenarios/hub_supply-H1.json`?"
5. Report prints the counts `READY 1  STUB 0  NOT ASSESSED 0` and verdict `MAPPED`

**Assertions:**
- [ ] No file is written before its own "May I write" ask is answered
- [ ] The manifest path is under `Tools/Gameflow/scenarios/` and the report names that folder
- [ ] The manifest has `schema: hf.gameflow.manifest/1` and `duration_s` at most 60
- [ ] READY + STUB + NOT ASSESSED equals the number of table rows

### Case 2: NOT ASSESSED - hypothesis with no observable event

**Input:** `/gameflow hub_supply` where the user states H2 as "the hub feels rewarding"

**Expected behavior:** H2 gets status `NOT ASSESSED (no observable event)`, NO manifest is
asked for or written for it, the report lists `H2 NOT ASSESSED (no observable event) - no manifest
written`, and the verdict is `MAPPED WITH GAPS`, never `MAPPED`.

**Assertions:**
- [ ] No `hub_supply-H2.json` exists after the run
- [ ] The report names H2 and the missing piece; a silent omission fails this case
- [ ] The verdict is `MAPPED WITH GAPS`

### Case 3: Silent-skip check - project root unresolved

**Fixture:** `project.local.yaml` has no `unreal.project_root` key.

**Expected behavior:** manifests go to `design/gameflow/manifests/`; the report prints
`Project root: UNRESOLVED (key absent)` and `Manifests in: design/gameflow/manifests/`; the event-emission
search cannot run, so a hypothesis with named events is `STUB (emission not checked - project root unresolved)`, not `READY`.

**Assertions:**
- [ ] The output says the key is absent by name
- [ ] No hypothesis is `READY` in this run
- [ ] No guessed project path appears anywhere

### Case 4: Stub - event named but not emitted

**Fixture:** root resolved; `Script/` has no `Emit` of the event `stash.deposited`.

**Expected behavior:** the manifest stub is written and the hypothesis is `STUB (event not emitted)`;
verdict `MAPPED WITH GAPS`.

**Assertions:**
- [ ] The report lists the hypothesis as STUB with the event name
- [ ] The run does not say "ready to run" for it

### Case 5: Duration above the cap and missing fields

**Input:** the user asks for `duration_s: 300` and gives no map.

**Expected behavior:** `duration_s` above 60 is refused with a pointer to `/soak-test`; the missing map is written as `""`
and listed under `Missing manifest fields`; no sample map or seed is invented.

**Assertions:**
- [ ] `/soak-test` is named
- [ ] The manifest has `"map": ""`, not a made-up path
- [ ] The `Missing manifest fields` line names the map

### Case 6: Redirect

**Input:** `/gameflow settings-menu` and the user picks `[C]`.

**Expected behavior:** stops with verdict `REDIRECTED`, names `/design-system`, writes no file.

---

## Protocol Compliance

- [ ] Draft shown in full before any write ask
- [ ] A skipped step (unresolved root, no concept doc, no delegation) is named in the output
- [ ] Counts in the report are derived from the table, and the report is internally consistent
