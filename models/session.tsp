// =============================================================================
// ANcpLua v2.0 - Session Semantic Conventions (OTel v1.40)
// =============================================================================
// User session telemetry attributes.
// =============================================================================

import "@typespec/openapi";
import "../common/types.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;

namespace Qyl.Api.Contracts.Domains.Observe.Session;

// =============================================================================
// Session Attributes
// =============================================================================

@doc("Session span/event attributes")
model SessionAttributes {
  @doc("Session ID")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Session.Id)
  id: SessionId;

  @doc("Previous session ID (for session continuity)")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Session.PreviousId)
  previousId?: SessionId;
}

// =============================================================================
// Session Event Models
// =============================================================================

@doc("Session lifecycle event")
model SessionEvent {
  @doc("Event name")
  @encodedName("application/json", "event.name")
  eventName: SessionEventName;

  @doc("Session ID")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Session.Id)
  sessionId: SessionId;

  @doc("Event timestamp")
  timestamp: utcDateTime;

  @doc("Event domain")
  @encodedName("application/json", "event.domain")
  eventDomain: "session";
}

@doc("Session event names")
enum SessionEventName {
  @doc("Session started")
  sessionStart: "session.start",

  @doc("Session ended")
  sessionEnd: "session.end",
}

// =============================================================================
// Session Entity Model (Full Session Record)
// =============================================================================

@doc("Complete session entity with aggregated data")
@TypeSpec.OpenAPI.extension("x-csharp-type", "SessionEntity")
model SessionEntity {
  @doc("Session ID")
  @key
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Session.Id)
  sessionId: SessionId;

  @doc("User ID (if authenticated)")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.User.Id)
  userId?: UserId;

  @doc("Session start time")
  @encodedName("application/json", "start_time")
  startTime: utcDateTime;

  @doc("Session end time")
  @encodedName("application/json", "end_time")
  endTime?: utcDateTime;

  @doc("Session duration in milliseconds")
  @encodedName("application/json", "duration_ms")
  durationMs?: DurationMs;

  @doc("Total trace count in session")
  @encodedName("application/json", "trace_count")
  @minValue(0)
  traceCount: int32;

  @doc("Total span count in session")
  @encodedName("application/json", "span_count")
  @minValue(0)
  spanCount: int32;

  @doc("Total error count in session")
  @encodedName("application/json", "error_count")
  @minValue(0)
  errorCount: int32;

  @doc("Service names observed in this session")
  services: string[];

  @doc("Session state")
  state: SessionState;

  @doc("Client information")
  client?: SessionClientInfo;

  @doc("Location information")
  geo?: SessionGeoInfo;

  @doc("GenAI usage summary")
  @encodedName("application/json", "genai_usage")
  genaiUsage?: SessionGenAiUsage;
}

@doc("Session states")
enum SessionState {
  @doc("Session is active")
  active: "active",

  @doc("Session is idle")
  idle: "idle",

  @doc("Session has ended normally")
  ended: "ended",

  @doc("Session has timed out")
  timedOut: "timed_out",

  @doc("Session was invalidated")
  invalidated: "invalidated",
}

@doc("Session client information")
model SessionClientInfo {
  @doc("Client IP address")
  ip?: IpAddress;

  @doc("User agent string")
  @encodedName("application/json", "user_agent")
  userAgent?: UserAgent;

  @doc("Device type")
  @encodedName("application/json", "device_type")
  deviceType?: DeviceType;

  @doc("Operating system")
  os?: string;

  @doc("Browser name")
  browser?: string;

  @doc("Browser version")
  @encodedName("application/json", "browser_version")
  browserVersion?: string;
}

@doc("Device types")
enum DeviceType {
  @doc("Desktop computer")
  desktop: "desktop",

  @doc("Mobile phone")
  mobile: "mobile",

  @doc("Tablet device")
  tablet: "tablet",

  @doc("TV or set-top box")
  tv: "tv",

  @doc("Gaming console")
  console: "console",

  @doc("Wearable device")
  wearable: "wearable",

  @doc("IoT device")
  iot: "iot",

  @doc("Bot/crawler")
  bot: "bot",

  @doc("Unknown device")
  `unknown`: "unknown",
}

@doc("Session geographic information")
model SessionGeoInfo {
  @doc("Country code (ISO 3166-1 alpha-2)")
  @encodedName("application/json", "country_code")
  countryCode?: string;

  @doc("Country name")
  @encodedName("application/json", "country_name")
  countryName?: string;

  @doc("Region/state")
  region?: string;

  @doc("City")
  city?: string;

  @doc("Postal code")
  @encodedName("application/json", "postal_code")
  postalCode?: string;

  @doc("Timezone")
  timezone?: string;
}

@doc("Session GenAI usage summary")
model SessionGenAiUsage {
  @doc("Total GenAI requests in session")
  @encodedName("application/json", "request_count")
  @minValue(0)
  requestCount: int32;

  @doc("Total input tokens consumed")
  @encodedName("application/json", "total_input_tokens")
  totalInputTokens: TokenCount;

  @doc("Total output tokens generated")
  @encodedName("application/json", "total_output_tokens")
  totalOutputTokens: TokenCount;

  @doc("Models used in session")
  @encodedName("application/json", "models_used")
  modelsUsed: string[];

  @doc("Providers used in session")
  @encodedName("application/json", "providers_used")
  providersUsed: string[];

  @doc("Estimated cost in USD")
  @encodedName("application/json", "estimated_cost_usd")
  estimatedCostUsd?: float64;
}

// =============================================================================
// Session Statistics
// =============================================================================

@doc("Aggregated session statistics")
model SessionStats {
  @doc("Active sessions count")
  @encodedName("application/json", "active_sessions")
  activeSessions: Count;

  @doc("Total sessions in time range")
  @encodedName("application/json", "total_sessions")
  totalSessions: Count;

  @doc("Unique users in time range")
  @encodedName("application/json", "unique_users")
  uniqueUsers: Count;

  @doc("Average session duration in milliseconds")
  @encodedName("application/json", "avg_duration_ms")
  avgDurationMs: float64;

  @doc("Sessions with errors")
  @encodedName("application/json", "sessions_with_errors")
  sessionsWithErrors: Count;

  @doc("Sessions with GenAI usage")
  @encodedName("application/json", "sessions_with_genai")
  sessionsWithGenAi: Count;

  @doc("Bounce rate (single-page sessions)")
  @encodedName("application/json", "bounce_rate")
  bounceRate: Ratio;

  @doc("Sessions by device type")
  @encodedName("application/json", "by_device_type")
  byDeviceType?: SessionDeviceStats[];

  @doc("Sessions by country")
  @encodedName("application/json", "by_country")
  byCountry?: SessionCountryStats[];
}

@doc("Session stats by device type")
model SessionDeviceStats {
  @doc("Device type")
  @encodedName("application/json", "device_type")
  deviceType: DeviceType;

  @doc("Session count")
  count: Count;

  @doc("Percentage of total")
  percentage: Percentage;
}

@doc("Session stats by country")
model SessionCountryStats {
  @doc("Country code")
  @encodedName("application/json", "country_code")
  countryCode: string;

  @doc("Country name")
  @encodedName("application/json", "country_name")
  countryName: string;

  @doc("Session count")
  count: Count;

  @doc("Percentage of total")
  percentage: Percentage;
}
