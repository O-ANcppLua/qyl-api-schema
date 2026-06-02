// =============================================================================
// ANcpLua v2.0 - Alerting & Autofix Entities
// =============================================================================
// Alert rules, firings, fix runs, artifacts, policy gates.
// =============================================================================

import "@typespec/openapi";
import "../common/types.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;

namespace Qyl.Api.Contracts.Domains.Alerting;

// =============================================================================
// Alert Rule
// =============================================================================

@doc("Alert rule definition")
@extension("x-csharp-type", "AlertRuleEntity")
model AlertRuleEntity {
  @doc("Rule ID")
  @key
  id: string;

  @doc("Owning project")
  @encodedName("application/json", "project_id")
  projectId: string;

  @doc("Rule name")
  name: string;

  @doc("Rule description")
  description?: string;

  @doc("Rule type")
  @encodedName("application/json", "rule_type")
  ruleType: AlertRuleType;

  @doc("Condition definition")
  @encodedName("application/json", "condition_json")
  conditionJson: string;

  @doc("Threshold definition")
  @encodedName("application/json", "threshold_json")
  thresholdJson?: string;

  @doc("Target type for evaluation")
  @encodedName("application/json", "target_type")
  targetType: string;

  @doc("Target filter")
  @encodedName("application/json", "target_filter_json")
  targetFilterJson?: string;

  @doc("Alert severity")
  severity: AlertSeverity;

  @doc("Cooldown between firings in seconds")
  @encodedName("application/json", "cooldown_seconds")
  cooldownSeconds: int32;

  @doc("Notification channels")
  @encodedName("application/json", "notification_channels_json")
  notificationChannelsJson?: string;

  @doc("Whether rule is enabled")
  enabled: boolean;

  @doc("Last trigger timestamp")
  @encodedName("application/json", "last_triggered_at")
  lastTriggeredAt?: utcDateTime;

  @doc("Total trigger count")
  @encodedName("application/json", "trigger_count")
  triggerCount: int64;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;

  @doc("Last update timestamp")
  @encodedName("application/json", "updated_at")
  updatedAt: utcDateTime;
}

@doc("Alert rule types")
enum AlertRuleType {
  @doc("Metric threshold alert")
  threshold: "threshold",

  @doc("Error rate alert")
  errorRate: "error_rate",

  @doc("New issue alert")
  newIssue: "new_issue",

  @doc("Regression alert")
  regression: "regression",

  @doc("SLO burn rate alert")
  burnRate: "burn_rate",

  @doc("Anomaly detection alert")
  anomaly: "anomaly",

  @doc("Custom query alert")
  custom: "custom",
}

@doc("Alert severity levels")
enum AlertSeverity {
  @doc("Critical alert")
  critical: "critical",

  @doc("Warning alert")
  warning: "warning",

  @doc("Informational alert")
  info: "info",
}

// =============================================================================
// Alert Firing
// =============================================================================

@doc("Triggered alert instance")
@extension("x-csharp-type", "AlertFiringEntity")
model AlertFiringEntity {
  @doc("Firing ID")
  @key
  id: string;

  @doc("Source rule")
  @encodedName("application/json", "rule_id")
  ruleId: string;

  @doc("Dedup fingerprint")
  fingerprint: string;

  @doc("Alert severity")
  severity: AlertSeverity;

  @doc("Alert title")
  title: string;

  @doc("Alert message")
  message?: string;

  @doc("Measured value that triggered the alert")
  @encodedName("application/json", "trigger_value")
  triggerValue?: float64;

  @doc("Threshold value")
  @encodedName("application/json", "threshold_value")
  thresholdValue?: float64;

  @doc("Additional context")
  @encodedName("application/json", "context_json")
  contextJson?: string;

  @doc("Firing status")
  status: AlertFiringStatus;

  @doc("Acknowledgment timestamp")
  @encodedName("application/json", "acknowledged_at")
  acknowledgedAt?: utcDateTime;

  @doc("Acknowledged by")
  @encodedName("application/json", "acknowledged_by")
  acknowledgedBy?: string;

  @doc("Resolution timestamp")
  @encodedName("application/json", "resolved_at")
  resolvedAt?: utcDateTime;

  @doc("Firing timestamp")
  @encodedName("application/json", "fired_at")
  firedAt: utcDateTime;

  @doc("Dedup key for suppressing duplicates")
  @encodedName("application/json", "dedup_key")
  dedupKey?: string;
}

@doc("Alert firing status")
enum AlertFiringStatus {
  @doc("Currently firing")
  firing: "firing",

  @doc("Acknowledged by operator")
  acknowledged: "acknowledged",

  @doc("Resolved (condition cleared)")
  resolved: "resolved",

  @doc("Suppressed by cooldown")
  suppressed: "suppressed",
}

// =============================================================================
// Fix Run
// =============================================================================

@doc("AI-assisted fix attempt")
@extension("x-csharp-type", "FixRunEntity")
model FixRunEntity {
  @doc("Fix run ID")
  @key
  id: string;

  @doc("Target issue")
  @encodedName("application/json", "issue_id")
  issueId: string;

  @doc("Triggering alert firing")
  @encodedName("application/json", "alert_firing_id")
  alertFiringId?: string;

  @doc("What triggered the fix")
  @encodedName("application/json", "trigger_type")
  triggerType: FixTriggerType;

  @doc("Fix strategy")
  strategy: string;

  @doc("AI model used")
  @encodedName("application/json", "model_name")
  modelName?: string;

  @doc("AI provider")
  @encodedName("application/json", "model_provider")
  modelProvider?: string;

  @doc("Fix run status")
  status: FixRunStatus;

  @doc("Error message if failed")
  @encodedName("application/json", "error_message")
  errorMessage?: string;

  @doc("Tokens consumed")
  @encodedName("application/json", "tokens_used")
  tokensUsed?: int32;

  @doc("Duration in milliseconds")
  @encodedName("application/json", "duration_ms")
  durationMs?: int32;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;

  @doc("Start timestamp")
  @encodedName("application/json", "started_at")
  startedAt?: utcDateTime;

  @doc("Completion timestamp")
  @encodedName("application/json", "completed_at")
  completedAt?: utcDateTime;
}

@doc("Fix trigger types")
enum FixTriggerType {
  @doc("Triggered by alert")
  alert: "alert",

  @doc("Triggered manually")
  manual: "manual",

  @doc("Triggered by MCP tool")
  mcp: "mcp",

  @doc("Triggered by schedule")
  scheduled: "scheduled",
}

@doc("Fix run status")
enum FixRunStatus {
  @doc("Pending execution")
  pending: "pending",

  @doc("Running")
  running: "running",

  @doc("Awaiting approval")
  awaitingApproval: "awaiting_approval",

  @doc("Approved and applied")
  applied: "applied",

  @doc("Rejected")
  rejected: "rejected",

  @doc("Failed")
  failed: "failed",
}

// =============================================================================
// Fix Artifact
// =============================================================================

@doc("Fix run output artifact")
@extension("x-csharp-type", "FixArtifactEntity")
model FixArtifactEntity {
  @doc("Artifact ID")
  @key
  id: string;

  @doc("Parent fix run")
  @encodedName("application/json", "fix_run_id")
  fixRunId: string;

  @doc("Artifact type")
  @encodedName("application/json", "artifact_type")
  artifactType: FixArtifactType;

  @doc("Artifact name")
  name: string;

  @doc("Content MIME type")
  @encodedName("application/json", "content_type")
  contentType: string;

  @doc("Artifact content")
  content?: string;

  @doc("Content hash for dedup")
  @encodedName("application/json", "content_hash")
  contentHash?: string;

  @doc("Size in bytes")
  @encodedName("application/json", "size_bytes")
  sizeBytes?: int64;

  @doc("Artifact metadata")
  @encodedName("application/json", "metadata_json")
  metadataJson?: string;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;
}

@doc("Fix artifact types")
enum FixArtifactType {
  @doc("Code patch (diff)")
  patch: "patch",

  @doc("Execution log")
  log: "log",

  @doc("Analysis report")
  report: "report",

  @doc("Prompt used for AI")
  prompt: "prompt",

  @doc("AI model response")
  response: "response",

  @doc("Test results")
  testResults: "test_results",
}

// =============================================================================
// Fix Policy Gate
// =============================================================================

@doc("Autofix policy gate decision")
@extension("x-csharp-type", "FixPolicyGateEntity")
model FixPolicyGateEntity {
  @doc("Gate ID")
  @key
  id: string;

  @doc("Parent fix run")
  @encodedName("application/json", "fix_run_id")
  fixRunId: string;

  @doc("Gate type")
  @encodedName("application/json", "gate_type")
  gateType: PolicyGateType;

  @doc("Gate name")
  @encodedName("application/json", "gate_name")
  gateName: string;

  @doc("Decision")
  decision: GateDecision;

  @doc("Decision reason")
  reason?: string;

  @doc("Gate input data")
  @encodedName("application/json", "input_json")
  inputJson?: string;

  @doc("Gate output data")
  @encodedName("application/json", "output_json")
  outputJson?: string;

  @doc("Evaluation timestamp")
  @encodedName("application/json", "evaluated_at")
  evaluatedAt: utcDateTime;
}

@doc("Policy gate types")
enum PolicyGateType {
  @doc("Scope check (allowed files/directories)")
  scope: "scope",

  @doc("Safety check (no destructive changes)")
  safety: "safety",

  @doc("Test gate (tests must pass)")
  test: "test",

  @doc("Review gate (human approval)")
  review: "review",

  @doc("Budget gate (token/cost limit)")
  budget: "budget",
}

@doc("Gate decision outcomes")
enum GateDecision {
  @doc("Gate passed")
  allow: "allow",

  @doc("Gate blocked the fix")
  deny: "deny",

  @doc("Gate deferred to human")
  defer: "defer",
}
