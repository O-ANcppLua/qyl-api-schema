// =============================================================================
// ANcpLua v2.0 - Error Semantic Conventions (OTel v1.40)
// =============================================================================
// Error type and error handling telemetry attributes.
// =============================================================================

import "@typespec/openapi";
import "../common/types.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;

namespace Qyl.Api.Contracts.Domains.Observe.Error;

// =============================================================================
// Error Type Attribute
// =============================================================================

@doc("Error type attribute (OTel stable)")
model ErrorAttributes {
  @doc("Error type - full exception class name or error code")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Error.Type)
  errorType: string;
}

// =============================================================================
// Error Categories
// =============================================================================

@doc("High-level error categories")
enum ErrorCategory {
  @doc("Client error (4xx)")
  client: "client",

  @doc("Server error (5xx)")
  server: "server",

  @doc("Network error")
  network: "network",

  @doc("Timeout error")
  timeout: "timeout",

  @doc("Validation error")
  validation: "validation",

  @doc("Authentication error")
  authentication: "authentication",

  @doc("Authorization error")
  authorization: "authorization",

  @doc("Rate limit error")
  rateLimit: "rate_limit",

  @doc("Resource not found")
  notFound: "not_found",

  @doc("Conflict error")
  conflict: "conflict",

  @doc("Internal error")
  internal: "internal",

  @doc("External service error")
  external: "external",

  @doc("Database error")
  database: "database",

  @doc("Configuration error")
  configuration: "configuration",

  @doc("Unknown error")
  `unknown`: "unknown",
}

// =============================================================================
// Error Entity
// =============================================================================

@doc("Error entity for tracking and analysis")
@TypeSpec.OpenAPI.extension("x-csharp-type", "ErrorEntity")
model ErrorEntity {
  @doc("Error ID")
  @key
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "error_id")
  errorId: string;

  @doc("Error type (class name or code)")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Error.Type)
  errorType: string;

  @doc("Error message")
  @visibility(Lifecycle.Read)
  message: string;

  @doc("Error category")
  @visibility(Lifecycle.Read)
  category: ErrorCategory;

  @doc("Fingerprint for grouping")
  @visibility(Lifecycle.Read)
  fingerprint: string;

  @doc("First occurrence")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "first_seen")
  firstSeen: utcDateTime;

  @doc("Last occurrence")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "last_seen")
  lastSeen: utcDateTime;

  @doc("Occurrence count")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "occurrence_count")
  occurrenceCount: Count;

  @doc("Affected users count")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "affected_users")
  affectedUsers?: Count;

  @doc("Affected services")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "affected_services")
  affectedServices?: string[];

  @doc("Status")
  @visibility(Lifecycle.Read, Lifecycle.Update)
  status: ErrorStatus;

  @doc("Assigned to")
  @visibility(Lifecycle.Read, Lifecycle.Update)
  @encodedName("application/json", "assigned_to")
  assignedTo?: string;

  @doc("Issue tracker URL")
  @visibility(Lifecycle.Read, Lifecycle.Update)
  @encodedName("application/json", "issue_url")
  issueUrl?: UrlString;

  @doc("Sample trace IDs")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "sample_traces")
  sampleTraces?: TraceId[];
}

@doc("Error tracking status")
enum ErrorStatus {
  @doc("New/unreviewed")
  new: "new",

  @doc("Acknowledged")
  acknowledged: "acknowledged",

  @doc("In progress")
  inProgress: "in_progress",

  @doc("Resolved")
  resolved: "resolved",

  @doc("Ignored")
  ignored: "ignored",

  @doc("Regressed")
  regressed: "regressed",

  @doc("Won't fix")
  wontFix: "wont_fix",
}

// =============================================================================
// Error Budget
// =============================================================================

@doc("Error budget tracking for SLOs")
model ErrorBudget {
  @doc("Service name")
  @encodedName("application/json", "service_name")
  serviceName: string;

  @doc("SLO target (e.g., 99.9%)")
  @encodedName("application/json", "slo_target")
  sloTarget: Percentage;

  @doc("Current SLI (actual success rate)")
  @encodedName("application/json", "current_sli")
  currentSli: Percentage;

  @doc("Budget remaining")
  @encodedName("application/json", "budget_remaining")
  budgetRemaining: Percentage;

  @doc("Budget consumed")
  @encodedName("application/json", "budget_consumed")
  budgetConsumed: Percentage;

  @doc("Budget period start")
  @encodedName("application/json", "period_start")
  periodStart: utcDateTime;

  @doc("Budget period end")
  @encodedName("application/json", "period_end")
  periodEnd: utcDateTime;

  @doc("Burn rate (how fast budget is being consumed)")
  @encodedName("application/json", "burn_rate")
  burnRate: float64;

  @doc("Budget status")
  status: ErrorBudgetStatus;
}

@doc("Error budget status")
enum ErrorBudgetStatus {
  @doc("Healthy - plenty of budget remaining")
  healthy: "healthy",

  @doc("Warning - budget is being consumed faster than expected")
  warning: "warning",

  @doc("Critical - budget nearly exhausted")
  critical: "critical",

  @doc("Exhausted - no budget remaining")
  exhausted: "exhausted",
}

// =============================================================================
// Error Rate Metrics
// =============================================================================

@doc("Error rate metric")
model ErrorRateMetric {
  @doc("Metric name")
  name: "error.rate";

  @doc("Metric unit (ratio)")
  unit: "1";

  @doc("Service name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Service.Name)
  serviceName: string;

  @doc("Error category")
  @encodedName("application/json", "error.category")
  category?: ErrorCategory;

  @doc("Endpoint")
  endpoint?: string;
}

@doc("Error count metric")
model ErrorCountMetric {
  @doc("Metric name")
  name: "errors";

  @doc("Metric unit")
  unit: "{error}";

  @doc("Service name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Service.Name)
  serviceName: string;

  @doc("Error type")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Error.Type)
  errorType: string;

  @doc("Error category")
  @encodedName("application/json", "error.category")
  category?: ErrorCategory;
}

// =============================================================================
// Error Analysis
// =============================================================================

@doc("Error correlation result")
model ErrorCorrelation {
  @doc("Error ID")
  @encodedName("application/json", "error_id")
  errorId: string;

  @doc("Correlated errors")
  @encodedName("application/json", "correlated_errors")
  correlatedErrors: CorrelatedError[];

  @doc("Potential root cause")
  @encodedName("application/json", "root_cause")
  rootCause?: string;

  @doc("Common attributes")
  @encodedName("application/json", "common_attributes")
  commonAttributes?: Attribute[];
}

@doc("Correlated error")
model CorrelatedError {
  @doc("Error ID")
  @encodedName("application/json", "error_id")
  errorId: string;

  @doc("Error type")
  @encodedName("application/json", "error_type")
  errorType: string;

  @doc("Correlation strength")
  @encodedName("application/json", "correlation_strength")
  correlationStrength: Ratio;

  @doc("Temporal relationship")
  @encodedName("application/json", "temporal_relationship")
  temporalRelationship: TemporalRelationship;
}

@doc("Temporal relationship between errors")
enum TemporalRelationship {
  @doc("Errors occur together")
  concurrent: "concurrent",

  @doc("This error precedes the other")
  precedes: "precedes",

  @doc("This error follows the other")
  follows: "follows",

  @doc("No clear temporal pattern")
  unrelated: "unrelated",
}

// =============================================================================
// Error Statistics
// =============================================================================

@doc("Error statistics")
model ErrorStats {
  @doc("Total error count")
  @encodedName("application/json", "total_count")
  totalCount: Count;

  @doc("Unique error types")
  @encodedName("application/json", "unique_types")
  uniqueTypes: int32;

  @doc("Error rate")
  @encodedName("application/json", "error_rate")
  errorRate: Ratio;

  @doc("Errors by category")
  @encodedName("application/json", "by_category")
  byCategory: ErrorCategoryStats[];

  @doc("Errors by service")
  @encodedName("application/json", "by_service")
  byService?: ErrorServiceStats[];

  @doc("Top errors")
  @encodedName("application/json", "top_errors")
  topErrors: ErrorTypeStats[];

  @doc("Trend")
  trend: ErrorTrend;
}

@doc("Error stats by category")
model ErrorCategoryStats {
  @doc("Category")
  category: ErrorCategory;

  @doc("Count")
  count: Count;

  @doc("Percentage of total")
  percentage: Percentage;
}

@doc("Error stats by service")
model ErrorServiceStats {
  @doc("Service name")
  @encodedName("application/json", "service_name")
  serviceName: string;

  @doc("Error count")
  count: Count;

  @doc("Error rate")
  @encodedName("application/json", "error_rate")
  errorRate: Ratio;

  @doc("Top error type")
  @encodedName("application/json", "top_error_type")
  topErrorType: string;
}

@doc("Error stats by type")
model ErrorTypeStats {
  @doc("Error type")
  @encodedName("application/json", "error_type")
  errorType: string;

  @doc("Count")
  count: Count;

  @doc("Percentage of total")
  percentage: Percentage;

  @doc("Affected users")
  @encodedName("application/json", "affected_users")
  affectedUsers?: Count;

  @doc("Status")
  status: ErrorStatus;
}

@doc("Error trend")
enum ErrorTrend {
  @doc("Errors increasing")
  increasing: "increasing",

  @doc("Errors decreasing")
  decreasing: "decreasing",

  @doc("Errors stable")
  stable: "stable",

  @doc("Anomalous spike")
  spike: "spike",
}
