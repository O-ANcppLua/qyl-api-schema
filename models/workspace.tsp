// =============================================================================
// ANcpLua v2.0 - Workspace & Identity Entities
// =============================================================================
// Local-first workspace envelope, handshake, tokens, process registry.
// =============================================================================

import "@typespec/openapi";
import "../common/types.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;

namespace Qyl.Api.Contracts.Domains.Workspace;

// =============================================================================
// Project
// =============================================================================

@doc("Project registry: top-level organizational unit")
@extension("x-csharp-type", "ProjectEntity")
model ProjectEntity {
  @doc("Project ID")
  @key
  @visibility(Lifecycle.Read)
  id: string;

  @doc("Project name")
  @visibility(Lifecycle.Read, Lifecycle.Create, Lifecycle.Update)
  name: string;

  @doc("URL-safe slug (unique)")
  @visibility(Lifecycle.Read, Lifecycle.Create)
  slug: string;

  @doc("Project description")
  @visibility(Lifecycle.Read, Lifecycle.Create, Lifecycle.Update)
  description?: string;

  @doc("Creation timestamp")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;

  @doc("Last update timestamp")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "updated_at")
  updatedAt: utcDateTime;

  @doc("Archive timestamp (null if active)")
  @visibility(Lifecycle.Read)
  @encodedName("application/json", "archived_at")
  archivedAt?: utcDateTime;
}

// =============================================================================
// Project Environment
// =============================================================================

@doc("Environment row per project (dev, staging, prod)")
@extension("x-csharp-type", "ProjectEnvironmentEntity")
model ProjectEnvironmentEntity {
  @doc("Environment ID")
  @key
  id: string;

  @doc("Owning project")
  @encodedName("application/json", "project_id")
  projectId: string;

  @doc("Environment name (dev, staging, prod)")
  name: string;

  @doc("Display name for UI")
  @encodedName("application/json", "display_name")
  displayName: string;

  @doc("Hex color for UI")
  color?: string;

  @doc("Sort order for display")
  @encodedName("application/json", "sort_order")
  sortOrder: int32;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;
}

// =============================================================================
// Local Node
// =============================================================================

@doc("Local agent/daemon registry entry")
@extension("x-csharp-type", "LocalNodeEntity")
model LocalNodeEntity {
  @doc("Node ID")
  @key
  id: string;

  @doc("Owning project")
  @encodedName("application/json", "project_id")
  projectId: string;

  @doc("Environment")
  @encodedName("application/json", "environment_id")
  environmentId: string;

  @doc("Machine hostname")
  hostname: string;

  @doc("OS-level machine identifier")
  @encodedName("application/json", "machine_id")
  machineId?: string;

  @doc("Agent binary version")
  @encodedName("application/json", "agent_version")
  agentVersion?: string;

  @doc("Operating system type")
  @encodedName("application/json", "os_type")
  osType?: string;

  @doc("Operating system version")
  @encodedName("application/json", "os_version")
  osVersion?: string;

  @doc("First seen timestamp")
  @encodedName("application/json", "first_seen_at")
  firstSeenAt: utcDateTime;

  @doc("Last seen timestamp")
  @encodedName("application/json", "last_seen_at")
  lastSeenAt: utcDateTime;

  @doc("Node status")
  status: NodeStatus;
}

@doc("Node online status")
enum NodeStatus {
  @doc("Node is online")
  online: "online",

  @doc("Node is offline")
  offline: "offline",

  @doc("Node heartbeat is stale")
  stale: "stale",
}

// =============================================================================
// Workspace Envelope
// =============================================================================

@doc("Workspace envelope: the local-first workspace unit")
@extension("x-csharp-type", "WorkspaceEnvelopeEntity")
model WorkspaceEnvelopeEntity {
  @doc("Workspace ID")
  @key
  id: string;

  @doc("Owning project")
  @encodedName("application/json", "project_id")
  projectId: string;

  @doc("Environment")
  @encodedName("application/json", "environment_id")
  environmentId: string;

  @doc("Host node")
  @encodedName("application/json", "node_id")
  nodeId: string;

  @doc("Workspace name")
  name: string;

  @doc("Local filesystem root path")
  @encodedName("application/json", "root_path")
  rootPath: string;

  @doc("Last heartbeat timestamp")
  @encodedName("application/json", "heartbeat_at")
  heartbeatAt?: utcDateTime;

  @doc("Heartbeat interval in seconds")
  @encodedName("application/json", "heartbeat_interval_seconds")
  heartbeatIntervalSeconds: int32;

  @doc("Workspace status")
  status: WorkspaceStatus;

  @doc("Workspace-level configuration overrides")
  @encodedName("application/json", "config_json")
  configJson?: string;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;

  @doc("Last update timestamp")
  @encodedName("application/json", "updated_at")
  updatedAt: utcDateTime;
}

@doc("Workspace lifecycle status")
enum WorkspaceStatus {
  @doc("Active and receiving data")
  active: "active",

  @doc("Temporarily suspended")
  suspended: "suspended",

  @doc("Archived (read-only)")
  archived: "archived",
}

// =============================================================================
// Handshake Session
// =============================================================================

@doc("Browser-local handshake session for workspace verification")
@extension("x-csharp-type", "HandshakeSessionEntity")
model HandshakeSessionEntity {
  @doc("Session ID")
  @key
  id: string;

  @doc("Target workspace")
  @encodedName("application/json", "workspace_id")
  workspaceId: string;

  @doc("PKCE-style challenge")
  challenge: string;

  @doc("Challenge method")
  @encodedName("application/json", "challenge_method")
  challengeMethod: string;

  @doc("Browser fingerprint")
  @encodedName("application/json", "browser_fingerprint")
  browserFingerprint?: string;

  @doc("Origin URL")
  @encodedName("application/json", "origin_url")
  originUrl?: string;

  @doc("Handshake state")
  state: HandshakeState;

  @doc("Verification timestamp")
  @encodedName("application/json", "verified_at")
  verifiedAt?: utcDateTime;

  @doc("Expiration timestamp")
  @encodedName("application/json", "expires_at")
  expiresAt: utcDateTime;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;
}

@doc("Handshake session state")
enum HandshakeState {
  @doc("Waiting for verification")
  pending: "pending",

  @doc("Successfully verified")
  verified: "verified",

  @doc("Session expired")
  expired: "expired",

  @doc("Verification rejected")
  rejected: "rejected",
}

// =============================================================================
// Workspace Token
// =============================================================================

@doc("Workspace-scoped API token metadata")
@extension("x-csharp-type", "WorkspaceTokenEntity")
model WorkspaceTokenEntity {
  @doc("Token ID")
  @key
  id: string;

  @doc("Owning workspace")
  @encodedName("application/json", "workspace_id")
  workspaceId: string;

  @doc("Token display name")
  name: string;

  @doc("SHA-256 hash of token value")
  @encodedName("application/json", "token_hash")
  tokenHash: string;

  @doc("First 8 chars for identification")
  @encodedName("application/json", "token_prefix")
  tokenPrefix: string;

  @doc("Allowed scopes")
  @encodedName("application/json", "scopes_json")
  scopesJson?: string;

  @doc("Last used timestamp")
  @encodedName("application/json", "last_used_at")
  lastUsedAt?: utcDateTime;

  @doc("Expiration timestamp")
  @encodedName("application/json", "expires_at")
  expiresAt?: utcDateTime;

  @doc("Revocation timestamp")
  @encodedName("application/json", "revoked_at")
  revokedAt?: utcDateTime;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;
}

// =============================================================================
// Process Registry
// =============================================================================

@doc("Local process identity per workspace")
@extension("x-csharp-type", "ProcessRegistryEntity")
model ProcessRegistryEntity {
  @doc("Registry entry ID")
  @key
  id: string;

  @doc("Owning workspace")
  @encodedName("application/json", "workspace_id")
  workspaceId: string;

  @doc("Process type")
  @encodedName("application/json", "process_type")
  processType: ProcessType;

  @doc("OS process ID")
  pid: int32;

  @doc("Listening port")
  port?: int32;

  @doc("Protocol")
  protocol?: string;

  @doc("Binary file path")
  @encodedName("application/json", "binary_path")
  binaryPath?: string;

  @doc("Binary version")
  @encodedName("application/json", "binary_version")
  binaryVersion?: string;

  @doc("Process start timestamp")
  @encodedName("application/json", "started_at")
  startedAt: utcDateTime;

  @doc("Last heartbeat timestamp")
  @encodedName("application/json", "last_heartbeat_at")
  lastHeartbeatAt?: utcDateTime;

  @doc("Process status")
  status: ProcessStatus;
}

@doc("ANcpLua process types")
enum ProcessType {
  @doc("Collector backend")
  collector: "collector",

  @doc("MCP server")
  mcp: "mcp",

  @doc("Terminal span viewer")
  watch: "watch",

  @doc("Process anomaly detector")
  watchdog: "watchdog",

  @doc("CLI tool")
  cli: "cli",
}

@doc("Process lifecycle status")
enum ProcessStatus {
  @doc("Process is running")
  running: "running",

  @doc("Process has stopped")
  stopped: "stopped",

  @doc("Process crashed")
  crashed: "crashed",
}

// =============================================================================
// Port Lease
// =============================================================================

@doc("Collision-proof port lease entry")
@extension("x-csharp-type", "PortLeaseEntity")
model PortLeaseEntity {
  @doc("Leased port number")
  port: int32;

  @doc("Owning workspace")
  @encodedName("application/json", "workspace_id")
  workspaceId: string;

  @doc("Owning process")
  @encodedName("application/json", "process_id")
  processId: string;

  @doc("Protocol (tcp/udp)")
  protocol: string;

  @doc("Lease start timestamp")
  @encodedName("application/json", "leased_at")
  leasedAt: utcDateTime;

  @doc("Lease expiration")
  @encodedName("application/json", "expires_at")
  expiresAt: utcDateTime;

  @doc("Release timestamp (null if active)")
  @encodedName("application/json", "released_at")
  releasedAt?: utcDateTime;
}
