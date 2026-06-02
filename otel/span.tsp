// =============================================================================
// ANcpLua v2.0 - OpenTelemetry Span Model
// =============================================================================
// Distributed tracing span representation following OTel specification.
// =============================================================================

import "@typespec/http";
import "@typespec/openapi";
import "../common/types.tsp";
import "./enums.tsp";
import "./resource.tsp";

using TypeSpec.Http;
using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;
using Qyl.Api.Contracts.OTel.Enums;
using Qyl.Api.Contracts.OTel.Resource;

namespace Qyl.Api.Contracts.OTel.Traces;

// =============================================================================
// Span Model
// =============================================================================

@doc("OpenTelemetry Span representing a single operation in a distributed trace")
model Span {
  @doc("Unique span identifier (16 hex chars)")
  @key
  @encodedName("application/json", "span_id")
  spanId: SpanId;

  @doc("Trace identifier (32 hex chars)")
  @encodedName("application/json", "trace_id")
  traceId: TraceId;

  @doc("Parent span identifier (null for root spans)")
  @encodedName("application/json", "parent_span_id")
  parentSpanId?: SpanId;

  @doc("W3C trace state")
  @encodedName("application/json", "trace_state")
  traceState?: TraceState;

  @doc("Human-readable span name")
  @minLength(1)
  name: string;

  @doc("Span kind")
  kind: SpanKind;

  @doc("Start timestamp in nanoseconds since epoch")
  @encodedName("application/json", "start_time_unix_nano")
  startTimeUnixNano: UnixNanos;

  @doc("End timestamp in nanoseconds since epoch")
  @encodedName("application/json", "end_time_unix_nano")
  endTimeUnixNano: UnixNanos;

  @doc("Span attributes")
  attributes?: Attribute[];

  @doc("Dropped attributes count")
  @encodedName("application/json", "dropped_attributes_count")
  droppedAttributesCount?: Count;

  @doc("Span events (logs attached to span)")
  events?: SpanEvent[];

  @doc("Dropped events count")
  @encodedName("application/json", "dropped_events_count")
  droppedEventsCount?: Count;

  @doc("Links to other spans")
  links?: SpanLink[];

  @doc("Dropped links count")
  @encodedName("application/json", "dropped_links_count")
  droppedLinksCount?: Count;

  @doc("Span status")
  status: SpanStatus;

  @doc("Span flags")
  flags?: int32;

  @doc("Resource describing the entity that produced this span")
  resource: Qyl.Api.Contracts.OTel.Resource.Resource;

  @doc("Instrumentation scope")
  @encodedName("application/json", "instrumentation_scope")
  instrumentationScope?: InstrumentationScope;
}

@doc("Span status")
model SpanStatus {
  @doc("Status code")
  code: SpanStatusCode;

  @doc("Status message (only for ERROR status)")
  message?: string;
}

@doc("Event occurring during a span's lifetime")
model SpanEvent {
  @doc("Event name")
  @minLength(1)
  name: string;

  @doc("Event timestamp in nanoseconds since epoch")
  @encodedName("application/json", "time_unix_nano")
  timeUnixNano: UnixNanos;

  @doc("Event attributes")
  attributes?: Attribute[];

  @doc("Dropped attributes count")
  @encodedName("application/json", "dropped_attributes_count")
  droppedAttributesCount?: Count;
}

@doc("Link to another span (e.g., batch processing)")
model SpanLink {
  @doc("Linked trace ID")
  @encodedName("application/json", "trace_id")
  traceId: TraceId;

  @doc("Linked span ID")
  @encodedName("application/json", "span_id")
  spanId: SpanId;

  @doc("Trace state of the linked span")
  @encodedName("application/json", "trace_state")
  traceState?: TraceState;

  @doc("Link attributes")
  attributes?: Attribute[];

  @doc("Dropped attributes count")
  @encodedName("application/json", "dropped_attributes_count")
  droppedAttributesCount?: Count;

  @doc("Link flags")
  flags?: int32;
}

// =============================================================================
// Trace Model (Collection of Spans)
// =============================================================================

@doc("Complete trace containing all related spans")
model Trace {
  @doc("Trace identifier")
  @key
  @encodedName("application/json", "trace_id")
  traceId: TraceId;

  @doc("All spans in this trace")
  spans: Span[];

  @doc("Root span of the trace")
  @encodedName("application/json", "root_span")
  rootSpan?: Span;

  @doc("Total span count")
  @encodedName("application/json", "span_count")
  spanCount: int32;

  @doc("Trace duration in nanoseconds")
  @encodedName("application/json", "duration_ns")
  durationNs: DurationNs;

  @doc("Trace start time")
  @encodedName("application/json", "start_time")
  startTime: utcDateTime;

  @doc("Trace end time")
  @encodedName("application/json", "end_time")
  endTime: utcDateTime;

  @doc("Services involved in this trace")
  services: string[];

  @doc("Whether trace contains errors")
  @encodedName("application/json", "has_error")
  hasError: boolean;
}

// =============================================================================
// Span Query Filters
// =============================================================================

@doc("Filter parameters for querying spans")
model SpanQueryFilters {
  @doc("Filter by trace ID")
  @query
  @encodedName("application/json", "trace_id")
  traceId?: TraceId;

  @doc("Filter by parent span ID")
  @query
  @encodedName("application/json", "parent_span_id")
  parentSpanId?: SpanId;

  @doc("Filter by span name (supports wildcards)")
  @query
  name?: string;

  @doc("Filter by span kind")
  @query
  kind?: SpanKind;

  @doc("Filter by service name")
  @query
  @encodedName("application/json", "service_name")
  serviceName?: string;

  @doc("Filter by status code")
  @query
  @encodedName("application/json", "status_code")
  statusCode?: SpanStatusCode;

  @doc("Minimum duration in nanoseconds")
  @query
  @encodedName("application/json", "min_duration_ns")
  minDurationNs?: DurationNs;

  @doc("Maximum duration in nanoseconds")
  @query
  @encodedName("application/json", "max_duration_ns")
  maxDurationNs?: DurationNs;

  @doc("Filter by attribute key-value pair")
  @query
  attribute?: string;
}

// =============================================================================
// Span Aggregations
// =============================================================================

@doc("Aggregated span statistics")
model SpanStats {
  @doc("Total span count")
  @encodedName("application/json", "total_count")
  totalCount: Count;

  @doc("Error count")
  @encodedName("application/json", "error_count")
  errorCount: Count;

  @doc("Error rate (0.0 - 1.0)")
  @encodedName("application/json", "error_rate")
  errorRate: Ratio;

  @doc("Average duration in nanoseconds")
  @encodedName("application/json", "avg_duration_ns")
  avgDurationNs: float64;

  @doc("P50 duration in nanoseconds")
  @encodedName("application/json", "p50_duration_ns")
  p50DurationNs: DurationNs;

  @doc("P90 duration in nanoseconds")
  @encodedName("application/json", "p90_duration_ns")
  p90DurationNs: DurationNs;

  @doc("P99 duration in nanoseconds")
  @encodedName("application/json", "p99_duration_ns")
  p99DurationNs: DurationNs;

  @doc("Minimum duration in nanoseconds")
  @encodedName("application/json", "min_duration_ns")
  minDurationNs: DurationNs;

  @doc("Maximum duration in nanoseconds")
  @encodedName("application/json", "max_duration_ns")
  maxDurationNs: DurationNs;

  @doc("Throughput (spans per second)")
  @encodedName("application/json", "throughput_per_second")
  throughputPerSecond: float64;

  @doc("Stats grouped by service")
  @encodedName("application/json", "by_service")
  byService?: SpanStatsByDimension[];

  @doc("Stats grouped by operation name")
  @encodedName("application/json", "by_operation")
  byOperation?: SpanStatsByDimension[];
}

@doc("Span statistics for a specific dimension value")
model SpanStatsByDimension {
  @doc("Dimension value (e.g., service name)")
  dimension: string;

  @doc("Span count for this dimension")
  count: Count;

  @doc("Average duration in nanoseconds")
  @encodedName("application/json", "avg_duration_ns")
  avgDurationNs: float64;

  @doc("Error rate for this dimension")
  @encodedName("application/json", "error_rate")
  errorRate: Ratio;
}
