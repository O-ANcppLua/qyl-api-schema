// =============================================================================
// ANcpLua v2.0 - Tool Call Contract Model (OTel v1.40)
// =============================================================================
// Tool call records extracted from OTLP spans.
// Maps OTel GenAI tool semantic convention attributes to qyl API contract fields.
//
// OTel semconv mapping:
//   gen_ai.tool.name           → tool_name
//   gen_ai.tool.type           → tool_type
//   gen_ai.tool.call.id        → call_id
//   gen_ai.tool.call.arguments → arguments_json
//   gen_ai.tool.call.result    → result_json
//   gen_ai.tool.description    → tool_description
//   gen_ai.operation.name      → operation_name (= "execute_tool")
// =============================================================================

import "@typespec/openapi";
import "../../common/types.tsp";
import "../../otel/enums.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;
using Qyl.Api.Contracts.OTel.Enums;

namespace Qyl.Api.Contracts.Domains.Agent.ToolCall;

// =============================================================================
// Tool Call Status
// =============================================================================

@doc("Tool call execution status")
enum ToolCallStatus {
  @doc("Tool is currently executing")
  running: "running",

  @doc("Tool completed successfully")
  completed: "completed",

  @doc("Tool execution failed")
  failed: "failed",
}

// =============================================================================
// Tool Call Entity
// =============================================================================

@doc("Tool call entity materialized from OTLP spans with gen_ai.tool.* attributes")
@TypeSpec.OpenAPI.extension("x-csharp-type", "ToolCallEntity")
model ToolCallEntity {
  // === Identifiers ===

  @doc("Unique tool call identifier - OTel: gen_ai.tool.call.id")
  @key
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  callId: string;

  @doc("Parent agent run identifier")
  runId: string;

  @doc("Parent OTel trace identifier")
  traceId: TraceId;

  @doc("Associated OTel span identifier")
  spanId: SpanId;

  // === Tool Identity (OTel gen_ai.tool.*) ===

  @doc("Tool name - OTel: gen_ai.tool.name (e.g., 'Read', 'Bash', 'Edit', 'TodoWrite')")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  toolName: string;

  @doc("Tool type categorization - OTel: gen_ai.tool.type (e.g., 'function', 'extension')")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  toolType?: string;

  @doc("Tool description - OTel: gen_ai.tool.description")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  toolDescription?: string;

  // === Tool Call Data (OTel gen_ai.tool.call.*) ===

  @doc("Tool input arguments as JSON - OTel: gen_ai.tool.call.arguments")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  argumentsJson?: string;

  @doc("Tool output result as JSON - OTel: gen_ai.tool.call.result")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  resultJson?: string;

  // === Execution State ===

  @doc("Execution status")
  status: ToolCallStatus;

  // === Timing ===

  @doc("Tool call start time in nanoseconds since epoch")
  startTimeUnixNano: UnixNanos;

  @doc("Tool call end time in nanoseconds since epoch")
  endTimeUnixNano?: UnixNanos;

  @doc("Duration in nanoseconds")
  durationNs?: DurationNs;

  // === Error ===

  @doc("Error message if failed")
  errorMessage?: string;

  // === Ordering ===

  @doc("Execution order within the agent run")
  @minValue(0)
  sequenceNumber: int32;

  // === Internal ===

  @doc("Row creation timestamp")
  @TypeSpec.OpenAPI.extension("x-internal", true)
  createdAt?: utcDateTime;
}
