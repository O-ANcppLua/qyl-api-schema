// =============================================================================
// ANcpLua v2.0 - Workflow DAG Runtime Entities
// =============================================================================
// Workflow runs, nodes, checkpoints, shared state, events, routing rules.
// =============================================================================

import "@typespec/openapi";
import "../common/types.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;

namespace Qyl.Api.Contracts.Domains.Workflow;

// =============================================================================
// Workflow Run
// =============================================================================

@doc("Top-level workflow execution")
@extension("x-csharp-type", "WorkflowRunEntity")
model WorkflowRunEntity {
  @doc("Run ID")
  @key
  id: string;

  @doc("Workflow definition ID")
  @encodedName("application/json", "workflow_id")
  workflowId: string;

  @doc("Workflow definition version")
  @encodedName("application/json", "workflow_version")
  workflowVersion: int32;

  @doc("Owning project")
  @encodedName("application/json", "project_id")
  projectId: string;

  @doc("Trigger type")
  @encodedName("application/json", "trigger_type")
  triggerType: WorkflowTriggerType;

  @doc("Trigger source identifier")
  @encodedName("application/json", "trigger_source")
  triggerSource?: string;

  @doc("Run input data")
  @encodedName("application/json", "input_json")
  inputJson?: string;

  @doc("Run output data")
  @encodedName("application/json", "output_json")
  outputJson?: string;

  @doc("Run status")
  status: WorkflowRunStatus;

  @doc("Error message if failed")
  @encodedName("application/json", "error_message")
  errorMessage?: string;

  @doc("Parent run ID for sub-workflows")
  @encodedName("application/json", "parent_run_id")
  parentRunId?: string;

  @doc("Correlation ID for tracing")
  @encodedName("application/json", "correlation_id")
  correlationId?: string;

  @doc("Start timestamp")
  @encodedName("application/json", "started_at")
  startedAt?: utcDateTime;

  @doc("Completion timestamp")
  @encodedName("application/json", "completed_at")
  completedAt?: utcDateTime;

  @doc("Duration in milliseconds")
  @encodedName("application/json", "duration_ms")
  durationMs?: int32;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;
}

@doc("Workflow trigger types")
enum WorkflowTriggerType {
  @doc("Manual trigger")
  manual: "manual",

  @doc("Alert-triggered")
  alert: "alert",

  @doc("Schedule-triggered")
  schedule: "schedule",

  @doc("Event-triggered")
  event: "event",

  @doc("API-triggered")
  api: "api",

  @doc("MCP tool-triggered")
  mcp: "mcp",
}

@doc("Workflow run status")
enum WorkflowRunStatus {
  @doc("Pending start")
  pending: "pending",

  @doc("Currently running")
  running: "running",

  @doc("Paused/waiting for input")
  paused: "paused",

  @doc("Successfully completed")
  completed: "completed",

  @doc("Failed with error")
  failed: "failed",

  @doc("Cancelled")
  cancelled: "cancelled",

  @doc("Timed out")
  timedOut: "timed_out",
}

// =============================================================================
// Workflow Node
// =============================================================================

@doc("Individual DAG node execution")
@extension("x-csharp-type", "WorkflowNodeEntity")
model WorkflowNodeEntity {
  @doc("Execution ID")
  @key
  id: string;

  @doc("Parent run")
  @encodedName("application/json", "run_id")
  runId: string;

  @doc("Node definition ID")
  @encodedName("application/json", "node_id")
  nodeId: string;

  @doc("Node type")
  @encodedName("application/json", "node_type")
  nodeType: WorkflowNodeType;

  @doc("Node name")
  @encodedName("application/json", "node_name")
  nodeName: string;

  @doc("Attempt number (1-based)")
  attempt: int32;

  @doc("Node input data")
  @encodedName("application/json", "input_json")
  inputJson?: string;

  @doc("Node output data")
  @encodedName("application/json", "output_json")
  outputJson?: string;

  @doc("Node status")
  status: WorkflowRunStatus;

  @doc("Error message if failed")
  @encodedName("application/json", "error_message")
  errorMessage?: string;

  @doc("Retry count")
  @encodedName("application/json", "retry_count")
  retryCount: int32;

  @doc("Maximum retries allowed")
  @encodedName("application/json", "max_retries")
  maxRetries: int32;

  @doc("Timeout in milliseconds")
  @encodedName("application/json", "timeout_ms")
  timeoutMs?: int32;

  @doc("Start timestamp")
  @encodedName("application/json", "started_at")
  startedAt?: utcDateTime;

  @doc("Completion timestamp")
  @encodedName("application/json", "completed_at")
  completedAt?: utcDateTime;

  @doc("Duration in milliseconds")
  @encodedName("application/json", "duration_ms")
  durationMs?: int32;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;
}

@doc("Workflow node types")
enum WorkflowNodeType {
  @doc("AI agent invocation")
  agent: "agent",

  @doc("Tool/function call")
  tool: "tool",

  @doc("Conditional branch")
  condition: "condition",

  @doc("Parallel fork")
  fork: "fork",

  @doc("Join/barrier")
  join: "join",

  @doc("Human approval gate")
  approval: "approval",

  @doc("Sub-workflow invocation")
  subWorkflow: "sub_workflow",

  @doc("Transform/map node")
  transform: "transform",

  @doc("Wait/delay node")
  wait: "wait",
}

// =============================================================================
// Workflow Checkpoint
// =============================================================================

@doc("Durable node snapshot for crash recovery")
@extension("x-csharp-type", "WorkflowCheckpointEntity")
model WorkflowCheckpointEntity {
  @doc("Checkpoint ID")
  @key
  id: string;

  @doc("Parent run")
  @encodedName("application/json", "run_id")
  runId: string;

  @doc("Node that created the checkpoint")
  @encodedName("application/json", "node_id")
  nodeId: string;

  @doc("Checkpoint type")
  @encodedName("application/json", "checkpoint_type")
  checkpointType: string;

  @doc("Serialized state")
  @encodedName("application/json", "state_json")
  stateJson: string;

  @doc("Monotonic sequence number")
  @encodedName("application/json", "sequence_number")
  sequenceNumber: int64;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;
}

// =============================================================================
// Workflow Shared State
// =============================================================================

@doc("Cross-node versioned KV store per run")
@extension("x-csharp-type", "WorkflowSharedStateEntity")
model WorkflowSharedStateEntity {
  @doc("Run ID")
  @encodedName("application/json", "run_id")
  runId: string;

  @doc("State key")
  key: string;

  @doc("State value")
  @encodedName("application/json", "value_json")
  valueJson: string;

  @doc("Optimistic concurrency version")
  version: int32;

  @doc("Last updater")
  @encodedName("application/json", "updated_by")
  updatedBy?: string;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;

  @doc("Last update timestamp")
  @encodedName("application/json", "updated_at")
  updatedAt: utcDateTime;
}

// =============================================================================
// Workflow Event
// =============================================================================

@doc("Append-only workflow event")
@extension("x-csharp-type", "WorkflowEventEntity")
model WorkflowEventEntity {
  @doc("Event ID")
  @key
  id: string;

  @doc("Parent run")
  @encodedName("application/json", "run_id")
  runId: string;

  @doc("Source node (null for run-level events)")
  @encodedName("application/json", "node_id")
  nodeId?: string;

  @doc("Event type")
  @encodedName("application/json", "event_type")
  eventType: string;

  @doc("Event name")
  @encodedName("application/json", "event_name")
  eventName: string;

  @doc("Event payload")
  @encodedName("application/json", "payload_json")
  payloadJson?: string;

  @doc("Monotonic sequence number")
  @encodedName("application/json", "sequence_number")
  sequenceNumber: int64;

  @doc("Event source identifier")
  source?: string;

  @doc("Correlation ID")
  @encodedName("application/json", "correlation_id")
  correlationId?: string;

  @doc("Event timestamp")
  timestamp: utcDateTime;
}

// =============================================================================
// Workflow Routing Rule
// =============================================================================

@doc("DAG conditional branch predicate")
@extension("x-csharp-type", "WorkflowRoutingRuleEntity")
model WorkflowRoutingRuleEntity {
  @doc("Rule ID")
  @key
  id: string;

  @doc("Workflow definition")
  @encodedName("application/json", "workflow_id")
  workflowId: string;

  @doc("Source node")
  @encodedName("application/json", "source_node_id")
  sourceNodeId: string;

  @doc("Target node")
  @encodedName("application/json", "target_node_id")
  targetNodeId: string;

  @doc("Condition type")
  @encodedName("application/json", "condition_type")
  conditionType: string;

  @doc("Condition expression")
  @encodedName("application/json", "condition_expression")
  conditionExpression: string;

  @doc("Evaluation priority (higher first)")
  priority: int32;

  @doc("Whether this is the default/fallback route")
  @encodedName("application/json", "is_default")
  isDefault: boolean;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;

  @doc("Last update timestamp")
  @encodedName("application/json", "updated_at")
  updatedAt: utcDateTime;
}
