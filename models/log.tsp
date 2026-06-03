// =============================================================================
// ANcpLua v2.0 - Log Semantic Conventions (OTel v1.40)
// =============================================================================
// Log record attributes and log-specific semantic conventions.
// =============================================================================

import "../otel/enums.tsp";

using Qyl.Api.Contracts.OTel.Enums;

namespace Qyl.Api.Contracts.Domains.Observe.Log;

// =============================================================================
// Log Attributes
// =============================================================================

@doc("Log record attributes")
model LogAttributes {
  @doc("Log record unique identifier")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Log.RecordUid)
  recordUid?: string;

  @doc("Original log file name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Log.FileName)
  fileName?: string;

  @doc("Full path to log file")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Log.FilePath)
  filePath?: string;

  @doc("Original log file name resolved")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Log.FileNameResolved)
  fileNameResolved?: string;

  @doc("Full path to log file resolved")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Log.FilePathResolved)
  filePathResolved?: string;

  @doc("Log iostream (stdout/stderr)")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Log.Iostream)
  iostream?: LogIostream;
}

@doc("Log IO streams")
enum LogIostream {
  @doc("Standard output")
  stdout: "stdout",

  @doc("Standard error")
  stderr: "stderr",
}

// =============================================================================
// Event Attributes
// =============================================================================

@doc("Event domain for event.name categorization")
enum EventDomain {
  @doc("Browser events")
  browser: "browser",

  @doc("Device events")
  device: "device",

  @doc("Kubernetes events")
  k8s: "k8s",

  @doc("User events")
  user: "user",

  @doc("Session events")
  session: "session",

  @doc("Application events")
  app: "app",

  @doc("Feature flag events")
  featureFlag: "feature_flag",

  @doc("Deployment events")
  deployment: "deployment",

  @doc("CI/CD events")
  cicd: "cicd",
}

@doc("Log event attributes")
model EventAttributes {
  @doc("Event name (with domain prefix)")
  @encodedName("application/json", "event.name")
  name: string;

  @doc("Event domain")
  @encodedName("application/json", "event.domain")
  domain?: EventDomain;
}

// =============================================================================
// Log Severity Mapping
// =============================================================================

@doc("Log severity text to number mapping")
model SeverityMapping {
  @doc("Severity text")
  text: string;

  @doc("Severity number (1-24)")
  number: SeverityNumber;
}

// =============================================================================
// Structured Log Format
// =============================================================================

@doc("Structured log format detection")
enum StructuredLogFormat {
  @doc("JSON format")
  json: "json",

  @doc("Logfmt format")
  logfmt: "logfmt",

  @doc("Apache Common Log Format")
  clf: "clf",

  @doc("Apache Combined Log Format")
  combined: "combined",

  @doc("Syslog format")
  syslog: "syslog",

  @doc("W3C Extended Log Format")
  w3c: "w3c",

  @doc("CSV format")
  csv: "csv",

  @doc("Unstructured/plaintext")
  plaintext: "plaintext",
}
