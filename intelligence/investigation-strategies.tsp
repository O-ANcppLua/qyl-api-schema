// =============================================================================
// ANcpLua v2.0 - Investigation Strategies
// =============================================================================
// A deterministic sequence of steps to investigate a matched pattern.
// The LLM does not invent investigation paths — it selects from known
// strategies and interprets results.
// =============================================================================

import "@typespec/openapi";

using TypeSpec.OpenAPI;

namespace Qyl.Api.Contracts.Intelligence;

@doc("Single step in an investigation strategy")
model InvestigationStep {
  @doc("What to do (e.g. query_traces, get_code_location, compare_deployments)")
  action: string;

  @doc("Query template or tool name")
  query: string;

  @doc("Human-readable explanation of this step")
  description: string;
}

@doc("Deterministic investigation sequence triggered by a matched pattern")
model InvestigationStrategy {
  @doc("Unique strategy identifier")
  id: string;

  @doc("Trigger — pattern ID or category:X for category-wide triggers")
  triggerPattern: string;

  @doc("Ordered investigation steps")
  steps: InvestigationStep[];
}
