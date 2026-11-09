# Unreal — Hazelight AngelScript Fork

| Field | Value |
|-------|-------|
| **Applies when** | `project.yaml` lists AngelScript in `engine.languages`, or the project's engine is the Hazelight UnrealEngine-AngelScript fork |
| **Fork** | Hazelight's UnrealEngine-AngelScript fork of Unreal Engine (this reference is written against 5.8) |
| **Primary gameplay language** | AngelScript. C++ owns native and core systems and plugins; Blueprint stays a supported production tool |
| **Sourced from this repo** | NO — see below |

## What this repo can and cannot tell you

`docs/engine-reference/unreal/` documents Epic's Unreal Engine. **Nothing in this repository
documents the fork's script syntax, its API surface, its reload rules or its test runner.**
Those facts are **NOT SOURCEABLE** from here, so no agent states one from memory: an
invented AngelScript API compiles in nobody's editor and reads as fact in the docs.

What this file does state is only the split the fork's users work under (above): script for
gameplay, C++ for native systems. Everything finer is read from the sources below, in the
project, before it is used.

## Where the fork's facts live

These are HF sources, outside this repo. Read them in the project; if they are unreachable,
write `NOT SOURCEABLE: <the fact>` and ask the user.

| Need | Source |
|------|--------|
| Writing or porting script | HF skill `hf-unreal-projects:dev-as`; the fork's own docs shipped with the engine fork |
| Script unit tests | HF skill `hf-unreal-projects:as-tests` |
| Scenario / PIE validation standard (`UHF_Scenario`, `run_scenario.py`) | HF registry doc `DOC-0148` |
| Compile check after an edit | HF skill `hf-unreal-projects:validate-as` |

## Rules this repo applies

- Reload and build rules for script versus native code (what hot-reloads, what needs a full
  build) are fork facts: read them from the sources above, not from here.
- `ue-angelscript-specialist` owns the script layer; `unreal-specialist` decides
  Blueprint versus script versus C++.
- Do not edit the fork's own (Hazelight or Epic) code to fix a project problem.

## Related

- `docs/engine-reference/unreal/VERSION.md` — the pinned engine version
- `.claude/agents/ue-angelscript-specialist.md`
