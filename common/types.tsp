// =============================================================================
// qyl common types and scalars
// =============================================================================
// Foundational types used across qyl API contracts and OTel-compatible models.
// OpenTelemetry semantic-convention references are pinned to v1.41.0.
// =============================================================================

import "@typespec/versioning";
import "@typespec/json-schema";
import "@typespec/openapi";

using TypeSpec.Versioning;
using TypeSpec.JsonSchema;
using TypeSpec.OpenAPI;

namespace Qyl.Api.Contracts.Common;

// =============================================================================
// Version Enum - OTel Semantic Convention Versions
// =============================================================================

@doc("OpenTelemetry semantic-convention versions supported by qyl compatibility models")
enum OTelVersion {
  @doc("OTel Semconv v1.27 - Base version")
  v1_27: "1.27.0",

  @doc("OTel Semconv v1.28 - GenAI additions")
  v1_28: "1.28.0",

  @doc("OTel Semconv v1.29 - HTTP improvements")
  v1_29: "1.29.0",

  @doc("OTel Semconv v1.30 - Database updates")
  v1_30: "1.30.0",

  @doc("OTel Semconv v1.38 - GenAI.Agent support")
  v1_38: "1.38.0",

  @doc("OTel Semconv v1.39 - RPC metadata consolidation")
  v1_39: "1.39.0",

  @doc("OTel Semconv v1.40 - Oracle DB split, RPC cleanup, GenAI cache tokens")
  v1_40: "1.40.0",

  @doc("OTel Semconv v1.41 - Current compatibility pin")
  v1_41: "1.41.0",
}

// =============================================================================
// Identifier Scalars - Strongly Typed IDs
// =============================================================================

@jsonSchema
@doc("Unique trace identifier (32 lowercase hex characters)")
@pattern("^[a-f0-9]{32}$")
@minLength(32)
@maxLength(32)
@example("0af7651916cd43dd8448eb211c80319c")
@TypeSpec.OpenAPI.extension("x-csharp-struct", true)
@TypeSpec.OpenAPI.extension("x-csharp-type", "TraceId")
scalar TraceId extends string;

@jsonSchema
@doc("Unique span identifier (16 lowercase hex characters)")
@pattern("^[a-f0-9]{16}$")
@minLength(16)
@maxLength(16)
@example("b7ad6b7169203331")
@TypeSpec.OpenAPI.extension("x-csharp-struct", true)
@TypeSpec.OpenAPI.extension("x-csharp-type", "SpanId")
scalar SpanId extends string;

@jsonSchema
@doc("W3C Trace Context traceparent header format")
@pattern("^[0-9a-f]{2}-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$")
@example("00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01")
scalar TraceParent extends string;

@jsonSchema
@doc("W3C Trace Context tracestate header (vendor-specific key-value pairs)")
@example("rojo=00f067aa0ba902b7,congo=t61rcWkgMzE")
scalar TraceState extends string;

@jsonSchema
@doc("Unique session identifier")
@minLength(1)
@maxLength(128)
@TypeSpec.OpenAPI.extension("x-csharp-struct", true)
@TypeSpec.OpenAPI.extension("x-csharp-type", "SessionId")
scalar SessionId extends string;

@jsonSchema
@doc("User identifier (pseudonymized for privacy)")
@minLength(1)
@maxLength(256)
scalar UserId extends string;

// =============================================================================
// Temporal Scalars - Timestamps & Durations
// =============================================================================

@jsonSchema
@doc("ISO 8601 timestamp with nanosecond precision (RFC 3339)")
@encode(DateTimeKnownEncoding.rfc3339)
scalar Timestamp extends utcDateTime;

@jsonSchema
@doc("Unix timestamp in nanoseconds since epoch")
@encode(DateTimeKnownEncoding.unixTimestamp, int64)
@TypeSpec.OpenAPI.extension("x-csharp-struct", true)
@TypeSpec.OpenAPI.extension("x-csharp-type", "UnixNano")
scalar UnixNanos extends utcDateTime;

@jsonSchema
@doc("Duration in nanoseconds")
@minValue(0)
@TypeSpec.OpenAPI.extension("x-csharp-type", "long")
scalar DurationNs extends int64;

@jsonSchema
@doc("Duration in milliseconds")
@minValue(0)
@TypeSpec.OpenAPI.extension("x-csharp-type", "double")
scalar DurationMs extends float64;

@jsonSchema
@doc("Duration in seconds")
@minValue(0)
scalar DurationS extends float64;

@jsonSchema
@doc("ISO 8601 duration format (e.g., PT1H30M)")
@encode(DurationKnownEncoding.ISO8601)
scalar IsoDuration extends duration;

// =============================================================================
// Network Scalars - IP Addresses & Ports
// =============================================================================

@jsonSchema
@doc("IPv4 address in dotted-decimal notation")
@pattern("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")
@example("192.168.1.1")
scalar IPv4Address extends string;

@jsonSchema
@doc("IPv6 address in standard notation")
@example("2001:0db8:85a3:0000:0000:8a2e:0370:7334")
scalar IPv6Address extends string;

@jsonSchema
@doc("IP address (IPv4 or IPv6)")
scalar IpAddress extends string;

@jsonSchema
@doc("Network port number (1-65535)")
@minValue(1)
@maxValue(65535)
@TypeSpec.OpenAPI.extension("x-csharp-type", "int")
scalar Port extends int32;

@jsonSchema
@doc("MAC address in colon-separated hex notation")
@pattern("^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$")
@example("00:1A:2B:3C:4D:5E")
scalar MacAddress extends string;

// =============================================================================
// Size & Count Scalars
// =============================================================================

@jsonSchema
@doc("Size in bytes")
@minValue(0)
@TypeSpec.OpenAPI.extension("x-csharp-type", "long")
scalar ByteSize extends int64;

@jsonSchema
@doc("Token count (for LLM operations)")
@minValue(0)
@TypeSpec.OpenAPI.extension("x-csharp-type", "long")
scalar TokenCount extends int64;

@jsonSchema
@doc("Generic non-negative counter")
@minValue(0)
@TypeSpec.OpenAPI.extension("x-csharp-type", "long")
scalar Count extends int64;

@jsonSchema
@doc("Percentage value (0.0 to 100.0)")
@minValue(0.0)
@maxValue(100.0)
@TypeSpec.OpenAPI.extension("x-csharp-type", "double")
scalar Percentage extends float64;

@jsonSchema
@doc("Ratio value (0.0 to 1.0)")
@minValue(0.0)
@maxValue(1.0)
@TypeSpec.OpenAPI.extension("x-csharp-type", "double")
scalar Ratio extends float64;

// =============================================================================
// GenAI-Specific Scalars
// =============================================================================

@jsonSchema
@doc("Cost in USD (floating point)")
@minValue(0)
@TypeSpec.OpenAPI.extension("x-csharp-type", "double")
scalar CostUsd extends float64;

@jsonSchema
@doc("Temperature setting for LLM requests (0.0-2.0)")
@minValue(0)
@maxValue(2)
@TypeSpec.OpenAPI.extension("x-csharp-type", "double")
scalar Temperature extends float64;

// =============================================================================
// Semantic Scalars - Special Purpose Types
// =============================================================================

@jsonSchema
@doc("SHA-256 hash in lowercase hex")
@pattern("^[a-f0-9]{64}$")
@minLength(64)
@maxLength(64)
scalar Sha256Hash extends string;

@jsonSchema
@doc("Semantic version string (e.g., 1.2.3)")
@pattern("^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$")
@example("2.1.0")
scalar SemVer extends string;

@jsonSchema
@doc("URL string (absolute)")
@format("uri")
scalar UrlString extends string;

@jsonSchema
@doc("URL path component")
@example("/api/v1/users")
scalar UrlPath extends string;

@jsonSchema
@doc("URL query string (without leading ?)")
@example("page=1&limit=100")
scalar UrlQuery extends string;

@jsonSchema
@doc("HTTP method name (uppercase)")
@example("GET")
scalar HttpMethod extends string;

@jsonSchema
@doc("MIME content type")
@example("application/json")
scalar ContentType extends string;

@jsonSchema
@doc("User agent string")
@example("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
scalar UserAgent extends string;

@jsonSchema
@doc("Language/locale code (BCP 47)")
@pattern("^[a-z]{2,3}(-[A-Z]{2})?$")
@example("en-US")
scalar LanguageCode extends string;

// =============================================================================
// OpenTelemetry Attribute Value Types
// =============================================================================

@doc("Primitive attribute value types supported by OpenTelemetry")
union AttributeValue {
  @doc("String value")
  stringValue: string,

  @doc("Boolean value")
  boolValue: boolean,

  @doc("64-bit integer value")
  intValue: int64,

  @doc("64-bit floating point value")
  doubleValue: float64,

  @doc("Array of strings")
  stringArrayValue: string[],

  @doc("Array of booleans")
  boolArrayValue: boolean[],

  @doc("Array of integers")
  intArrayValue: int64[],

  @doc("Array of doubles")
  doubleArrayValue: float64[],

  @doc("Bytes value (base64 encoded)")
  bytesValue: bytes,
}

@doc("Key-value attribute pair following OTel conventions")
model Attribute {
  @doc("Attribute key (dot-separated namespace)")
  @minLength(1)
  @maxLength(256)
  key: string;

  @doc("Attribute value")
  value: AttributeValue;
}

@doc("Collection of attributes")
model Attributes {
  @doc("List of key-value attributes")
  items: Attribute[];
}

// =============================================================================
// Instrumentation Scope
// =============================================================================

@doc("Instrumentation scope identifying the library/component emitting telemetry")
model InstrumentationScope {
  @doc("Name of the instrumentation scope (library name)")
  @encodedName("application/json", "name")
  scopeName: string;

  @doc("Version of the instrumentation scope")
  @encodedName("application/json", "version")
  scopeVersion?: SemVer;

  @doc("Additional attributes for the scope")
  @encodedName("application/json", "attributes")
  scopeAttributes?: Attribute[];

  @doc("Dropped attributes count")
  @encodedName("application/json", "dropped_attributes_count")
  droppedAttributesCount?: Count;
}
