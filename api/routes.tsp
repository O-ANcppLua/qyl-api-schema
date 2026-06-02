// =============================================================================
// qyl API routes
// =============================================================================
// RESTful API routes with proper pagination, streaming, and error handling.
// =============================================================================

import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi";
import "@typespec/versioning";

import "../common/types.tsp";
import "../common/errors.tsp";
import "../common/pagination.tsp";
import "../otel/span.tsp";
import "../otel/logs.tsp";
import "../otel/metrics.tsp";
import "../otel/profiles.tsp";
import "../models/session.tsp";
import "../models/log.tsp";
import "../models/error.tsp";
import "../models/deployment.tsp";
import "../models/identity.tsp";

// New domain models
import "../models/workspace.tsp";
import "../models/configurator.tsp";
import "../models/issues.tsp";
import "../models/alerting.tsp";
import "../models/workflow.tsp";
import "../models/search.tsp";

using TypeSpec.Http;
using TypeSpec.OpenAPI;
using TypeSpec.Versioning;

using Qyl.Api.Contracts.Common;
using Qyl.Api.Contracts.Common.Errors;
using Qyl.Api.Contracts.Common.Pagination;
using Qyl.Api.Contracts.OTel.Traces;
using Qyl.Api.Contracts.OTel.Logs;
using Qyl.Api.Contracts.OTel.Enums;
using Qyl.Api.Contracts.OTel.Profiles;
using Qyl.Api.Contracts.Domains.Observe.Session;
using Qyl.Api.Contracts.Domains.Observe.Log;
using Qyl.Api.Contracts.Domains.Observe.Error;
using Qyl.Api.Contracts.Domains.Ops.Deployment;
using Qyl.Api.Contracts.Domains.Identity;
using Qyl.Api.Contracts.Domains.Workspace;
using Qyl.Api.Contracts.Domains.Configurator;
using Qyl.Api.Contracts.Domains.Issues;
using Qyl.Api.Contracts.Domains.Alerting;
using Qyl.Api.Contracts.Domains.Workflow;
using Qyl.Api.Contracts.Domains.Search;

// =============================================================================
// API Versioning
// =============================================================================

@versioned(ApiVersions)
@service(#{
  title: "qyl Observability API",
})
@server("https://api.qyl.dev", "qyl production API")
@server("https://api.staging.qyl.dev", "qyl staging API")
namespace Qyl.Api.Contracts;

enum ApiVersions {
  @doc("Initial API version")
  v1: "2025-12-01",

  @doc("GenAI observability additions")
  v2: "2026-01-15",

  @doc("Full OTel v1.40 compliance")
  v3: "2026-01-26",
}

// =============================================================================
// Common Response Models
// =============================================================================

@doc("Health status for component-level reporting (HealthUiResponse, dashboard).")
enum HealthStatus {
  healthy: "healthy",
  degraded: "degraded",
  unhealthy: "unhealthy",
}

// =============================================================================
// Traces API
// =============================================================================

@route("/api/v1/traces")
@tag("Traces")
interface TracesApi {
  @doc("List traces with pagination")
  @get
  list(
    @query @doc("Service name filter") serviceName?: string,
    @query @doc("Minimum duration in ms") minDurationMs?: int64,
    @query @doc("Maximum duration in ms") maxDurationMs?: int64,
    @query @doc("Status filter") status?: SpanStatusCode,
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
    @query @doc("Page size") @minValue(1) @maxValue(1000) limit?: int32 = 100,
    @query @doc("Cursor for pagination") cursor?: string,
  ): CursorPage<Trace> | NotFoundError | ValidationError | InternalServerError;

  @doc("Get a specific trace by ID")
  @get
  @route("/{traceId}")
  get(@path traceId: TraceId): Trace | NotFoundError | InternalServerError;

  @doc("Get spans for a trace")
  @get
  @route("/{traceId}/spans")
  getSpans(
    @path traceId: TraceId,
    @query @doc("Page size") @minValue(1) @maxValue(1000) limit?: int32 = 100,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<Span> | NotFoundError | InternalServerError;

  @doc("Search traces")
  @post
  @route("/search")
  search(@body query: TraceQuery): CursorPage<Trace> | ValidationError | InternalServerError;
}

@doc("Trace search query")
model TraceQuery {
  @doc("Free text search")
  query?: string;

  @doc("Service name filter")
  @encodedName("application/json", "service_name")
  serviceName?: string;

  @doc("Operation name filter")
  @encodedName("application/json", "operation_name")
  operationName?: string;

  @doc("Minimum duration in milliseconds")
  @encodedName("application/json", "min_duration_ms")
  minDurationMs?: int64;

  @doc("Maximum duration in milliseconds")
  @encodedName("application/json", "max_duration_ms")
  maxDurationMs?: int64;

  @doc("Status filter")
  status?: SpanStatusCode;

  @doc("Time range start")
  @encodedName("application/json", "start_time")
  startTime?: utcDateTime;

  @doc("Time range end")
  @encodedName("application/json", "end_time")
  endTime?: utcDateTime;

  @doc("Tag filters")
  tags?: Record<string>;

  @doc("Page size")
  @minValue(1)
  @maxValue(1000)
  limit?: int32 = 100;

  @doc("Cursor")
  cursor?: string;
}

// =============================================================================
// Logs API
// =============================================================================

@route("/api/v1/logs")
@tag("Logs")
interface LogsApi {
  @doc("Query logs with filtering and pagination")
  @get
  list(
    @query @doc("Service name filter") serviceName?: string,
    @query @doc("Minimum severity") severityMin?: SeverityNumber,
    @query @doc("Maximum severity") severityMax?: SeverityNumber,
    @query @doc("Trace ID filter") traceId?: TraceId,
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
    @query @doc("Free text search") query?: string,
    @query @doc("Page size") @minValue(1) @maxValue(10000) limit?: int32 = 100,
    @query @doc("Cursor") cursor?: string,
    @query @doc("Order") orderBy?: LogOrderBy,
  ): CursorPage<LogRecord> | ValidationError | InternalServerError;

  @doc("Search logs with complex query")
  @post
  @route("/search")
  search(@body query: LogQuery): CursorPage<LogRecord> | ValidationError | InternalServerError;

  @doc("Aggregate logs")
  @post
  @route("/aggregate")
  aggregate(@body request: LogAggregationRequest): LogAggregationResponse | ValidationError | InternalServerError;

  @doc("Get log patterns")
  @get
  @route("/patterns")
  getPatterns(
    @query @doc("Service name filter") serviceName?: string,
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
    @query @doc("Minimum occurrences") minCount?: int32,
  ): LogPattern[] | InternalServerError;

  @doc("Get log statistics")
  @get
  @route("/stats")
  getStats(
    @query @doc("Service name filter") serviceName?: string,
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
  ): Qyl.Api.Contracts.OTel.Logs.LogStats | InternalServerError;
}

@doc("Log aggregation request")
model LogAggregationRequest {
  @doc("Query filters")
  query?: LogQuery;

  @doc("Aggregation specification")
  aggregation: LogAggregation;
}

@doc("Log aggregation response")
model LogAggregationResponse {
  @doc("Aggregation results")
  results: LogAggregationBucket[];

  @doc("Total matching logs")
  @encodedName("application/json", "total_count")
  totalCount: Count;
}

@doc("Log aggregation bucket")
model LogAggregationBucket {
  @doc("Bucket key (group by value)")
  key: string;

  @doc("Aggregated value")
  value: float64;

  @doc("Document count")
  count: Count;

  @doc("Timestamp (for time series)")
  timestamp?: utcDateTime;
}

// =============================================================================
// Metrics API
// =============================================================================

@route("/api/v1/metrics")
@tag("Metrics")
interface MetricsApi {
  @doc("List available metrics")
  @get
  list(
    @query @doc("Service name filter") serviceName?: string,
    @query @doc("Metric name pattern") namePattern?: string,
    @query @doc("Page size") @minValue(1) @maxValue(1000) limit?: int32 = 100,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<MetricMetadata> | InternalServerError;

  @doc("Query metric data points")
  @post
  @route("/query")
  query(@body request: MetricQueryRequest): MetricQueryResponse | ValidationError | InternalServerError;

  @doc("Get metric metadata")
  @get
  @route("/{metricName}")
  getMetadata(@path metricName: string): MetricMetadata | NotFoundError | InternalServerError;
}

@doc("Metric metadata")
model MetricMetadata {
  @doc("Metric name")
  name: string;

  @doc("Metric description")
  description?: string;

  @doc("Metric unit")
  unit?: string;

  @doc("Metric type")
  type: MetricType;

  @doc("Available label keys")
  @encodedName("application/json", "label_keys")
  labelKeys: string[];

  @doc("Services reporting this metric")
  services: string[];
}

@doc("Metric query request")
model MetricQueryRequest {
  @doc("Metric name")
  @encodedName("application/json", "metric_name")
  metricName: string;

  @doc("Label filters")
  filters?: Record<string>;

  @doc("Start time")
  @encodedName("application/json", "start_time")
  startTime: utcDateTime;

  @doc("End time")
  @encodedName("application/json", "end_time")
  endTime: utcDateTime;

  @doc("Step interval")
  step?: Qyl.Api.Contracts.Common.Pagination.TimeBucket;

  @doc("Aggregation function")
  aggregation?: Qyl.Api.Contracts.OTel.Metrics.AggregationFunction;

  @doc("Group by labels")
  @encodedName("application/json", "group_by")
  groupBy?: string[];
}

@doc("Metric query response")
model MetricQueryResponse {
  @doc("Metric name")
  @encodedName("application/json", "metric_name")
  metricName: string;

  @doc("Time series data")
  series: MetricTimeSeries[];
}

@doc("Metric time series")
model MetricTimeSeries {
  @doc("Labels")
  labels: Record<string>;

  @doc("Data points")
  points: MetricDataPoint[];
}

@doc("Metric data point")
model MetricDataPoint {
  @doc("Timestamp")
  timestamp: utcDateTime;

  @doc("Value")
  value: float64;
}

// =============================================================================
// Profiles API (v1development, Development stability)
// =============================================================================

@route("/api/v1/profiles")
@tag("Profiles")
interface ProfilesApi {
  @doc("List profiles with filtering")
  @get
  list(
    @query @doc("Session ID filter") sessionId?: SessionId,
    @query @doc("Trace ID filter") traceId?: TraceId,
    @query @doc("Service name filter") serviceName?: string,
    @query @doc("Sample type filter (e.g., cpu, alloc_objects, wall)") sampleType?: string,
    @query @doc("Page size") @minValue(1) @maxValue(1000) limit?: int32 = 100,
  ): Profile[] | ValidationError | InternalServerError;

  @doc("Get a specific profile by ID")
  @get
  @route("/{profileId}")
  get(@path profileId: string): Profile | NotFoundError | InternalServerError;

  @doc("Get profiles for a trace")
  @get
  @route("/by-trace/{traceId}")
  getByTrace(
    @path traceId: TraceId,
    @query @doc("Page size") @minValue(1) @maxValue(1000) limit?: int32 = 100,
  ): Profile[] | InternalServerError;

  @doc("Get profiles for a span")
  @get
  @route("/by-span/{spanId}")
  getBySpan(
    @path spanId: SpanId,
    @query @doc("Page size") @minValue(1) @maxValue(1000) limit?: int32 = 100,
  ): Profile[] | InternalServerError;
}

// =============================================================================
// Sessions API
// =============================================================================

@route("/api/v1/sessions")
@tag("Sessions")
interface SessionsApi {
  @doc("List sessions")
  @get
  list(
    @query @doc("User ID filter") userId?: UserId,
    @query @doc("Is active filter") isActive?: boolean,
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
    @query @doc("Page size") @minValue(1) @maxValue(1000) limit?: int32 = 100,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<SessionEntity> | ValidationError | InternalServerError;

  @doc("Get session by ID")
  @get
  @route("/{sessionId}")
  get(@path sessionId: string): SessionEntity | NotFoundError | InternalServerError;

  @doc("Get session traces")
  @get
  @route("/{sessionId}/traces")
  getTraces(
    @path sessionId: string,
    @query @doc("Page size") limit?: int32 = 100,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<Trace> | NotFoundError | InternalServerError;

  @doc("Get session statistics")
  @get
  @route("/stats")
  getStats(
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
  ): SessionStats | InternalServerError;
}

// =============================================================================
// Errors API
// =============================================================================

@route("/api/v1/errors")
@tag("Errors")
interface ErrorsApi {
  @doc("List error groups")
  @get
  list(
    @query @doc("Service name filter") serviceName?: string,
    @query @doc("Status filter") status?: ErrorStatus,
    @query @doc("Category filter") category?: ErrorCategory,
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
    @query @doc("Page size") @minValue(1) @maxValue(1000) limit?: int32 = 100,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<ErrorEntity> | ValidationError | InternalServerError;

  @doc("Get error by ID")
  @get
  @route("/{errorId}")
  get(@path errorId: string): ErrorEntity | NotFoundError | InternalServerError;

  @doc("Update error status")
  @patch
  @route("/{errorId}")
  update(
    @path errorId: string,
    @body update: MergePatchUpdate<ErrorEntity>,
  ): ErrorEntity | NotFoundError | ValidationError | InternalServerError;

  @doc("Get error statistics")
  @get
  @route("/stats")
  getStats(
    @query @doc("Service name filter") serviceName?: string,
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
  ): ErrorStats | InternalServerError;

  @doc("Get error correlations")
  @get
  @route("/{errorId}/correlations")
  getCorrelations(@path errorId: string): ErrorCorrelation | NotFoundError | InternalServerError;
}


// =============================================================================
// Deployments API
// =============================================================================

@route("/api/v1/deployments")
@tag("Deployments")
interface DeploymentsApi {
  @doc("List deployments")
  @get
  list(
    @query @doc("Service name filter") serviceName?: string,
    @query @doc("Environment filter") environment?: DeploymentEnvironment,
    @query @doc("Status filter") status?: DeploymentStatus,
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
    @query @doc("Page size") @minValue(1) @maxValue(1000) limit?: int32 = 100,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<DeploymentEntity> | ValidationError | InternalServerError;

  @doc("Get deployment by ID")
  @get
  @route("/{deploymentId}")
  get(@path deploymentId: string): DeploymentEntity | NotFoundError | InternalServerError;

  @doc("Record new deployment")
  @post
  create(@body deployment: Create<DeploymentEntity>): DeploymentEntity | ValidationError | InternalServerError;

  @doc("Update deployment status")
  @patch
  @route("/{deploymentId}")
  update(
    @path deploymentId: string,
    @body update: MergePatchUpdate<DeploymentEntity>,
  ): DeploymentEntity | NotFoundError | ValidationError | InternalServerError;

  @doc("Get DORA metrics")
  @get
  @route("/metrics/dora")
  getDoraMetrics(
    @query @doc("Service name filter") serviceName?: string,
    @query @doc("Environment filter") environment?: DeploymentEnvironment,
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
  ): DoraMetrics | InternalServerError;
}

@doc("DORA metrics response")
model DoraMetrics {
  @doc("Deployment frequency (per day)")
  @encodedName("application/json", "deployment_frequency")
  deploymentFrequency: float64;

  @doc("Lead time for changes (hours)")
  @encodedName("application/json", "lead_time_hours")
  leadTimeHours: float64;

  @doc("Change failure rate")
  @encodedName("application/json", "change_failure_rate")
  changeFailureRate: Ratio;

  @doc("Mean time to recovery (hours)")
  @encodedName("application/json", "mttr_hours")
  mttrHours: float64;

  @doc("Performance level")
  @encodedName("application/json", "performance_level")
  performanceLevel: DoraPerformanceLevel;
}

@doc("DORA performance levels")
enum DoraPerformanceLevel {
  @doc("Elite performer")
  elite: "elite",

  @doc("High performer")
  high: "high",

  @doc("Medium performer")
  medium: "medium",

  @doc("Low performer")
  low: "low",
}

// =============================================================================
// Services API
// =============================================================================

@route("/api/v1/services")
@tag("Services")
interface ServicesApi {
  @doc("List discovered services")
  @get
  list(
    @query @doc("Namespace filter") namespaceName?: string,
    @query @doc("Page size") @minValue(1) @maxValue(1000) limit?: int32 = 100,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<ServiceInfo> | InternalServerError;

  @doc("Get service details")
  @get
  @route("/{serviceName}")
  get(@path serviceName: string): ServiceDetails | NotFoundError | InternalServerError;

  @doc("Get service dependencies")
  @get
  @route("/{serviceName}/dependencies")
  getDependencies(@path serviceName: string): ServiceDependency[] | NotFoundError | InternalServerError;

  @doc("Get service operations")
  @get
  @route("/{serviceName}/operations")
  getOperations(
    @path serviceName: string,
    @query @doc("Page size") limit?: int32 = 100,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<OperationInfo> | NotFoundError | InternalServerError;
}

@doc("Service information")
model ServiceInfo {
  @doc("Service name")
  name: string;

  @doc("Service namespace")
  @encodedName("application/json", "namespace_name")
  namespaceName?: string;

  @doc("Service version")
  version?: SemVer;

  @doc("Instance count")
  @encodedName("application/json", "instance_count")
  instanceCount: int32;

  @doc("Last seen")
  @encodedName("application/json", "last_seen")
  lastSeen: utcDateTime;
}

@doc("Service details")
model ServiceDetails {
  ...ServiceInfo;

  @doc("Resource attributes")
  @encodedName("application/json", "resource_attributes")
  resourceAttributes: Attribute[];

  @doc("Instrumentation libraries")
  @encodedName("application/json", "instrumentation_libraries")
  instrumentationLibraries: InstrumentationScope[];

  @doc("Request rate (per second)")
  @encodedName("application/json", "request_rate")
  requestRate: float64;

  @doc("Error rate")
  @encodedName("application/json", "error_rate")
  errorRate: Ratio;

  @doc("Average latency in milliseconds")
  @encodedName("application/json", "avg_latency_ms")
  avgLatencyMs: float64;

  @doc("P99 latency in milliseconds")
  @encodedName("application/json", "p99_latency_ms")
  p99LatencyMs: float64;
}

@doc("Operation information")
model OperationInfo {
  @doc("Operation name")
  name: string;

  @doc("Span kind")
  @encodedName("application/json", "span_kind")
  spanKind: SpanKind;

  @doc("Request count")
  @encodedName("application/json", "request_count")
  requestCount: Count;

  @doc("Error count")
  @encodedName("application/json", "error_count")
  errorCount: Count;

  @doc("Average duration in milliseconds")
  @encodedName("application/json", "avg_duration_ms")
  avgDurationMs: float64;

  @doc("P99 duration in milliseconds")
  @encodedName("application/json", "p99_duration_ms")
  p99DurationMs: float64;
}

// =============================================================================
// Health API — Aspire-shape probes. /alive is cheap liveness (live-tagged checks),
// /health runs all ready-tagged checks. Collector exposes a rich /health/ui DTO for
// the dashboard, modelled separately as HealthUiResponse.
// =============================================================================

@tag("Health")
interface HealthApi {
  @doc("Liveness probe — runs live-tagged health checks.")
  @route("/alive")
  @get
  @operationId("health_alive")
  alive(): {
    @statusCode statusCode: 200;
  } | {
    @statusCode statusCode: 503;
  };

  @doc("Readiness probe — runs all ready-tagged health checks.")
  @route("/health")
  @get
  @operationId("health_ready")
  ready(): {
    @statusCode statusCode: 200;
  } | {
    @statusCode statusCode: 503;
  };
}

// =============================================================================
// Workspace API
// =============================================================================

@route("/api/v1/workspaces")
@tag("Workspaces")
interface WorkspacesApi {
  @doc("Get current workspace envelope")
  @get
  @route("/current")
  getCurrent(): WorkspaceEnvelopeEntity | NotFoundError | InternalServerError;

  @doc("Register workspace heartbeat")
  @post
  @route("/current/heartbeat")
  heartbeat(): WorkspaceEnvelopeEntity | NotFoundError | InternalServerError;

  @doc("List projects")
  @get
  @route("/projects")
  listProjects(
    @query @doc("Page size") @minValue(1) @maxValue(100) limit?: int32 = 20,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<ProjectEntity> | InternalServerError;

  @doc("Get project by ID")
  @get
  @route("/projects/{projectId}")
  getProject(@path projectId: string): ProjectEntity | NotFoundError | InternalServerError;

  @doc("Create a new project")
  @post
  @route("/projects")
  createProject(@body project: Create<ProjectEntity>): ProjectEntity | ValidationError | InternalServerError;

  @doc("List environments for a project")
  @get
  @route("/projects/{projectId}/environments")
  listEnvironments(@path projectId: string): ProjectEnvironmentEntity[] | NotFoundError | InternalServerError;
}

// =============================================================================
// Onboarding API
// =============================================================================

@route("/api/v1/onboarding")
@tag("Onboarding")
interface OnboardingApi {
  @doc("Start a new handshake session")
  @post
  @route("/handshake")
  startHandshake(@body request: HandshakeStartRequest): HandshakeSessionEntity | ValidationError | InternalServerError;

  @doc("Complete handshake verification")
  @post
  @route("/handshake/{sessionId}/verify")
  verifyHandshake(
    @path sessionId: string,
    @body request: HandshakeVerifyRequest,
  ): HandshakeVerifyResponse | NotFoundError | ValidationError | InternalServerError;

  @doc("Get handshake session status")
  @get
  @route("/handshake/{sessionId}")
  getHandshake(@path sessionId: string): HandshakeSessionEntity | NotFoundError | InternalServerError;
}

@doc("Handshake start request")
model HandshakeStartRequest {
  @doc("PKCE code challenge")
  @encodedName("application/json", "code_challenge")
  codeChallenge: string;

  @doc("Client identifier")
  @encodedName("application/json", "client_id")
  clientId: string;
}

@doc("Handshake verification request")
model HandshakeVerifyRequest {
  @doc("PKCE code verifier")
  @encodedName("application/json", "code_verifier")
  codeVerifier: string;

  @doc("Authorization code")
  code: string;
}

@doc("Handshake verification response")
model HandshakeVerifyResponse {
  @doc("Access token")
  @encodedName("application/json", "access_token")
  accessToken: string;

  @doc("Token expiration")
  @encodedName("application/json", "expires_at")
  expiresAt: utcDateTime;

  @doc("Workspace ID")
  @encodedName("application/json", "workspace_id")
  workspaceId: string;
}

// =============================================================================
// Configurator API
// =============================================================================

@route("/api/v1/configurator")
@tag("Configurator")
interface ConfiguratorApi {
  @doc("List generation profiles")
  @get
  @route("/profiles")
  listProfiles(
    @query @doc("Page size") @minValue(1) @maxValue(100) limit?: int32 = 20,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<GenerationProfileEntity> | InternalServerError;

  @doc("Get generation profile by ID")
  @get
  @route("/profiles/{profileId}")
  getProfile(@path profileId: string): GenerationProfileEntity | NotFoundError | InternalServerError;

  @doc("Create generation profile")
  @post
  @route("/profiles")
  createProfile(@body profile: Create<GenerationProfileEntity>): GenerationProfileEntity | ValidationError | InternalServerError;

  @doc("Get generation selections for a workspace")
  @get
  @route("/selections")
  getSelections(
    @query @doc("Workspace ID") workspaceId: string,
  ): GenerationSelectionEntity[] | InternalServerError;

  @doc("Save generation selections")
  @post
  @route("/selections")
  saveSelections(@body selections: GenerationSelectionSaveRequest): GenerationSelectionEntity | ValidationError | InternalServerError;

  @doc("Create a generation job")
  @post
  @route("/jobs")
  createJob(@body job: Create<GenerationJobEntity>): GenerationJobEntity | ValidationError | InternalServerError;

  @doc("Get generation job status")
  @get
  @route("/jobs/{jobId}")
  getJob(@path jobId: string): GenerationJobEntity | NotFoundError | InternalServerError;
}

@doc("Batch upsert request — workspace+profile scope from GenerationSelectionEntity, plus an array of selection keys")
model GenerationSelectionSaveRequest {
  ...PickProperties<GenerationSelectionEntity, "workspaceId" | "profileId">;

  @doc("Array of selection keys to enable in a single round-trip")
  @encodedName("application/json", "selected_keys")
  selectedKeys: string[];
}

// =============================================================================
// Issues API (Sentry-style error grouping)
// =============================================================================

@route("/api/v1/issues")
@tag("Issues")
interface IssuesApi {
  @doc("List error issues")
  @get
  list(
    @query @doc("Project ID filter") projectId?: string,
    @query @doc("Status filter") status?: IssueStatus,
    @query @doc("Priority filter") priority?: IssuePriority,
    @query @doc("Level filter") level?: IssueLevel,
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
    @query @doc("Page size") @minValue(1) @maxValue(100) limit?: int32 = 20,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<ErrorIssueEntity> | ValidationError | InternalServerError;

  @doc("Get issue by ID")
  @get
  @route("/{issueId}")
  get(@path issueId: string): ErrorIssueEntity | NotFoundError | InternalServerError;

  @doc("Update issue status")
  @patch
  @route("/{issueId}")
  update(
    @path issueId: string,
    @body update: MergePatchUpdate<ErrorIssueEntity>,
  ): ErrorIssueEntity | NotFoundError | ValidationError | InternalServerError;

  @doc("Get issue events")
  @get
  @route("/{issueId}/events")
  getEvents(
    @path issueId: string,
    @query @doc("Page size") @minValue(1) @maxValue(100) limit?: int32 = 20,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<ErrorIssueEventEntity> | NotFoundError | InternalServerError;

  @doc("Get issue breadcrumbs")
  @get
  @route("/{issueId}/breadcrumbs")
  getBreadcrumbs(
    @path issueId: string,
    @query @doc("Page size") @minValue(1) @maxValue(50) limit?: int32 = 20,
  ): ErrorBreadcrumbEntity[] | NotFoundError | InternalServerError;
}


// =============================================================================
// Workflow API
// =============================================================================

@route("/api/v1/workflows")
@tag("Workflows")
interface WorkflowsApi {
  @doc("List workflow runs")
  @get
  @route("/runs")
  listRuns(
    @query @doc("Project ID filter") projectId?: string,
    @query @doc("Workflow ID filter") workflowId?: string,
    @query @doc("Status filter") status?: WorkflowRunStatus,
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
    @query @doc("Page size") @minValue(1) @maxValue(100) limit?: int32 = 20,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<WorkflowRunEntity> | ValidationError | InternalServerError;

  @doc("Get workflow run by ID")
  @get
  @route("/runs/{runId}")
  getRun(@path runId: string): WorkflowRunEntity | NotFoundError | InternalServerError;

  @doc("Get workflow run nodes")
  @get
  @route("/runs/{runId}/nodes")
  getRunNodes(
    @path runId: string,
    @query @doc("Page size") @minValue(1) @maxValue(100) limit?: int32 = 50,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<WorkflowNodeEntity> | NotFoundError | InternalServerError;

  @doc("Get workflow events")
  @get
  @route("/runs/{runId}/events")
  getRunEvents(
    @path runId: string,
    @query @doc("After sequence number") afterSequence?: int64,
    @query @doc("Page size") @minValue(1) @maxValue(100) limit?: int32 = 50,
  ): WorkflowEventEntity[] | NotFoundError | InternalServerError;

  @doc("Resume a paused workflow")
  @post
  @route("/runs/{runId}/resume")
  resumeRun(@path runId: string): WorkflowRunEntity | NotFoundError | ValidationError | InternalServerError;

  @doc("Approve a pending workflow step")
  @post
  @route("/runs/{runId}/nodes/{nodeId}/approve")
  approveStep(
    @path runId: string,
    @path nodeId: string,
  ): WorkflowNodeEntity | NotFoundError | ValidationError | InternalServerError;
}

// =============================================================================
// Search API
// =============================================================================

@route("/api/v1/search")
@tag("Search")
interface SearchApi {
  @doc("Unified search across all entity types")
  @post
  search(@body request: SearchRequest): SearchResponse | ValidationError | InternalServerError;

  @doc("Get search suggestions")
  @get
  @route("/suggestions")
  getSuggestions(
    @query @doc("Query prefix") query: string,
    @query @doc("Maximum suggestions") @minValue(1) @maxValue(20) limit?: int32 = 5,
  ): string[] | InternalServerError;
}

// =============================================================================
// Alerts API
// =============================================================================

@route("/api/v1/alerts")
@tag("Alerts")
interface AlertsApi {
  @doc("List alert rules")
  @get
  @route("/rules")
  listRules(
    @query @doc("Project ID filter") projectId?: string,
    @query @doc("Enabled filter") enabled?: boolean,
    @query @doc("Page size") @minValue(1) @maxValue(100) limit?: int32 = 20,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<AlertRuleEntity> | InternalServerError;

  @doc("Get alert rule by ID")
  @get
  @route("/rules/{ruleId}")
  getRule(@path ruleId: string): AlertRuleEntity | NotFoundError | InternalServerError;

  @doc("Create a new alert rule")
  @post
  @route("/rules")
  createRule(@body rule: AlertRuleEntity): AlertRuleEntity | ValidationError | InternalServerError;

  @doc("Update an existing alert rule")
  @put
  @route("/rules/{ruleId}")
  updateRule(
    @path ruleId: string,
    @body rule: AlertRuleEntity,
  ): AlertRuleEntity | NotFoundError | ValidationError | InternalServerError;

  @doc("Delete an alert rule")
  @delete
  @route("/rules/{ruleId}")
  deleteRule(@path ruleId: string): NoContentResponse | NotFoundError | InternalServerError;

  @doc("List alert firings")
  @get
  @route("/firings")
  listFirings(
    @query @doc("Rule ID filter") ruleId?: string,
    @query @doc("Status filter") status?: AlertFiringStatus,
    @query @doc("Start time") startTime?: utcDateTime,
    @query @doc("End time") endTime?: utcDateTime,
    @query @doc("Page size") @minValue(1) @maxValue(100) limit?: int32 = 20,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<AlertFiringEntity> | ValidationError | InternalServerError;

  @doc("Acknowledge an alert firing")
  @post
  @route("/firings/{firingId}/acknowledge")
  acknowledgeFiring(
    @path firingId: string,
    @body acknowledgement: AlertFiringAcknowledgement,
  ): AlertFiringEntity | NotFoundError | InternalServerError;

  @doc("Resolve an alert firing")
  @post
  @route("/firings/{firingId}/resolve")
  resolveFiring(@path firingId: string): AlertFiringEntity | NotFoundError | InternalServerError;

  @doc("List fix runs")
  @get
  @route("/fixes")
  listFixRuns(
    @query @doc("Issue ID filter") issueId?: string,
    @query @doc("Status filter") status?: FixRunStatus,
    @query @doc("Page size") @minValue(1) @maxValue(100) limit?: int32 = 20,
    @query @doc("Cursor") cursor?: string,
  ): CursorPage<FixRunEntity> | ValidationError | InternalServerError;

  @doc("Get fix run by ID")
  @get
  @route("/fixes/{fixId}")
  getFixRun(@path fixId: string): FixRunEntity | NotFoundError | InternalServerError;
}

@doc("Acknowledge request body for an alert firing")
model AlertFiringAcknowledgement {
  @doc("User or service that acknowledges the firing")
  @encodedName("application/json", "acknowledged_by")
  acknowledgedBy: string;
}
