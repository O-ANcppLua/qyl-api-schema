// =============================================================================
// ANcpLua v2.0 - Agent Run Contract Model (OTel v1.40)
// =============================================================================
// Agent run records extracted from OTLP spans.
// Maps OTel GenAI semantic convention attributes to qyl API contract fields.
//
// OTel semconv mapping:
//   gen_ai.agent.name        → agent_name
//   gen_ai.agent.id          → agent_id
//   gen_ai.agent.description → agent_description
//   gen_ai.operation.name    → operation_name
//   gen_ai.request.model     → gen_ai_request_model
//   gen_ai.provider.name     → gen_ai_provider_name
//   gen_ai.usage.input_tokens  → gen_ai_input_tokens
//   gen_ai.usage.output_tokens → gen_ai_output_tokens
// =============================================================================

import "@typespec/openapi";
import "../../common/types.tsp";
import "../../otel/enums.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;
using Qyl.Api.Contracts.OTel.Enums;

namespace Qyl.Api.Contracts.Domains.Agent.Run;

// =============================================================================
// Agent Run Status
// =============================================================================

@doc("Agent run execution status")
enum AgentRunStatus {
  @doc("Agent is currently executing")
  running: "running",

  @doc("Agent completed successfully")
  completed: "completed",

  @doc("Agent execution failed")
  failed: "failed",

  @doc("Agent execution was cancelled")
  cancelled: "cancelled",
}

// =============================================================================
// Agent Run Entity
// =============================================================================

@doc("Agent run entity materialized from OTLP spans with gen_ai.agent.* attributes")
@TypeSpec.OpenAPI.extension("x-csharp-type", "AgentRunEntity")
model AgentRunEntity {
  // === Identifiers ===

  @doc("Unique agent run identifier")
  @key
  runId: string;

  @doc("Parent OTel trace identifier")
  traceId: TraceId;

  @doc("Root span ID of the agent invocation")
  spanId?: SpanId;

  @doc("Parent run ID for nested agent invocations")
  parentRunId?: string;

  @doc("Session identifier for grouping related runs")
  sessionId?: SessionId;

  // === Agent Identity (OTel gen_ai.agent.*) ===

  @doc("Agent name - OTel: gen_ai.agent.name")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  agentName: string;

  @doc("Agent identifier - OTel: gen_ai.agent.id")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  agentId?: string;

  @doc("Agent description - OTel: gen_ai.agent.description")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  agentDescription?: string;

  // === GenAI Attributes (OTel gen_ai.*) ===

  @doc("Operation name - OTel: gen_ai.operation.name")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  operationName?: string;

  @doc("LLM model used - OTel: gen_ai.request.model")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  genAiRequestModel?: string;

  @doc("Provider name - OTel: gen_ai.provider.name")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  genAiProviderName?: string;

  // === Execution State ===

  @doc("Execution status")
  status: AgentRunStatus;

  // === Token Usage (OTel gen_ai.usage.*) ===

  @doc("Input/prompt tokens - OTel: gen_ai.usage.input_tokens")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  genAiInputTokens?: TokenCount;

  @doc("Output/completion tokens - OTel: gen_ai.usage.output_tokens")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  genAiOutputTokens?: TokenCount;

  @doc("Estimated cost in USD")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  genAiCostUsd?: CostUsd;

  @doc("Number of tool calls made")
  toolCallCount?: int32;

  // === Timing ===

  @doc("Start timestamp in nanoseconds since epoch")
  startTimeUnixNano: UnixNanos;

  @doc("End timestamp in nanoseconds since epoch")
  endTimeUnixNano?: UnixNanos;

  @doc("Duration in nanoseconds")
  durationNs?: DurationNs;

  // === Service Info ===

  @doc("Service name from resource attributes")
  @TypeSpec.OpenAPI.extension("x-promoted", true)
  serviceName?: string;

  // === Error ===

  @doc("Error message if failed")
  errorMessage?: string;

  // === Attributes (JSON Blobs) ===

  @doc("Additional attributes as JSON")
  attributesJson?: string;

  // === Internal ===

  @doc("Row creation timestamp")
  @TypeSpec.OpenAPI.extension("x-internal", true)
  createdAt?: utcDateTime;
}
