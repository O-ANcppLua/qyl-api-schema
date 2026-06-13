# qyl-api-schema — Telemetry Control Graph: verified handoff

> Written 2026-06-13 by Opus 4.8 (session c50f930f) as the single source of truth for the
> Cowork continuation. Replaces the secondhand "12 points before release" paste, which was a
> mid-work snapshot and is now ~80% stale. Everything below is **verified by running the build**,
> not copied from another agent.

## Verdict: v1 is GREEN and emitting. Not a crisis.

Verified on HEAD `8b017c6` (clean tree), all exit 0:

| Check | Command | Result |
|---|---|---|
| Emitter TS build | `npm run build:emitters` | ✅ clean, no tsc errors |
| Full compile + emit | `npx tsp compile main.tsp` | ✅ all 5 emitters run |
| Lint (warn-as-error) | `npm run lint` | ✅ clean |
| Artifacts | `ls generated/control-graph/` | ✅ all 8 files emitted |

The 8 emitted artifacts: `control-graph.json`, `control-graph.yaml`,
`instrumentation-profiles.json`, `declared-signals.json`, `export-edges.json`,
`control-graph.schema.json`, `conformance-plan.json`, `control-graph.report.md`.

## What the 12-point list got wrong (already done)

- **P1 `bad-emitter-option` / `NoTarget`, P2 broken `linter.ts`, P3 missing `index.ts` export** —
  the emitter + linter TS now compile clean. Build proves it.
- **P4 old names (`typespec-emit-tcg`, `emitters/tcg`, `@ancplua/typespec-emit-tcg`)** — `grep`
  finds zero. Gone. Package is `@qyl/telemetry-control-graph` everywhere; dir is
  `emitters/telemetry-control-graph`.
- **P5 tspconfig activation, P11 package-lock, P12 artifacts present** — compile emits all 8 to
  `generated/control-graph/`. Done.

## What is GENUINELY open (depth decisions, NOT blockers)

These are "how rich is the contract", not bugs. Ship-shallow-v1 is a valid choice.

- **P8 — profile normalization.** `instrumentation-profiles.json` is currently just
  `profile_id → service_names` (verified: only `qyl-default → [qyl.collector, qyl.dashboard]`).
  The emitter reads the `@instance(...)` graph value but does **not** traverse
  `GenerationProfileEntity`. Decision: leave shallow, or make the emitter collect Profile bodies
  TypeSpec-semantically (or put them structurally in the instance).
- **P9 — edge granularity.** `export-edges.json` is `service_name + signal_kind → exporter`
  (verified). If the runtime verifier needs `service + concrete signal name → exporter`, expand
  edge generation over declared signals.
- **P10 — collector/channel as explicit fields.** `ExportEdge` currently carries `exporter_id`,
  `protocol`, `endpoint_env_var` — no `target_id`/`channel`. Add only if "collector/channel" is
  meant to be contract.
- **P6 — `fail-on-diagnostics`.** Typed but `grep` finds no impl in
  `emitters/telemetry-control-graph/src`. Hard graph errors are already `error`; linter warnings
  escalate via `--warn-as-error`. Either implement the option or delete the typed-but-dead knob.

## Definition of done (the verification goal)

A change is DONE when, from `qyl-api-schema/`:

```bash
npm run build:emitters   # exit 0
npx tsp compile main.tsp # exit 0, all 5 emitters run
npm run lint             # exit 0 (tsp --warn-as-error)
```

…and `generated/control-graph/` holds all 8 artifacts with the intended wire-shape
(`schema_version`, `service_name`, `profile_id`, `exporter_id`, `endpoint_env_var`; signal enums
`span|metric|log|profile`; protocols `otlp_grpc|otlp_http`; requirements
`required|recommended|opt_in`). For P8–P10 changes, also assert the new fields appear in the
emitted JSON.

## TODO (ordered, do in qyl-api-schema — separate repo, no Codex conflict)

1. **Decide v1 scope**: ship shallow-as-is, or deepen P8→P9→P10 first. (Alex's call — these
   change the contract surface the .NET runtime verifier will check.)
2. If deepening: **P8** GenerationProfileEntity traversal → **P9** concrete-signal edges →
   **P10** collector/channel fields. Each: extend emitter shape + add a snapshot assertion.
3. **P6**: implement or delete `fail-on-diagnostics` (no dead typed knobs).
4. Re-run the three-command verification goal; confirm 8 artifacts + new fields.
5. Only then: version bump / pack / push.

## Honest scope note

This is **not** an agent-swarm task — it builds and emits today. The high-leverage spend is
*depth done right* (P8–P10 with snapshot tests proving the new wire-shape), not agent count.
One focused executor + the verification goal above is the correct shape.

## Cross-repo redundancy verdict (verified 2026-06-13, read-only across all 4 repos)

The recurring "is the conformance contract duplicated?" question — answered with evidence.

**There are two `conformance-plan.json` files, from two generators:**

| Plan | Generator | Subject (verified by reading the JSON) |
|---|---|---|
| `qyl-api-schema/generated/control-graph/conformance-plan.json` | TypeSpec `@qyl/telemetry-control-graph` | qyl's **own product services**: `qyl.collector`, `qyl.dashboard`. Richer: has `export_edges` + `recommended_attributes`. |
| `qyl-dotnet-autoinstrumentation/docs/qyl-aot-autoinstrumentation.conformance-plan.json` | Python `tools/generate-contract-artifacts.py` | the **.NET instrumentation coverage matrix**: 13 demo services (`qyl-db-aot-demo`, `qyl-grpc-aot-demo`, …). Leaner: `required_attributes` only. |

**Verdict: NOT data duplication.** Same wire contract (`schema_version "1"`), **disjoint subjects**
(product services vs instrumentation demos). Do **not** "consolidate the plans" — they describe
different things. A breadth-first map that flags "two conformance-plans = redundant" is wrong.

**The one REAL (small) redundancy = the plan SHAPE has no single schema.** The conformance-plan
wire shape is hand-reimplemented in **three** places that must agree by hand:
1. the TypeSpec emitter (emits the plan),
2. the Python generator (re-emits the same shape independently),
3. `qyl/internal/qyl.conformance/ConformancePlan.cs` (C# wire model — its own doc-comment says
   *"Wire model of conformance-plan.json as emitted by @qyl/telemetry-control-graph"*).

The C# `ConformanceVerifier.Verify(plan, observed)` is a **schema-agnostic diff engine** — it
consumes *either* plan. Good design. But the shape drift is **already visible**: the Python plan
lacks `export_edges` + `recommended_attributes` that the TypeSpec/C# side has.

**Fix (closes the only drift seam, low effort):** the emitter already emits
`control-graph.schema.json` for the *input* graph — emit a sibling **`conformance-plan.schema.json`**
the same way, then make the Python generator and a C# round-trip test **validate against that one
schema**. One schema artifact, three producers/consumers validate — instead of three hand-copies.
This is the SSOT, not merging the plans.

## Boundary (confirmed correct by the prior agent, restated)

The TypeSpec emitter lives **only** here in `qyl-api-schema`. Do **not** rebuild a second
`@qyl/telemetry-control-graph` in `qyl-dotnet-autoinstrumentation` — that repo has its own Python
contract generator (`tools/generate-contract-artifacts.py` →
`docs/qyl-aot-autoinstrumentation.conformance-plan.json`). Later, wire one to consume the other;
never duplicate.
