---
name: gameflow
description: "Map one game loop (goals, actions, feedback, resources, progression, failure, recovery) as a single artifact, with testable hypotheses, each tied to a scenario manifest that /scenario-run plays."
argument-hint: "<loop-name> [concept-doc-path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/gameflow/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow`

# Gameflow

Maps ONE loop of the game as one document, `design/gameflow/<loop>.md`, and turns each
hypothesis about that loop into a scenario manifest (`hf.gameflow.manifest/1`) that
`/scenario-run` plays as a short, seeded PIE scenario with a StateTree player surrogate.

**Output:** `design/gameflow/<loop>.md` plus one manifest stub per assessable hypothesis.

**When to run:** a loop exists (or is designed) and you want to test a claim about it
repeatably: "does paying X before Y leave the player stuck?", "does recovery take under
a minute?". Not for tuning a number (`/quick-design`) or a full system GDD (`/design-system`).

Every `AskUserQuestion` call and every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). Ask with the question tool; without one,
list the options numbered and end your turn.

**Scope line (state it in the output):** single-process PIE scenarios through
`UHF_Scenario` and `run_scenario.py` only. Functional Testing and Gauntlet are out of scope.
This skill never drives the editor and never starts a headless Claude session.

---

## Phase 1: Resolve inputs

1. `<loop-name>` is required. Absent: ask for it in plain text. Accept `[a-z0-9_-]` only;
   it becomes the file stem, so a name with other characters is re-asked, not rewritten.
2. Resolve `unreal.project_root` from `project.local.yaml` (Read it; the key is not in
   `project.yaml`). Record the result as one of:
   - `RESOLVED <path>`: the folder exists and holds a `*.uproject`
   - `UNRESOLVED (key absent)` or `UNRESOLVED (path missing)`
   An unresolved root is not an error here: the manifests go to `design/gameflow/manifests/`
   and the output says so by name (Phase 5). It is never defaulted to a guessed path.
3. Concept doc: the second argument, else `design/gdd/game-concept.md` if it exists. Read
   its Core Loop, feedback, recovery, progression and hypothesis prose (`map-systems`
   consumes the same sections) and keep the loop map consistent with it. A conflict is shown
   to the user as a conflict; it is not silently resolved. With no concept doc, say
   `Concept doc: NONE - map built from the conversation only`.
4. An existing `design/gameflow/<loop>.md`: read it, show what changes, and treat the run as an
   update (Phase 4 asks before overwriting).

## Phase 2: Draft the loop map

Interview in plain text, one block of questions at a time, until each section below has
content the user confirmed. A section the user cannot fill is written as `NOT ASSESSED -
<what is missing>`; it is never filled from what such games usually do.

| Section | What it holds |
|---|---|
| Goals | What the player is trying to reach, short and long |
| Actions | What the player can do in the loop (verbs, in order of use) |
| Feedback | What the game shows or plays back after each action |
| Resources | What is spent, earned, carried, capped |
| Progression | What changes between passes of the loop |
| Failure | How the loop goes wrong or stalls |
| Recovery | How the player gets out of a failure, and what it costs |

## Phase 3: Hypotheses

A hypothesis is a claim the loop can falsify. For each one the table row needs:

| Column | Rule |
|---|---|
| id | `H1`, `H2`, ... stable within the loop |
| statement | One sentence, falsifiable |
| observable events | Event names the game emits through the scenario trace (`UHF_ScenarioTraceSubsystem::Emit`). Dotted lower-case, e.g. `supply.short` |
| pass condition | Built only from the four predicates: `event_count` (event, min, max), `event_order` (events[]), `no_event` (event), `event_before` (first, then) |
| manifest path | Filled in Phase 5 |
| status | See below |

Status values, in this order of precedence when more than one applies:

- `NOT ASSESSED (no observable event)`: the claim names no event the game can emit. It gets
  NO manifest. The output lists it by id with the missing piece ("needs an event for X").
- `NOT ASSESSED (no pass condition)`: events exist but no predicate decides the claim. No manifest.
- `STUB (event not emitted)`: the events are named but a search of the project's `Script/` and
  `Source/` for the literal event name found no `Emit` of it. The manifest stub is written
  and marked; `/scenario-run` will fail its predicate rather than pass. Never report such a
  hypothesis as ready. When the project root is unresolved, the search cannot run: the status
  is `STUB (emission not checked - project root unresolved)`.
- `READY`: every named event has an `Emit` found in the project, and the pass condition is complete.

Also ask for, per hypothesis: map (`/Game/...`), seed (integer; ask, never invent one),
`duration_s` (at most 60; above 60 is refused here and redirected to `/soak-test`), optional
`restore_save` name, the surrogate StateTree asset path and pawn, and `checkpoints[{name, event, by_s}]`.
A value the user does not give is written as an empty string and listed under
`Missing manifest fields`; `/scenario-run` refuses a manifest with an empty required field.

### Delegation (on demand)

When a hypothesis needs a surrogate tree that does not exist, a save restore point, or
custom scenario setup logic, ask the `ue-scenario-automation` agent to draft the plan for it
(goal: name the tree, the events it must emit and the setup it needs). Pass it the loop map
section file path and the hypothesis row as input. Do not let it write files: the agent drafts,
this skill shows the draft, and the user approves. Verify the agent's event names against the
hypothesis table before using them (re-check, never copy blind). If the agent is unavailable
or the user declines, write `Surrogate/setup plan: NOT DRAFTED (<reason>)` in the output.

## Phase 4: Show the draft and ask

Present the full document and the hypotheses table. Then `AskUserQuestion`:
- Prompt: "Here is the gameflow draft for `<loop>`. How do you want to proceed?"
- Options: `[A] Approve - write it as shown`, `[B] Revise - I'll describe what to change`,
  `[C] Not a loop - redirect to /design-system`

[B]: collect changes, redraft, ask again. [C]: stop; verdict **REDIRECTED**.
[A]: ask "May I write this to `design/gameflow/<loop>.md`?" (create `design/gameflow/` if absent).
Overwriting an existing file shows old vs. new first.

## Phase 5: Manifest stubs

For each hypothesis that is not `NOT ASSESSED`, show the manifest JSON and ask "May I write
`<path>`?" per file (one ask per manifest; a file is never written on a batch yes for another).

- Path: `<unreal.project_root>/Tools/Gameflow/scenarios/<loop>-<H#>.json` when the root is
  `RESOLVED`; otherwise `design/gameflow/manifests/<loop>-<H#>.json`.
  The output states which one applied and why ("unreal.project_root: UNRESOLVED (key absent)").
- Shape (`hf.gameflow.manifest/1`):

```json
{
  "schema": "hf.gameflow.manifest/1",
  "id": "<loop>_<H#>",
  "hypothesis": "<statement>",
  "project": "<project name>",
  "map": "/Game/...",
  "seed": 0,
  "duration_s": 60,
  "restore_save": "<optional name>",
  "surrogate": {"state_tree": "/Game/...", "pawn": "player"},
  "setup": {},
  "checkpoints": [{"name": "...", "event": "...", "by_s": 20}],
  "pass": [{"kind": "event_count", "event": "...", "min": 1, "max": 1}],
  "capture_on_fail": true
}
```

- Write the real values the user gave; leave the rest as `""`. Never write a placeholder that
  looks valid (no sample map, no sample seed).
- Fill `manifest path` and `status` in the table back in `design/gameflow/<loop>.md` (Edit, same approval).

## Phase 6: Report

```
Gameflow: design/gameflow/<loop>.md
Concept doc: <path | NONE - ...>
Project root: <RESOLVED <path> | UNRESOLVED (...)>   Manifests in: <folder>
Hypotheses: <total>  READY <n>  STUB <n>  NOT ASSESSED <n>
  <id> NOT ASSESSED (<reason>) - no manifest written
  <id> STUB (<reason>)
Missing manifest fields: <id: field, field | none>
Scope: single-process PIE scenarios only; Functional Testing and Gauntlet are out of scope.
```

Every count is derived from the table you just wrote, not remembered. A count line that does
not add up (READY + STUB + NOT ASSESSED != total) is a defect: fix the table before reporting.

Verdict: **MAPPED** when every hypothesis is `READY`. **MAPPED WITH GAPS** when any is `STUB` or
`NOT ASSESSED`; the list above says which, and "ready to run" is never claimed for them.
**REDIRECTED** per Phase 4.

---

## Recommended Next Steps

- `/scenario-run <manifest>` for each `READY` hypothesis (a `STUB` fails on purpose until its event is emitted)
- Add the missing events or surrogate trees, then rerun `/gameflow <loop>` to refresh the statuses
- `/design-system` or `/quick-design` when a hypothesis result changes a rule
