// =============================================================================
// ANcpLua v2.0 - OpenTelemetry Metrics Model
// =============================================================================
// Metrics data model with discriminated unions for different metric types.
// =============================================================================

import "@typespec/http";
import "../common/types.tsp";
import "./enums.tsp";
import "./resource.tsp";

using TypeSpec.Http;
using Qyl.Api.Contracts.Common;
using Qyl.Api.Contracts.OTel.Enums;
using Qyl.Api.Contracts.OTel.Resource;

namespace Qyl.Api.Contracts.OTel.Metrics;

// =============================================================================
// Metric Model
// =============================================================================

@doc("OpenTelemetry Metric containing measurement data")
model Metric {
  @doc("Metric name (e.g., http.server.request.duration)")
  @minLength(1)
  name: string;

  @doc("Metric description")
  description?: string;

  @doc("Metric unit (e.g., 's', 'By', '1')")
  unit?: string;

  @doc("Metric data (discriminated by type)")
  data: MetricData;

  @doc("Metric metadata attributes")
  metadata?: Attribute[];

  @doc("Resource describing the entity that produced this metric")
  resource: Qyl.Api.Contracts.OTel.Resource.Resource;

  @doc("Instrumentation scope")
  @encodedName("application/json", "instrumentation_scope")
  instrumentationScope?: InstrumentationScope;
}

// =============================================================================
// Metric Data Types (Discriminated Union)
// =============================================================================

@doc("Metric data discriminated by type")
@discriminator("type")
model MetricData {
  @doc("Metric type discriminator")
  type: MetricType;
}

@doc("Gauge metric - instantaneous value at a point in time")
model GaugeData extends MetricData {
  /** Discriminator identifying this as gauge metric data */
  type: MetricType.gauge;

  @doc("Gauge data points")
  @encodedName("application/json", "data_points")
  dataPoints: NumberDataPoint[];
}

@doc("Sum metric - cumulative or delta counter")
model SumData extends MetricData {
  /** Discriminator identifying this as sum metric data */
  type: MetricType.sum;

  @doc("Sum data points")
  @encodedName("application/json", "data_points")
  dataPoints: NumberDataPoint[];

  @doc("Whether the sum is monotonically increasing")
  @encodedName("application/json", "is_monotonic")
  isMonotonic: boolean;

  @doc("Aggregation temporality")
  @encodedName("application/json", "aggregation_temporality")
  aggregationTemporality: AggregationTemporality;
}

@doc("Histogram metric - distribution of values in buckets")
model HistogramData extends MetricData {
  /** Discriminator identifying this as histogram metric data */
  type: MetricType.histogram;

  @doc("Histogram data points")
  @encodedName("application/json", "data_points")
  dataPoints: HistogramDataPoint[];

  @doc("Aggregation temporality")
  @encodedName("application/json", "aggregation_temporality")
  aggregationTemporality: AggregationTemporality;
}

@doc("Exponential histogram metric - distribution with exponential bucket boundaries")
model ExponentialHistogramData extends MetricData {
  /** Discriminator identifying this as exponential histogram metric data */
  type: MetricType.exponentialHistogram;

  @doc("Exponential histogram data points")
  @encodedName("application/json", "data_points")
  dataPoints: ExponentialHistogramDataPoint[];

  @doc("Aggregation temporality")
  @encodedName("application/json", "aggregation_temporality")
  aggregationTemporality: AggregationTemporality;
}

@doc("Summary metric - pre-aggregated quantile distribution")
model SummaryData extends MetricData {
  /** Discriminator identifying this as summary metric data */
  type: MetricType.summary;

  @doc("Summary data points")
  @encodedName("application/json", "data_points")
  dataPoints: SummaryDataPoint[];
}

// =============================================================================
// Data Point Models
// =============================================================================

@doc("Base data point with common fields")
model DataPointBase {
  @doc("Start timestamp in nanoseconds since epoch")
  @encodedName("application/json", "start_time_unix_nano")
  startTimeUnixNano: UnixNanos;

  @doc("End timestamp in nanoseconds since epoch")
  @encodedName("application/json", "time_unix_nano")
  timeUnixNano: UnixNanos;

  @doc("Data point attributes")
  attributes?: Attribute[];

  @doc("Data point flags")
  flags?: DataPointFlags;
}

@doc("Numeric data point (for Gauge and Sum)")
model NumberDataPoint extends DataPointBase {
  @doc("Value as integer")
  @encodedName("application/json", "as_int")
  asInt?: int64;

  @doc("Value as double")
  @encodedName("application/json", "as_double")
  asDouble?: float64;

  @doc("Exemplars for the data point")
  exemplars?: Exemplar[];
}

@doc("Histogram data point")
model HistogramDataPoint extends DataPointBase {
  @doc("Number of values in the histogram")
  count: int64;

  @doc("Sum of all values")
  sum?: float64;

  @doc("Bucket counts")
  @encodedName("application/json", "bucket_counts")
  bucketCounts: int64[];

  @doc("Explicit bucket boundaries")
  @encodedName("application/json", "explicit_bounds")
  explicitBounds: float64[];

  @doc("Minimum value")
  min?: float64;

  @doc("Maximum value")
  max?: float64;

  @doc("Exemplars for the data point")
  exemplars?: Exemplar[];
}

@doc("Exponential histogram data point")
model ExponentialHistogramDataPoint extends DataPointBase {
  @doc("Number of values")
  count: int64;

  @doc("Sum of all values")
  sum?: float64;

  @doc("Scale factor for bucket boundaries")
  scale: int32;

  @doc("Zero count")
  @encodedName("application/json", "zero_count")
  zeroCount: int64;

  @doc("Zero threshold")
  @encodedName("application/json", "zero_threshold")
  zeroThreshold?: float64;

  @doc("Positive bucket counts")
  positive: ExponentialBuckets;

  @doc("Negative bucket counts")
  negative: ExponentialBuckets;

  @doc("Minimum value")
  min?: float64;

  @doc("Maximum value")
  max?: float64;

  @doc("Exemplars for the data point")
  exemplars?: Exemplar[];
}

@doc("Exponential histogram buckets")
model ExponentialBuckets {
  @doc("Offset of the first bucket")
  offset: int32;

  @doc("Bucket counts")
  @encodedName("application/json", "bucket_counts")
  bucketCounts: int64[];
}

@doc("Summary data point")
model SummaryDataPoint extends DataPointBase {
  @doc("Number of values")
  count: int64;

  @doc("Sum of all values")
  sum: float64;

  @doc("Quantile values")
  @encodedName("application/json", "quantile_values")
  quantileValues: QuantileValue[];
}

@doc("Quantile value for summary")
model QuantileValue {
  @doc("Quantile (0.0 to 1.0)")
  @minValue(0.0)
  @maxValue(1.0)
  quantile: float64;

  @doc("Value at this quantile")
  value: float64;
}

@doc("Exemplar - sample trace linked to metric")
model Exemplar {
  @doc("Timestamp in nanoseconds since epoch")
  @encodedName("application/json", "time_unix_nano")
  timeUnixNano: UnixNanos;

  @doc("Value as integer")
  @encodedName("application/json", "as_int")
  asInt?: int64;

  @doc("Value as double")
  @encodedName("application/json", "as_double")
  asDouble?: float64;

  @doc("Span ID of the exemplar")
  @encodedName("application/json", "span_id")
  spanId?: SpanId;

  @doc("Trace ID of the exemplar")
  @encodedName("application/json", "trace_id")
  traceId?: TraceId;

  @doc("Filtered attributes")
  @encodedName("application/json", "filtered_attributes")
  filteredAttributes?: Attribute[];
}

// =============================================================================
// Metric Query & Aggregation
// =============================================================================

@doc("Metric query filters")
model MetricQueryFilters {
  @doc("Filter by metric name (supports wildcards)")
  @query
  name?: string;

  @doc("Filter by metric type")
  @query
  type?: MetricType;

  @doc("Filter by service name")
  @query
  @encodedName("application/json", "service_name")
  serviceName?: string;

  @doc("Filter by attribute key-value pair")
  @query
  attribute?: string;

  @doc("Aggregation function")
  @query
  @encodedName("application/json", "agg_func")
  aggFunc?: AggregationFunction;
}

@doc("Aggregation functions for metrics")
enum AggregationFunction {
  @doc("Sum of values")
  sum: "sum",

  @doc("Average of values")
  avg: "avg",

  @doc("Minimum value")
  min: "min",

  @doc("Maximum value")
  max: "max",

  @doc("Count of values")
  count: "count",

  @doc("Latest value")
  last: "last",

  @doc("Rate of change per second")
  rate: "rate",

  @doc("Increase over time range")
  increase: "increase",
}

@doc("Time series data for graphing")
model TimeSeries {
  @doc("Metric name")
  metric: string;

  @doc("Dimension labels")
  labels: Attribute[];

  @doc("Data points over time")
  points: TimeSeriesPoint[];
}

@doc("Single point in a time series")
model TimeSeriesPoint {
  @doc("Timestamp")
  timestamp: utcDateTime;

  @doc("Value")
  value: float64;
}
