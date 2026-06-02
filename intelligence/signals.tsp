// =============================================================================
// ANcpLua v2.0 - Signal Primitive
// =============================================================================
// The atomic unit of telemetry observation. A single attribute condition.
// Signals reference semconv attributes and qyl-derived attributes only.
// =============================================================================

import "@typespec/openapi";

using TypeSpec.OpenAPI;

namespace Qyl.Api.Contracts.Intelligence;

@doc("Comparison operator for signal evaluation")
enum SignalOperator {
  @doc("Equals")
  eq: "eq",

  @doc("Not equals")
  neq: "neq",

  @doc("Greater than")
  gt: "gt",

  @doc("Greater than or equal")
  gte: "gte",

  @doc("Less than")
  lt: "lt",

  @doc("Less than or equal")
  lte: "lte",

  @doc("String contains")
  contains: "contains",

  @doc("Attribute is non-null")
  exists: "exists",

  @doc("Attribute is null")
  not_exists: "not_exists",

  @doc("Regex match")
  matches: "matches",

  @doc("Value in set (comma-separated)")
  in_set: "in",
}

@doc("Atomic telemetry observation — a single attribute condition")
model Signal {
  @doc("Telemetry attribute name (semconv or promoted column)")
  attribute: string;

  @doc("Comparison operator")
  operator: SignalOperator;

  @doc("Expected value (type-coerced at evaluation time). Omit for exists/not_exists.")
  value?: string;
}
