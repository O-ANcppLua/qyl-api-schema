// =============================================================================
// ANcpLua v2.0 - OpenTelemetry Log Record Model
// =============================================================================
// Structured logging following OTel log data model.
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

namespace Qyl.Api.Contracts.OTel.Logs;

// =============================================================================
// Log Record Model
// =============================================================================

@doc("OpenTelemetry Log Record")
model LogRecord {
  @doc("Timestamp when the event occurred (nanoseconds since epoch)")
  @encodedName("application/json", "time_unix_nano")
  timeUnixNano: UnixNanos;

  @doc("Timestamp when the log was observed/collected (nanoseconds since epoch)")
  @encodedName("application/json", "observed_time_unix_nano")
  observedTimeUnixNano: UnixNanos;

  @doc("Severity number (1-24)")
  @encodedName("application/json", "severity_number")
  severityNumber: SeverityNumber;

  @doc("Severity text (DEBUG, INFO, WARN, ERROR, etc.)")
  @encodedName("application/json", "severity_text")
  severityText?: SeverityText;

  @doc("Log body - the main content")
  body: LogBody;

  @doc("Log attributes")
  attributes?: Attribute[];

  @doc("Dropped attributes count")
  @encodedName("application/json", "dropped_attributes_count")
  droppedAttributesCount?: Count;

  @doc("Flags (trace flags)")
  flags?: int32;

  @doc("Associated trace ID")
  @encodedName("application/json", "trace_id")
  traceId?: TraceId;

  @doc("Associated span ID")
  @encodedName("application/json", "span_id")
  spanId?: SpanId;

  @doc("Resource describing the entity that produced this log")
  resource: Qyl.Api.Contracts.OTel.Resource.Resource;

  @doc("Instrumentation scope")
  @encodedName("application/json", "instrumentation_scope")
  instrumentationScope?: InstrumentationScope;
}

// =============================================================================
// Log Body Types (Discriminated Union)
// =============================================================================

@doc("Log body content - can be string, structured, or bytes")
@discriminated(#{ envelope: "none" })
union LogBody {
  @doc("Plain string body")
  stringBody: LogBodyString,

  @doc("Structured key-value body")
  kvListBody: LogBodyKvList,

  @doc("Array body")
  arrayBody: LogBodyArray,

  @doc("Binary body")
  bytesBody: LogBodyBytes,
}

@doc("String log body")
model LogBodyString {
  @doc("String value")
  @encodedName("application/json", "string_value")
  stringValue: string;
}

@doc("Structured key-value log body")
model LogBodyKvList {
  @doc("Key-value pairs")
  @encodedName("application/json", "kv_list_value")
  kvListValue: Attribute[];
}

@doc("Array log body")
model LogBodyArray {
  @doc("Array of values")
  @encodedName("application/json", "array_value")
  arrayValue: AttributeValue[];
}

@doc("Binary log body")
model LogBodyBytes {
  @doc("Binary value (base64 encoded)")
  @encodedName("application/json", "bytes_value")
  bytesValue: bytes;
}

// =============================================================================
// Log Query Filters
// =============================================================================

@doc("Filter parameters for querying logs")
model LogQueryFilters {
  @doc("Filter by trace ID")
  @query
  @encodedName("application/json", "trace_id")
  traceId?: TraceId;

  @doc("Filter by span ID")
  @query
  @encodedName("application/json", "span_id")
  spanId?: SpanId;

  @doc("Minimum severity number")
  @query
  @encodedName("application/json", "min_severity")
  minSeverity?: SeverityNumber;

  @doc("Maximum severity number")
  @query
  @encodedName("application/json", "max_severity")
  maxSeverity?: SeverityNumber;

  @doc("Filter by severity text")
  @query
  @encodedName("application/json", "severity_text")
  severityText?: SeverityText;

  @doc("Filter by service name")
  @query
  @encodedName("application/json", "service_name")
  serviceName?: string;

  @doc("Full-text search in body")
  @query
  search?: string;

  @doc("Filter by attribute key-value pair")
  @query
  attribute?: string;
}

// =============================================================================
// Log Aggregations
// =============================================================================

@doc("Aggregated log statistics")
model LogStats {
  @doc("Total log count")
  @encodedName("application/json", "total_count")
  totalCount: Count;

  @doc("Log counts by severity")
  @encodedName("application/json", "by_severity")
  bySeverity: LogCountBySeverity[];

  @doc("Log counts by service")
  @encodedName("application/json", "by_service")
  byService: LogCountByDimension[];

  @doc("Logs per second rate")
  @encodedName("application/json", "logs_per_second")
  logsPerSecond: float64;

  @doc("Error log rate")
  @encodedName("application/json", "error_rate")
  errorRate: Ratio;
}

@doc("Log count by severity level")
model LogCountBySeverity {
  @doc("Severity level")
  severity: SeverityText;

  @doc("Log count")
  count: Count;

  @doc("Percentage of total")
  percentage: Percentage;
}

@doc("Log count by dimension")
model LogCountByDimension {
  @doc("Dimension value")
  dimension: string;

  @doc("Log count")
  count: Count;

  @doc("Error count for this dimension")
  @encodedName("application/json", "error_count")
  errorCount: Count;
}

// =============================================================================
// Structured Log Templates
// =============================================================================

@doc("Log message template with placeholders")
model LogTemplate {
  @doc("Template string with {placeholder} syntax")
  template: string;

  @doc("Template parameters")
  parameters: Attribute[];

  @doc("Rendered message")
  @encodedName("application/json", "rendered_message")
  renderedMessage?: string;
}
