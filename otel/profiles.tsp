// =============================================================================
// ANcpLua v2.0 - OpenTelemetry Profiles Model (v1development)
// =============================================================================
// Continuous profiling signal following OTel Profiles proto specification.
// Proto package: opentelemetry.proto.profiles.v1development
// All attributes are Development stability (semconv v1.39.0-v1.40.0).
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

namespace Qyl.Api.Contracts.OTel.Profiles;

// =============================================================================
// Profile Model
// =============================================================================

@doc("OpenTelemetry Profile representing a continuous profiling snapshot")
model Profile {
  @doc("Unique profile identifier (16 hex chars)")
  @key
  @encodedName("application/json", "profile_id")
  profileId: string;

  @doc("Sample type describing what was measured")
  @encodedName("application/json", "sample_type")
  sampleType?: ProfileValueType;

  @doc("Profiling samples")
  samples?: ProfileSample[];

  @doc("Profile start timestamp in nanoseconds since epoch")
  @encodedName("application/json", "time_unix_nano")
  timeUnixNano: UnixNanos;

  @doc("Profile duration in nanoseconds")
  @encodedName("application/json", "duration_nano")
  durationNano: DurationNs;

  @doc("Sampling period type")
  @encodedName("application/json", "period_type")
  periodType?: ProfileValueType;

  @doc("Sampling period value")
  period?: int64;

  @doc("Original payload format (pprof, jfr, linux_perf)")
  @encodedName("application/json", "original_payload_format")
  originalPayloadFormat?: OriginalPayloadFormat;

  @doc("Original payload bytes (base64 encoded, opaque — not parsed)")
  @encodedName("application/json", "original_payload")
  originalPayload?: bytes;

  @doc("Profile attributes")
  attributes?: Attribute[];

  @doc("Dropped attributes count")
  @encodedName("application/json", "dropped_attributes_count")
  droppedAttributesCount?: Count;

  @doc("Resource describing the entity that produced this profile")
  resource: Qyl.Api.Contracts.OTel.Resource.Resource;

  @doc("Instrumentation scope")
  @encodedName("application/json", "instrumentation_scope")
  instrumentationScope?: InstrumentationScope;

  // Dictionary tables (dereferenced from ProfilesDictionary)

  @doc("String table for index-based lookups")
  @encodedName("application/json", "string_table")
  stringTable?: string[];

  @doc("Function table")
  @encodedName("application/json", "function_table")
  functionTable?: ProfileFunction[];

  @doc("Location table")
  @encodedName("application/json", "location_table")
  locationTable?: ProfileLocation[];

  @doc("Mapping table (memory-mapped binaries)")
  @encodedName("application/json", "mapping_table")
  mappingTable?: ProfileMapping[];

  @doc("Link table for cross-signal correlation")
  @encodedName("application/json", "link_table")
  linkTable?: ProfileLink[];

  @doc("Stack table (ordered location sequences)")
  @encodedName("application/json", "stack_table")
  stackTable?: ProfileStack[];
}

// =============================================================================
// Profile Sub-Models
// =============================================================================

@doc("Sample type descriptor (what was measured and in what unit)")
model ProfileValueType {
  @doc("Type string index into string table")
  @encodedName("application/json", "type_strindex")
  typeStrindex?: int32;

  @doc("Unit string index into string table")
  @encodedName("application/json", "unit_strindex")
  unitStrindex?: int32;
}

@doc("Individual profiling sample")
model ProfileSample {
  @doc("Stack index into stack table")
  @encodedName("application/json", "stack_index")
  stackIndex?: int32;

  @doc("Attribute indices into attribute table")
  @encodedName("application/json", "attribute_indices")
  attributeIndices?: int32[];

  @doc("Link index into link table for cross-signal correlation")
  @encodedName("application/json", "link_index")
  linkIndex?: int32;

  @doc("Sample values (one per sample type)")
  values?: int64[];

  @doc("Timestamps for each value in nanoseconds since epoch")
  @encodedName("application/json", "timestamps_unix_nano")
  timestampsUnixNano?: UnixNanos[];
}

@doc("Code location within a profiled binary")
model ProfileLocation {
  @doc("Mapping index into mapping table")
  @encodedName("application/json", "mapping_index")
  mappingIndex?: int32;

  @doc("Instruction address (program counter)")
  address?: uint64;

  @doc("Source lines at this location")
  lines?: ProfileLine[];

  @doc("Attribute indices")
  @encodedName("application/json", "attribute_indices")
  attributeIndices?: int32[];
}

@doc("Source line within a location")
model ProfileLine {
  @doc("Function index into function table")
  @encodedName("application/json", "function_index")
  functionIndex?: int32;

  @doc("Source line number")
  line?: int64;

  @doc("Source column number")
  column?: int64;
}

@doc("Function identity in a profiled binary")
model ProfileFunction {
  @doc("Function name string index")
  @encodedName("application/json", "name_strindex")
  nameStrindex?: int32;

  @doc("System/mangled function name string index")
  @encodedName("application/json", "system_name_strindex")
  systemNameStrindex?: int32;

  @doc("Source filename string index")
  @encodedName("application/json", "filename_strindex")
  filenameStrindex?: int32;

  @doc("First line number of the function in source")
  @encodedName("application/json", "start_line")
  startLine?: int64;
}

@doc("Memory mapping for a loaded binary or shared library")
model ProfileMapping {
  @doc("Start address of the mapping in virtual memory")
  @encodedName("application/json", "memory_start")
  memoryStart?: uint64;

  @doc("Limit address (exclusive) of the mapping")
  @encodedName("application/json", "memory_limit")
  memoryLimit?: uint64;

  @doc("Offset within the mapped file")
  @encodedName("application/json", "file_offset")
  fileOffset?: uint64;

  @doc("Filename string index of the mapped binary")
  @encodedName("application/json", "filename_strindex")
  filenameStrindex?: int32;

  @doc("Attribute indices")
  @encodedName("application/json", "attribute_indices")
  attributeIndices?: int32[];
}

@doc("Cross-signal link from profile sample to trace/span")
model ProfileLink {
  @doc("Linked trace ID (16 bytes, W3C format)")
  @encodedName("application/json", "trace_id")
  traceId?: TraceId;

  @doc("Linked span ID (8 bytes)")
  @encodedName("application/json", "span_id")
  spanId?: SpanId;
}

@doc("Ordered sequence of location indices forming a call stack")
model ProfileStack {
  @doc("Location indices from leaf (index 0) to root")
  @encodedName("application/json", "location_indices")
  locationIndices?: int32[];
}

// =============================================================================
// Profile Query Filters
// =============================================================================

@doc("Filter parameters for querying profiles")
model ProfileQueryFilters {
  @doc("Filter by trace ID")
  @query
  @encodedName("application/json", "trace_id")
  traceId?: TraceId;

  @doc("Filter by span ID")
  @query
  @encodedName("application/json", "span_id")
  spanId?: SpanId;

  @doc("Filter by session ID")
  @query
  @encodedName("application/json", "session_id")
  sessionId?: SessionId;

  @doc("Filter by service name")
  @query
  @encodedName("application/json", "service_name")
  serviceName?: string;

  @doc("Filter by sample type (e.g., cpu, alloc_objects, wall)")
  @query
  @encodedName("application/json", "sample_type")
  sampleType?: string;

  @doc("Filter by profile frame type (e.g., dotnet, jvm, cpython)")
  @query
  @encodedName("application/json", "profile_frame_type")
  profileFrameType?: string;

  @doc("Filter by original payload format")
  @query
  @encodedName("application/json", "original_payload_format")
  originalPayloadFormat?: OriginalPayloadFormat;

  @doc("Minimum duration in nanoseconds")
  @query
  @encodedName("application/json", "min_duration_nano")
  minDurationNano?: DurationNs;

  @doc("Start of time range (inclusive, ISO 8601)")
  @query
  @encodedName("application/json", "time_from")
  timeFrom?: utcDateTime;

  @doc("End of time range (exclusive, ISO 8601)")
  @query
  @encodedName("application/json", "time_to")
  timeTo?: utcDateTime;
}

// =============================================================================
// Profile Aggregations
// =============================================================================

@doc("Aggregated profile statistics")
model ProfileStats {
  @doc("Total profile count")
  @encodedName("application/json", "total_count")
  totalCount: Count;

  @doc("Total sample count across all profiles")
  @encodedName("application/json", "total_sample_count")
  totalSampleCount: Count;

  @doc("Average duration in nanoseconds")
  @encodedName("application/json", "avg_duration_nano")
  avgDurationNano: float64;

  @doc("Stats grouped by sample type")
  @encodedName("application/json", "by_sample_type")
  bySampleType?: ProfileStatsByDimension[];

  @doc("Stats grouped by service")
  @encodedName("application/json", "by_service")
  byService?: ProfileStatsByDimension[];

  @doc("Stats grouped by frame type")
  @encodedName("application/json", "by_frame_type")
  byFrameType?: ProfileStatsByDimension[];
}

@doc("Profile statistics for a specific dimension value")
model ProfileStatsByDimension {
  @doc("Dimension value")
  dimension: string;

  @doc("Profile count for this dimension")
  count: Count;

  @doc("Total sample count for this dimension")
  @encodedName("application/json", "sample_count")
  sampleCount: Count;

  @doc("Average duration in nanoseconds")
  @encodedName("application/json", "avg_duration_nano")
  avgDurationNano: float64;
}
