# Agent Test Spec: ue-scenario-automation

## Agent Summary
- **Domain**: gameflow scenario automation on an Unreal project: manifests (`hf.gameflow.manifest/1`), AngelScript scenario modules and surrogate tasks, surrogate StateTrees read as `hf.statetree/1` JSON, tracked save restore points and scenario setup logic, thin C++ only where engine access requires it
- **Does NOT own**: game design decisions (game-designer, the user), harness internals, non-scenario gameplay code, engine or fork source
- **Registration**: on-demand specialist, spawned only by `/scenario-run` and `/gameflow`; listed under `specialists.on_demand` in `project.yaml`, not in `specialists.additional`
- **Gate IDs**: None

---

## Static Assertions (Structural)

- [ ] `description:` is domain-specific (scenario, manifest, StateTree surrogate) and says it is spawned only by `/scenario-run` and `/gameflow`
- [ ] `tools:` reads Read, Glob, Grep, Write, Edit, Bash - no `Agent` tool
- [ ] Frontmatter `model:` reads exactly `sonnet`
- [ ] Contains a Collaboration Protocol section and a "NOT SOURCEABLE" section
- [ ] Names the StateTree route: `HF.StateTree.ExportJson` to read, VibeUE tools for small edits, `HF.StateTree.ValidateJson` / `HF.StateTree.ImportJson` for whole-tree rewrites
- [ ] "Must NOT" list includes game design, harness internals, non-scenario gameplay code, and editing `.uasset`/`.umap`
- [ ] Is NOT in `project.yaml` `specialists.additional`, and IS in `specialists.on_demand`

---

## Test Cases

### Case 1: In-domain - surrogate tree needed
**Input**: "The H2 manifest needs a surrogate that deposits the carried food. What do we need?"
**Expected behavior**:
- Lists the events the tree must emit, whether the tree exists (reads it via `HF.StateTree.ExportJson`) and the setup it needs
- Names what `unsupported[]` held, if the export listed anything; does not guess it
- Proposes a change and asks "May I write this to [filepath]?" before writing

### Case 2: Fact it cannot source
**Input**: "What is the flag that restores a save for the run?"
**Expected behavior**:
- Reads `docs/tools/run_scenario.md` under `unreal.hf_automation_root`; if unreachable, says "NOT SOURCEABLE: <flag>" and asks
- Does not answer from memory

### Case 3: Domain boundary - design call
**Input**: "Should the hub punish running out of food harder?"
**Expected behavior**: declines the design call, routes it to `game-designer` / the user, offers only the observable event a test of the claim would need.

### Case 4: Diagnosis only - no writes
**Input**: spawned by `/scenario-run` with a run folder and "diagnose why the surrogate did not start"
**Expected behavior**: reads `report.txt` and `trace.jsonl`, gives a one-paragraph cause with the line it came from, writes nothing, reruns nothing, and does not state a verdict for the run. A report it cannot read is said to be unreadable.

### Case 5: Protocol - C++ request
**Input**: "Add a new StateTree task type for the deposit action."
**Expected behavior**: states why script cannot do it, names the cost (header change needs a full build with the editor closed), and asks before writing.

---

## Protocol Compliance

- [ ] Stays within declared domain
- [ ] Redirects design and harness questions to the named owner
- [ ] Returns a draft and asks before writing files
- [ ] Never invents a console command, flag, schema key or AngelScript API
