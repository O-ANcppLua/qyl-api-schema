// =============================================================================
// ANcpLua v2.0 - Error Issue Engine Entities
// =============================================================================
// Issue aggregates, events, breadcrumbs, regressions, ownership, releases.
// Sentry-replacement error tracking engine.
// =============================================================================

import "@typespec/openapi";
import "../common/types.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;

namespace Qyl.Api.Contracts.Domains.Issues;

// =============================================================================
// Error Issue
// =============================================================================

@doc("Error issue aggregate with lifecycle tracking")
@extension("x-csharp-type", "ErrorIssueEntity")
model ErrorIssueEntity {
  @doc("Issue ID")
  @key
  @visibility(Lifecycle.Read)
  id: string;

  @doc("Owning project")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "project_id")
  projectId: string;

  @doc("Error fingerprint for grouping")
  @visibility(Lifecycle.Read)
  fingerprint: string;

  @doc("Issue title")
  @visibility(Lifecycle.Read)
  title: string;

  @doc("Culprit (function/module causing the error)")
  @visibility(Lifecycle.Read)
  culprit?: string;

  @doc("Error type (exception class name or code)")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "error_type")
  errorType: string;

  @doc("Error category")
  @visibility(Lifecycle.Read)
  category: string;

  @doc("Severity level")
  @visibility(Lifecycle.Read)
  level: IssueLevel;

  @doc("Platform (csharp, javascript, python, etc.)")
  @visibility(Lifecycle.Read)
  platform?: string;

  @doc("First occurrence")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "first_seen_at")
  firstSeenAt: utcDateTime;

  @doc("Last occurrence")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "last_seen_at")
  lastSeenAt: utcDateTime;

  @doc("Total occurrence count")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "occurrence_count")
  occurrenceCount: int64;

  @doc("Affected unique users count")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "affected_users_count")
  affectedUsersCount: int32;

  @doc("Issue status")
  @visibility(Lifecycle.Read, Lifecycle.Update)
  status: IssueStatus;

  @doc("Issue substatus")
  @visibility(Lifecycle.Read)
  substatus?: string;

  @doc("Priority level")
  @visibility(Lifecycle.Read, Lifecycle.Update)
  priority: IssuePriority;

  @doc("Assigned team member")
  @visibility(Lifecycle.Read, Lifecycle.Update)
  @encodedName("application/json", "assigned_to")
  assignedTo?: string;

  @doc("Resolution timestamp")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "resolved_at")
  resolvedAt?: utcDateTime;

  @doc("Resolved by")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "resolved_by")
  resolvedBy?: string;

  @doc("Number of regressions")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "regression_count")
  regressionCount: int32;

  @doc("Last associated release")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "last_release")
  lastRelease?: string;

  @doc("Issue tags")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "tags_json")
  tagsJson?: string;

  @doc("Issue metadata")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "metadata_json")
  metadataJson?: string;

  @doc("Creation timestamp")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;

  @doc("Last update timestamp")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "updated_at")
  updatedAt: utcDateTime;
}

@doc("Issue severity level")
enum IssueLevel {
  @doc("Debug level")
  debug: "debug",

  @doc("Info level")
  info: "info",

  @doc("Warning level")
  warning: "warning",

  @doc("Error level")
  error: "error",

  @doc("Fatal/critical level")
  fatal: "fatal",
}

@doc("Issue lifecycle status")
enum IssueStatus {
  @doc("Unresolved/new")
  unresolved: "unresolved",

  @doc("Acknowledged by team")
  acknowledged: "acknowledged",

  @doc("Being investigated")
  investigating: "investigating",

  @doc("Fix in progress")
  inProgress: "in_progress",

  @doc("Resolved")
  resolved: "resolved",

  @doc("Ignored")
  ignored: "ignored",

  @doc("Regressed after resolution")
  regressed: "regressed",
}

@doc("Issue priority")
enum IssuePriority {
  @doc("Critical priority")
  critical: "critical",

  @doc("High priority")
  high: "high",

  @doc("Medium priority")
  medium: "medium",

  @doc("Low priority")
  low: "low",
}

// =============================================================================
// Error Issue Event
// =============================================================================

@doc("Individual error occurrence linked to an issue")
@extension("x-csharp-type", "ErrorIssueEventEntity")
model ErrorIssueEventEntity {
  @doc("Event ID")
  @key
  id: string;

  @doc("Parent issue")
  @encodedName("application/json", "issue_id")
  issueId: string;

  @doc("Associated trace ID")
  @encodedName("application/json", "trace_id")
  traceId?: string;

  @doc("Associated span ID")
  @encodedName("application/json", "span_id")
  spanId?: string;

  @doc("Error message")
  message?: string;

  @doc("Stack trace")
  @encodedName("application/json", "stack_trace")
  stackTrace?: string;

  @doc("Parsed stack frames")
  @encodedName("application/json", "stack_frames_json")
  stackFramesJson?: string;

  @doc("Environment (dev, staging, prod)")
  environment?: string;

  @doc("Release version")
  @encodedName("application/json", "release_version")
  releaseVersion?: string;

  @doc("Affected user ID")
  @encodedName("application/json", "user_id")
  userId?: string;

  @doc("Client IP address")
  @encodedName("application/json", "user_ip")
  userIp?: string;

  @doc("Request URL")
  @encodedName("application/json", "request_url")
  requestUrl?: string;

  @doc("HTTP request method")
  @encodedName("application/json", "request_method")
  requestMethod?: string;

  @doc("Browser info")
  browser?: string;

  @doc("Operating system")
  os?: string;

  @doc("Device info")
  device?: string;

  @doc("Runtime name")
  runtime?: string;

  @doc("Runtime version")
  @encodedName("application/json", "runtime_version")
  runtimeVersion?: string;

  @doc("Additional context data")
  @encodedName("application/json", "context_json")
  contextJson?: string;

  @doc("Event tags")
  @encodedName("application/json", "tags_json")
  tagsJson?: string;

  @doc("Event timestamp")
  timestamp: utcDateTime;
}

// =============================================================================
// Error Breadcrumb
// =============================================================================

@doc("Pre-error context breadcrumb")
@extension("x-csharp-type", "ErrorBreadcrumbEntity")
model ErrorBreadcrumbEntity {
  @doc("Breadcrumb ID")
  @key
  id: string;

  @doc("Parent event")
  @encodedName("application/json", "event_id")
  eventId: string;

  @doc("Breadcrumb type")
  @encodedName("application/json", "breadcrumb_type")
  breadcrumbType: BreadcrumbType;

  @doc("Category (e.g. http, db, ui)")
  category?: string;

  @doc("Breadcrumb message")
  message?: string;

  @doc("Severity level")
  level: string;

  @doc("Breadcrumb data")
  @encodedName("application/json", "data_json")
  dataJson?: string;

  @doc("Breadcrumb timestamp")
  timestamp: utcDateTime;
}

@doc("Breadcrumb types")
enum BreadcrumbType {
  @doc("Navigation event")
  navigation: "navigation",

  @doc("HTTP request")
  http: "http",

  @doc("Database query")
  query: "query",

  @doc("User interaction")
  user: "user",

  @doc("Log message")
  log: "log",

  @doc("Error occurrence")
  error: "error",

  @doc("Debug information")
  debug: "debug",

  @doc("Default/other")
  default: "default",
}

// =============================================================================
// Error Regression
// =============================================================================

@doc("Regression window across releases")
@extension("x-csharp-type", "ErrorRegressionEntity")
model ErrorRegressionEntity {
  @doc("Regression ID")
  @key
  id: string;

  @doc("Regressed issue")
  @encodedName("application/json", "issue_id")
  issueId: string;

  @doc("Release where issue was resolved")
  @encodedName("application/json", "resolved_in_release")
  resolvedInRelease: string;

  @doc("Release where issue regressed")
  @encodedName("application/json", "regressed_in_release")
  regressedInRelease: string;

  @doc("Resolution timestamp")
  @encodedName("application/json", "resolved_at")
  resolvedAt: utcDateTime;

  @doc("Regression timestamp")
  @encodedName("application/json", "regressed_at")
  regressedAt: utcDateTime;

  @doc("Occurrences before regression")
  @encodedName("application/json", "occurrence_count_before")
  occurrenceCountBefore: int32;

  @doc("Occurrences after regression")
  @encodedName("application/json", "occurrence_count_after")
  occurrenceCountAfter: int32;

  @doc("Whether auto-detected")
  @encodedName("application/json", "auto_detected")
  autoDetected: boolean;

  @doc("Detection timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;
}

// =============================================================================
// Error Ownership
// =============================================================================

@doc("Code ownership rule for auto-triage")
@extension("x-csharp-type", "ErrorOwnershipEntity")
model ErrorOwnershipEntity {
  @doc("Rule ID")
  @key
  id: string;

  @doc("Owning project")
  @encodedName("application/json", "project_id")
  projectId: string;

  @doc("Rule type (path, tag, url, module)")
  @encodedName("application/json", "rule_type")
  ruleType: string;

  @doc("Match pattern (glob, regex, or exact)")
  pattern: string;

  @doc("Owner type (user, team)")
  @encodedName("application/json", "owner_type")
  ownerType: string;

  @doc("Owner identifier")
  @encodedName("application/json", "owner_id")
  ownerId: string;

  @doc("Rule priority (higher wins)")
  priority: int32;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;

  @doc("Last update timestamp")
  @encodedName("application/json", "updated_at")
  updatedAt: utcDateTime;
}

// =============================================================================
// Error Release Marker
// =============================================================================

@doc("Deploy marker for issue auto-transition")
@extension("x-csharp-type", "ErrorReleaseMarkerEntity")
model ErrorReleaseMarkerEntity {
  @doc("Marker ID")
  @key
  id: string;

  @doc("Owning project")
  @encodedName("application/json", "project_id")
  projectId: string;

  @doc("Release version")
  @encodedName("application/json", "release_version")
  releaseVersion: string;

  @doc("Target environment")
  environment: string;

  @doc("Git commit SHA")
  @encodedName("application/json", "commit_sha")
  commitSha?: string;

  @doc("Commit message")
  @encodedName("application/json", "commit_message")
  commitMessage?: string;

  @doc("Deployed by")
  @encodedName("application/json", "deployed_by")
  deployedBy?: string;

  @doc("Issues resolved by this release")
  @encodedName("application/json", "issues_resolved_count")
  issuesResolvedCount: int32;

  @doc("Issues regressed by this release")
  @encodedName("application/json", "issues_regressed_count")
  issuesRegressedCount: int32;

  @doc("Deployment timestamp")
  @encodedName("application/json", "deployed_at")
  deployedAt: utcDateTime;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;
}
