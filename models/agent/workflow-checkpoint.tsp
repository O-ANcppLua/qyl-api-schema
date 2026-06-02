// =============================================================================
// ANcpLua v2.0 - Workflow Checkpoint Contract Model (OTel v1.40)
// =============================================================================
// Checkpoint state persistence for workflow execution recovery.
// Enables resume-from-checkpoint after failures or cancellations.
// =============================================================================

import "@typespec/openapi";
import "../../common/types.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;

namespace Qyl.Api.Contracts.Domains.Agent.Checkpoint;

// =============================================================================
// Workflow Checkpoint Entity
// =============================================================================

@doc("Workflow checkpoint entity for persisting workflow node state for recovery")
@TypeSpec.OpenAPI.extension("x-csharp-type", "WorkflowCheckpointEntity")
model WorkflowCheckpointEntity {
  // === Identifiers ===

  @doc("Unique checkpoint identifier")
  @key
  checkpointId: string;

  @doc("Parent workflow execution identifier")
  executionId: string;

  // === Node State ===

  @doc("Workflow node identifier")
  nodeId: string;

  @doc("Serialized node state as JSON")
  stateJson: string;

  // === Ordering ===

  @doc("Checkpoint sequence number within the execution")
  @minValue(0)
  sequenceNumber: int32;

  // === Timing ===

  @doc("Checkpoint creation time in nanoseconds since epoch")
  createdAtUnixNano: UnixNanos;
}
