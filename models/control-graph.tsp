// =============================================================================
// ANcpLua v2.0 - Telemetry Control Graph v1
// =============================================================================
// The declared shape of qyl's telemetry: which service emits which signals
// with which attributes, and where they are exported. The graph is the single
// source the conformance verifier (qyl/internal/qyl.conformance) diffs reality
// against: the graph declares, the collector must conform. Exporter
// configuration is GENERATED from this graph only after the verifier reports
// conformance; it is never hand-authored.
// =============================================================================

import "@typespec/openapi";
import "@typespec/json-schema";
import "../common/types.tsp";
import "./configurator.tsp";

using TypeSpec.OpenAPI;
using TypeSpec.JsonSchema;
using Qyl.Api.Contracts.Common;
using Qyl.Api.Contracts.Domains.Configurator;

@jsonSchema
namespace Qyl.Api.Contracts.Domains.ControlGraph;

@doc("Telemetry signal kind a service can declare")
enum TelemetrySignalKind {
  @doc("Trace span")
  span: "span",

  @doc("Metric instrument")
  metric: "metric",

  @doc("Log record")
  log: "log",

  @doc("Continuous profile")
  profile: "profile",
}

@doc("Requirement level of a declared attribute (mirrors semconv requirement levels)")
enum AttributeRequirement {
  @doc("Must be present on every emission; absence is a conformance error")
  required: "required",

  @doc("Should be present; absence is a conformance warning")
  recommended: "recommended",

  @doc("May be present; never a finding")
  optIn: "opt_in",
}

@doc("A single attribute a service declares on a signal. Keys are verbatim semconv keys (otel-keys.gen) or qyl-registry keys ('qyl.'/'ancplua.' prefix) — enforced by otelconventions-lint.")
model DeclaredAttribute {
  @doc("Attribute key (dot-separated namespace, e.g. 'http.request.method' or 'qyl.session.id')")
  @minLength(1)
  key: string;

  @doc("Requirement level")
  requirement: AttributeRequirement = AttributeRequirement.recommended;
}

@doc("A signal a service declares it emits")
model DeclaredSignal {
  @doc("Signal kind")
  kind: TelemetrySignalKind;

  @doc("Signal name (span name pattern, metric instrument name, or log event name)")
  @minLength(1)
  name: string;

  @doc("Attributes declared on this signal")
  attributes: DeclaredAttribute[] = #[];
}

@doc("Wire protocol of an export edge")
enum ExportProtocol {
  @doc("OTLP over gRPC")
  otlpGrpc: "otlp_grpc",

  @doc("OTLP over HTTP/protobuf")
  otlpHttp: "otlp_http",
}

@doc("An edge from a service to an export target. Carries the ENV VAR NAME holding the endpoint, never the endpoint value — the graph is a contract, not a config store.")
model ExportEdge {
  @doc("Stable exporter identifier, unique per service (e.g. 'collector-primary')")
  @minLength(1)
  @encodedName("application/json", "exporter_id")
  exporterId: string;

  @doc("Wire protocol")
  protocol: ExportProtocol;

  @doc("Environment variable that resolves the endpoint at runtime (e.g. 'OTEL_EXPORTER_OTLP_ENDPOINT')")
  @minLength(1)
  @encodedName("application/json", "endpoint_env_var")
  endpointEnvVar: string;

  @doc("Signal kinds routed over this edge")
  @minItems(1)
  signals: TelemetrySignalKind[];
}

@doc("Typed projection of the generation profile key — stays in sync with the entity via TypeSpec 1.13 constraint-based member resolution instead of duplicating the key type.")
internal model GraphProfileBinding<P extends GenerationProfileEntity> {
  @doc("Generation profile this service's instrumentation is generated from")
  @encodedName("application/json", "profile_id")
  profileId: P.id;
}

@doc("A service node: what one service declares it emits and where it exports")
model ServiceNode {
  @doc("Logical service name — must equal the value of the OTel resource attribute 'service.name' the service emits")
  @minLength(1)
  @encodedName("application/json", "service_name")
  serviceName: string;

  ...GraphProfileBinding<GenerationProfileEntity>;

  @doc("Signals this service declares")
  declares: DeclaredSignal[];

  @doc("Export edges for this service")
  exports: ExportEdge[];
}

@doc("Telemetry Control Graph: the declared telemetry surface of a qyl deployment. Instances are emitted as YAML (review) and JSON (verifier input) by @qyl/telemetry-control-graph.")
model TelemetryControlGraph {
  @doc("Graph schema version")
  @encodedName("application/json", "schema_version")
  schemaVersion: "1";

  @doc("Service nodes")
  services: ServiceNode[];
}

@doc("Kind of a conformance finding produced by the runtime verifier")
enum ConformanceFindingKind {
  @doc("Telemetry observed that no service node declares")
  undeclaredEmitted: "undeclared_emitted",

  @doc("Declared signal never observed in the verification window")
  declaredMissing: "declared_missing",

  @doc("Observed attributes drift from the declaration (missing required key, unknown key)")
  attributeDrift: "attribute_drift",
}

@doc("Severity of a conformance finding")
enum ConformanceSeverity {
  @doc("Violates the graph; blocks exporter-config generation")
  error: "error",

  @doc("Drift worth reviewing; does not block")
  warning: "warning",
}

@doc("A single declared-vs-observed difference")
model ConformanceFinding {
  @doc("Finding kind")
  kind: ConformanceFindingKind;

  @doc("Severity")
  severity: ConformanceSeverity;

  @doc("Service the finding concerns")
  @encodedName("application/json", "service_name")
  serviceName: string;

  @doc("Signal kind, when the finding is signal-scoped")
  @encodedName("application/json", "signal_kind")
  signalKind?: TelemetrySignalKind;

  @doc("Signal name, when the finding is signal-scoped")
  @encodedName("application/json", "signal_name")
  signalName?: string;

  @doc("Attribute key, when the finding is attribute-scoped")
  @encodedName("application/json", "attribute_key")
  attributeKey?: string;

  @doc("Human-readable detail")
  detail: string;
}

@doc("Result of one verifier run: the graph diffed against observed telemetry. 'conformant' (no error findings) is the gate for exporter-config generation.")
model ConformanceReport {
  @doc("schema_version of the verified graph")
  @encodedName("application/json", "graph_schema_version")
  graphSchemaVersion: string;

  @doc("All findings (empty means fully conformant)")
  findings: ConformanceFinding[];

  @doc("True when no error-severity findings exist")
  conformant: boolean;
}
