// =============================================================================
// ANcpLua v2.0 - Deployment Semantic Conventions (OTel v1.40)
// =============================================================================
// Deployment/release telemetry attributes.
// =============================================================================

import "@typespec/openapi";
import "../common/types.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;

namespace Qyl.Api.Contracts.Domains.Ops.Deployment;

// =============================================================================
// Deployment Attributes
// =============================================================================

@doc("Deployment resource attributes")
model DeploymentAttributes {
  @doc("Deployment environment name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.EnvironmentName)
  environmentName?: string;

  @doc("Deployment ID")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.Id)
  id?: string;

  @doc("Deployment name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.Name)
  name?: string;

  @doc("Deployment status")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.Status)
  status?: DeploymentStatus;
}

// =============================================================================
// Deployment Enumerations
// =============================================================================

@doc("Deployment environments")
enum DeploymentEnvironment {
  @doc("Development environment")
  development: "development",

  @doc("Testing environment")
  testing: "testing",

  @doc("Staging environment")
  staging: "staging",

  @doc("Production environment")
  production: "production",

  @doc("Preview/ephemeral environment")
  preview: "preview",

  @doc("Canary environment")
  canary: "canary",
}

@doc("Deployment status")
enum DeploymentStatus {
  @doc("Deployment pending")
  pending: "pending",

  @doc("Deployment in progress")
  inProgress: "in_progress",

  @doc("Deployment succeeded")
  success: "success",

  @doc("Deployment failed")
  failed: "failed",

  @doc("Deployment rolled back")
  rolledBack: "rolled_back",

  @doc("Deployment cancelled")
  cancelled: "cancelled",
}

@doc("Deployment strategies")
enum DeploymentStrategy {
  @doc("Rolling update")
  rolling: "rolling",

  @doc("Blue-green deployment")
  blueGreen: "blue_green",

  @doc("Canary deployment")
  canary: "canary",

  @doc("Recreate (stop old, start new)")
  recreate: "recreate",

  @doc("A/B testing deployment")
  abTest: "ab_test",

  @doc("Shadow deployment")
  shadow: "shadow",

  @doc("Feature flag controlled")
  featureFlag: "feature_flag",
}

// =============================================================================
// Deployment Entity Model
// =============================================================================

@doc("Complete deployment record")
@TypeSpec.OpenAPI.extension("x-csharp-type", "DeploymentEntity")
model DeploymentEntity {
  @doc("Deployment ID")
  @key
  @visibility(Lifecycle.Read)
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.Id)
  deploymentId: string;

  @doc("Service name")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Service.Name)
  serviceName: string;

  @doc("Service version")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Service.Version)
  serviceVersion: SemVer;

  @doc("Environment")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  environment: DeploymentEnvironment;

  @doc("Status")
  @visibility(Lifecycle.Read, Lifecycle.Update)
  status: DeploymentStatus;

  @doc("Strategy")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  strategy: DeploymentStrategy;

  @doc("Start time")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "start_time")
  startTime: utcDateTime;

  @doc("End time")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "end_time")
  endTime?: utcDateTime;

  @doc("Duration in seconds")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "duration_s")
  durationS?: DurationS;

  @doc("Deployed by (user/system)")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  @encodedName("application/json", "deployed_by")
  deployedBy?: string;

  @doc("Git commit SHA")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  @encodedName("application/json", "git_commit")
  gitCommit?: string;

  @doc("Git branch")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  @encodedName("application/json", "git_branch")
  gitBranch?: string;

  @doc("Previous version")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "previous_version")
  previousVersion?: SemVer;

  @doc("Rollback target (if rolled back)")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "rollback_target")
  rollbackTarget?: string;

  @doc("Replica count")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "replica_count")
  replicaCount?: int32;

  @doc("Healthy replica count")
  @visibility(Lifecycle.Read, Lifecycle.Update)
  @encodedName("application/json", "healthy_replicas")
  healthyReplicas?: int32;

  @doc("Error message (if failed)")
  @visibility(Lifecycle.Read, Lifecycle.Update)
  @encodedName("application/json", "error_message")
  errorMessage?: string;
}

// =============================================================================
// Deployment Events
// =============================================================================

@doc("Deployment lifecycle event")
model DeploymentEvent {
  @doc("Event name")
  @encodedName("application/json", "event.name")
  eventName: DeploymentEventName;

  @doc("Deployment ID")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.Id)
  deploymentId: string;

  @doc("Service name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Service.Name)
  serviceName: string;

  @doc("Environment")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.EnvironmentName)
  environment: DeploymentEnvironment;

  @doc("Status")
  status: DeploymentStatus;

  @doc("Event timestamp")
  timestamp: utcDateTime;
}

@doc("Deployment event names")
enum DeploymentEventName {
  @doc("Deployment started")
  started: "deployment.started",

  @doc("Deployment completed")
  completed: "deployment.completed",

  @doc("Deployment failed")
  failed: "deployment.failed",

  @doc("Deployment rolled back")
  rolledBack: "deployment.rolled_back",

  @doc("Health check passed")
  healthCheckPassed: "deployment.health_check.passed",

  @doc("Health check failed")
  healthCheckFailed: "deployment.health_check.failed",
}

// =============================================================================
// Deployment Metrics
// =============================================================================

@doc("Deployment duration metric")
model DeploymentDurationMetric {
  @doc("Metric name")
  name: "deployment.duration";

  @doc("Metric unit (seconds)")
  unit: "s";

  @doc("Environment")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.EnvironmentName)
  environment: DeploymentEnvironment;

  @doc("Service name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Service.Name)
  serviceName: string;

  @doc("Status")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.Status)
  status: DeploymentStatus;
}

@doc("Deployment count metric")
model DeploymentCountMetric {
  @doc("Metric name")
  name: "deployment.count";

  @doc("Metric unit")
  unit: "{deployment}";

  @doc("Environment")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.EnvironmentName)
  environment: DeploymentEnvironment;

  @doc("Service name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Service.Name)
  serviceName: string;

  @doc("Status")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.Status)
  status: DeploymentStatus;
}

// =============================================================================
// DORA Metrics
// =============================================================================

@doc("DORA deployment frequency metric")
model DoraDeploymentFrequencyMetric {
  @doc("Metric name")
  name: "dora.deployment_frequency";

  @doc("Metric unit (deployments per day)")
  unit: "{deployment}/d";

  @doc("Environment")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.EnvironmentName)
  environment: DeploymentEnvironment;

  @doc("Service name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Service.Name)
  serviceName?: string;
}

@doc("DORA lead time for changes metric")
model DoraLeadTimeMetric {
  @doc("Metric name")
  name: "dora.lead_time_for_changes";

  @doc("Metric unit (hours)")
  unit: "h";

  @doc("Environment")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.EnvironmentName)
  environment: DeploymentEnvironment;

  @doc("Service name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Service.Name)
  serviceName?: string;
}

@doc("DORA change failure rate metric")
model DoraChangeFailureRateMetric {
  @doc("Metric name")
  name: "dora.change_failure_rate";

  @doc("Metric unit (ratio)")
  unit: "1";

  @doc("Environment")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.EnvironmentName)
  environment: DeploymentEnvironment;

  @doc("Service name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Service.Name)
  serviceName?: string;
}

@doc("DORA mean time to recovery metric")
model DoraMttrMetric {
  @doc("Metric name")
  name: "dora.mttr";

  @doc("Metric unit (hours)")
  unit: "h";

  @doc("Environment")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Deployment.EnvironmentName)
  environment: DeploymentEnvironment;

  @doc("Service name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Service.Name)
  serviceName?: string;
}
