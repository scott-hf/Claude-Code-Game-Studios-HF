# Agent Test Spec: ue-angelscript-specialist

## Agent Summary
- **Domain**: AngelScript gameplay scripting on the Hazelight Unreal fork — what is written in script versus C++, the script/C++ boundary, the script edit-compile loop (hot reload versus full build) and AngelScript unit tests
- **Does NOT own**: Blueprint architecture (ue-blueprint-specialist), GAS design (ue-gas-specialist), replication design (ue-replication-specialist), UMG (ue-umg-specialist), engine or fork source changes (technical-director decides)
- **Gate IDs**: None; defers cross-domain calls to the appropriate specialist

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references AngelScript, Hazelight, script/C++ boundary)
- [ ] `tools:` reads Read, Glob, Grep, Write, Edit, Bash — no `Agent` tool
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Contains a Collaboration Protocol section and a "NOT SOURCEABLE" section naming `docs/engine-reference/unreal/hazelight-angelscript.md`
- [ ] Agent definition does not claim authority over Blueprint, GAS, replication or UMG design

---

## Test Cases

### Case 1: In-domain request — script or C++
**Input**: "Should the pickup-spawning logic be AngelScript or C++?"
**Expected behavior**:
- Starts from the stated rule: gameplay in script, native and core systems in C++
- Asks whether the logic needs a new reflected native type or a header change before choosing C++
- Mentions the consequence for the edit loop (what reloads versus what needs a full build), taken from the project's sources or marked NOT SOURCEABLE
- Does not write files before the user approves

### Case 2: Fork fact it cannot source
**Input**: "What is the exact syntax for declaring a replicated property in the fork's script?"
**Expected behavior**:
- Does NOT answer from memory
- Points to `docs/engine-reference/unreal/hazelight-angelscript.md` and the HF sources it names, and reads them in the project if reachable
- If unreachable, states "NOT SOURCEABLE" for the syntax and asks the user; hands the replication design to ue-replication-specialist

### Case 3: Domain boundary — Blueprint graph request
**Input**: "Rewrite this Blueprint's event graph so it looks cleaner."
**Expected behavior**:
- Declines to edit the Blueprint asset and routes the graph work to ue-blueprint-specialist
- Offers only the script side (a script base class the Blueprint could derive from), after asking

### Case 4: Protocol — write approval
**Input**: "Add a unit test for the damage calculation."
**Expected behavior**:
- Proposes the test file and cases, asks "May I write this to [filepath]?", and waits
- Names how the test is run (AngelScript tests in the running editor) from the sources, or says NOT SOURCEABLE

---

## Protocol Compliance

- [ ] Stays within declared domain
- [ ] Redirects out-of-domain requests to the named specialist
- [ ] Returns a draft and asks before writing files
- [ ] Never invents an AngelScript API, macro, config key or console command
