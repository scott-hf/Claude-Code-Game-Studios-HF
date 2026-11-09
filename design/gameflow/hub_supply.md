# Gameflow: hub_supply

> **Provenance: hand-derived.** This file was written by hand following
> `.claude/skills/gameflow/SKILL.md` (final-validation scoped fix, WI-1709). The `/gameflow`
> skill was NOT run live in a session, so the interview and approval steps (Phase 2 and 4)
> did not happen. Content is taken from the WI-1709 scenario plan (section 0-5 of
> `scenario_plan.md`, which cites PrjEfz source lines) and from the manifest
> `hub_supply-H1.json` that ran PASS in PIE. Refresh it with a live `/gameflow hub_supply`.

Scope: single-process PIE scenarios through `UHF_Scenario` and `run_scenario.py` only.
Functional Testing and Gauntlet are out of scope.

Concept doc: NONE - map built from the WI-1709 scenario plan only
Project: PrjEfz (`LVL_AlternateHomeBase`, the Protozed hub; no level change, no zombies, no Mass)
Project root: RESOLVED E:/p4/prjefz/PrjEfz (hand-resolved; CCGS has no `project.local.yaml`)

## Goals

- Short: fund the Garden project and get it worked to Complete.
- Long: a self-sufficient Food supply (Garden Complete yields 3 Food per day tick).

## Actions

In order of use: walk to the departure board; Fund the Garden and Assign it to the player;
Rest (day tick); walk to the home stash and deposit the carried Food; walk back; Rest again.

## Feedback

Log lines `funded garden route=2`, `assigned garden to player`, `rest day=N`,
`tick day=N+1 hungry=.. thirsty=.. labour=..`, `project complete garden work=1`; the
hunger status tag on the player; the stash and bag counts.

## Resources

Stash `peas` 6 (route 2 costs 4), `WaterBottleFull` 6 (3 per Rest), 1 `CarrotBagSeed`;
the carried bag holds 2 `peas`. Consumption is 1 Food and 1 Water per person per Rest;
people are the player plus two survivors.

## Progression

Day 1 -> 2 -> 3; Garden Available -> Funded -> Complete; stash Food and Water fall each Rest.

## Failure

Rest 1 after paying the cheap route leaves 2 `peas` for 3 people. The player is the first
marked short (hungry), so the player-assigned Garden gets no labour: Garden stays Funded
with 0 work accrued.

## Recovery

Deposit the 2 carried `peas` into the stash and Rest again: nobody is hungry, labour is 1,
the Garden completes. Cost: one walk to the stash and back plus one more day.

## Hypotheses

| id | statement | observable events | pass condition | manifest path | status |
|---|---|---|---|---|---|
| H1 | Paying the Garden with the 4-Food route before restocking leaves the player hungry on the first Rest (no labour); depositing the 2 carried Food lets the second Rest complete the Garden. | `project.funded`, `project.assigned`, `day.rested`, `supply.short`, `stash.deposited`, `project.completed`, `surrogate.stalled` | `event_count` project.funded 1..1; `event_count` day.rested 2..2; `event_order` funded, assigned, rested, supply.short, deposited, rested, completed; `event_before` supply.short then project.completed; `no_event` surrogate.stalled | E:/p4/prjefz/PrjEfz/Tools/Gameflow/scenarios/hub_supply-H1.json | READY |

Emission check: every event in H1 has a literal `Emit` in PrjEfz `Script/AI/Surrogate/EfzGfTasks.as`
(`surrogate.started` is emitted by HF_Common `HF_ScenarioGameflow.as`).

Surrogate/setup plan: StateTree `/Game/AI/Surrogate/ST_PlayerSurrogate_HubSupply`; restore point
`hub_garden_short_food` (tracked at `Tools/Scenario/saves/`); scenario class `EfzGameflowScenario`.
Honest limit: H1 has no seed-dependent branch, so same-seed determinism shows the hub economy
and the surrogate are deterministic, not that the seed changes the loop.

## Report

```
Gameflow: design/gameflow/hub_supply.md
Concept doc: NONE - map built from the WI-1709 scenario plan only
Project root: RESOLVED E:/p4/prjefz/PrjEfz   Manifests in: E:/p4/prjefz/PrjEfz/Tools/Gameflow/scenarios
Hypotheses: 1  READY 1  STUB 0  NOT ASSESSED 0
Missing manifest fields: none
Scope: single-process PIE scenarios only; Functional Testing and Gauntlet are out of scope.
```

Verdict (hand-derived): MAPPED
