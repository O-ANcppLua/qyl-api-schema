// =============================================================================
// ANcpLua v2.0 - Workflow Execution Contract Model (OTel v1.40)
// =============================================================================
// Workflow execution tracking for multi-step AI agent workflows.
// Defines the public qyl workflow execution contract.
// =============================================================================

import "@typespec/openapi";
import "../../common/types.tsp";
import "../../otel/enums.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;
using Qyl.Api.Contracts.OTel.Enums;

namespace Qyl.Api.Contracts.Domains.Agent.Workflow;

// =============================================================================
// Workflow Execution Status
// =============================================================================

@doc("Workflow execution status")
enum WorkflowExecutionStatus {
  @doc("Workflow is pending execution")
  pending: "pending",

  @doc("Workflow is currently running")
  running: "running",

  @doc("Workflow completed successfully")
  completed: "completed",

  @doc("Workflow execution failed")
  failed: "failed",

  @doc("Workflow execution was cancelled")
  cancelled: "cancelled",
}

// =============================================================================
// Workflow Trigger Type
// =============================================================================

@doc("What triggered a workflow execution")
enum WorkflowTrigger {
  @doc("Manually triggered by user or agent")
  manual: "manual",

  @doc("Triggered by schedule/cron")
  schedule: "schedule",

  @doc("Triggered by event (e.g., error, alert)")
  event: "event",

  @doc("Triggered by another workflow")
  workflow: "workflow",
}

// =============================================================================
// Workflow Execution Entity
// =============================================================================

@doc("Workflow execution entity for tracking multi-step agent workflows")
@TypeSpec.OpenAPI.extension("x-csharp-type", "WorkflowExecutionEntity")
model WorkflowExecutionEntity {
  // === Identifiers ===

  @doc("Unique execution identifier")
  @key
  executionId: string;

  @doc("Associated OTel trace identifier")
  traceId?: TraceId;

  // === Workflow Identity ===

  @doc("Workflow name identifier")
  workflowName: string;

  @doc("What triggered the workflow")
  trigger: WorkflowTrigger;

  // === Execution State ===

  @doc("Execution status")
  status: WorkflowExecutionStatus;

  // === I/O ===

  @doc("Workflow input as JSON")
  inputJson?: string;

  @doc("Workflow output as JSON")
  outputJson?: string;

  // === Token Usage (OTel gen_ai.usage.*) ===

  @doc("Total input tokens - OTel: gen_ai.usage.input_tokens")
  genAiInputTokens?: TokenCount;

  @doc("Total output tokens - OTel: gen_ai.usage.output_tokens")
  genAiOutputTokens?: TokenCount;

  @doc("Estimated cost in USD")
  genAiCostUsd?: CostUsd;

  // === Progress ===

  @doc("Total number of workflow nodes")
  nodeCount?: int32;

  @doc("Number of completed nodes")
  completedNodes?: int32;

  // === Timing ===

  @doc("Start timestamp in nanoseconds since epoch")
  startTimeUnixNano: UnixNanos;

  @doc("End timestamp in nanoseconds since epoch")
  endTimeUnixNano?: UnixNanos;

  @doc("Duration in nanoseconds")
  durationNs?: DurationNs;

  // === Error ===

  @doc("Error message if failed")
  errorMessage?: string;

  // === Internal ===

  @doc("Row creation timestamp")
  @TypeSpec.OpenAPI.extension("x-internal", true)
  createdAt?: utcDateTime;
}
