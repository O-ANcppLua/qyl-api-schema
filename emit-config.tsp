// =============================================================================
// ANcpLua Emit Config — central augment-decorator file for the qyl API contract
// TypeSpec emitters (@ancplua/typespec-emit-csharp, emit-ts-types).
//
// This file decorates the existing hand-authored TypeSpec models so the new
// emitters know:
//   - which C# namespace each model maps to (matches NamespaceRoutingTable.cs
//     exactly, mirroring the current contract-drift outputs)
//   - which scalars are opaque branded string IDs on the TypeScript side
//
// Decoration-only: physical storage schema lives in qyl runtime mapping specs,
// not in this API contract repository.
// =============================================================================

import "@ancplua/typespec-emit-csharp";
import "@ancplua/typespec-emit-ts-types";

import "./main.tsp";
import "./models/agent/agent-run.tsp";
import "./models/agent/tool-call.tsp";
import "./models/agent/workflow-checkpoint.tsp";
import "./models/agent/workflow-execution.tsp";
import "./models/alerting.tsp";
import "./models/configurator.tsp";
import "./models/issues.tsp";
import "./models/retention.tsp";
import "./models/search.tsp";
import "./models/triage.tsp";
import "./models/workflow.tsp";
import "./models/workspace.tsp";
import "./intelligence/main.tsp";

using Qyl.Api.Schema.Emit.CSharp;
using Qyl.Api.Schema.Emit.TsTypes;

// -----------------------------------------------------------------------------
// C# namespace routing — one @@csharpNamespace per namespace declared in any
// hand-authored .tsp file. Values mirror NamespaceRoutingTable.cs exactly.
// -----------------------------------------------------------------------------

@@csharpNamespace(Qyl.Api.Contracts, "Qyl.Api.Contracts");
@@csharpNamespace(Qyl.Api.Contracts.Streaming, "Qyl.Api.Contracts.Streaming");

@@csharpNamespace(Qyl.Api.Contracts.Common, "Qyl.Api.Contracts.Common");
@@csharpNamespace(Qyl.Api.Contracts.Common.Errors, "Qyl.Api.Contracts.Common.Errors");
@@csharpNamespace(Qyl.Api.Contracts.Common.Pagination, "Qyl.Api.Contracts.Common.Pagination");

@@csharpNamespace(Qyl.Api.Contracts.Intelligence, "Qyl.Api.Contracts.Intelligence");

@@csharpNamespace(Qyl.Api.Contracts.Domains, "Qyl.Api.Contracts.Domains");
@@csharpNamespace(Qyl.Api.Contracts.Domains.AI.GenAi, "Qyl.Api.Contracts.Domains.AI.GenAi");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Agent.Run, "Qyl.Api.Contracts.Domains.Agent.Run");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Agent.ToolCall, "Qyl.Api.Contracts.Domains.Agent.ToolCall");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Agent.Checkpoint, "Qyl.Api.Contracts.Domains.Agent.Checkpoint");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Agent.Workflow, "Qyl.Api.Contracts.Domains.Agent.Workflow");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Alerting, "Qyl.Api.Contracts.Domains.Alerting");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Configurator, "Qyl.Api.Contracts.Domains.Configurator");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Data.Db, "Qyl.Api.Contracts.Domains.Data.Db");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Identity, "Qyl.Api.Contracts.Domains.Identity");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Issues, "Qyl.Api.Contracts.Domains.Issues");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Loom.Triage, "Qyl.Api.Contracts.Domains.Loom.Triage");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Observe.Error, "Qyl.Api.Contracts.Domains.Observe.Error");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Observe.Log, "Qyl.Api.Contracts.Domains.Observe.Log");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Observe.Otel, "Qyl.Api.Contracts.Domains.Observe.Otel");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Observe.Session, "Qyl.Api.Contracts.Domains.Observe.Session");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Observe.Test, "Qyl.Api.Contracts.Domains.Observe.Test");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Ops.Deployment, "Qyl.Api.Contracts.Domains.Ops.Deployment");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Ops.Retention, "Qyl.Api.Contracts.Domains.Ops.Retention");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Runtime.System, "Qyl.Api.Contracts.Domains.Runtime.System");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Search, "Qyl.Api.Contracts.Domains.Search");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Transport.Http, "Qyl.Api.Contracts.Domains.Transport.Http");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Transport.Messaging, "Qyl.Api.Contracts.Domains.Transport.Messaging");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Transport.Rpc, "Qyl.Api.Contracts.Domains.Transport.Rpc");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Workflow, "Qyl.Api.Contracts.Domains.Workflow");
@@csharpNamespace(Qyl.Api.Contracts.Domains.Workspace, "Qyl.Api.Contracts.Domains.Workspace");

@@csharpNamespace(Qyl.Api.Contracts.OTel, "Qyl.Api.Contracts.OTel");
@@csharpNamespace(Qyl.Api.Contracts.OTel.Enums, "Qyl.Api.Contracts.OTel.Enums");
@@csharpNamespace(Qyl.Api.Contracts.OTel.Logs, "Qyl.Api.Contracts.OTel.Logs");
@@csharpNamespace(Qyl.Api.Contracts.OTel.Metrics, "Qyl.Api.Contracts.OTel.Metrics");
@@csharpNamespace(Qyl.Api.Contracts.OTel.Profiles, "Qyl.Api.Contracts.OTel.Profiles");
@@csharpNamespace(Qyl.Api.Contracts.OTel.Resource, "Qyl.Api.Contracts.OTel.Resource");
@@csharpNamespace(Qyl.Api.Contracts.OTel.Traces, "Qyl.Api.Contracts.OTel.Traces");

// -----------------------------------------------------------------------------
// TypeScript brands for opaque string IDs. Mandate §Commit-4 exact list plus
// any scalar in common/types.tsp with x-csharp-struct extension.
// -----------------------------------------------------------------------------

@@tsBrand(Qyl.Api.Contracts.Common.TraceId);
@@tsBrand(Qyl.Api.Contracts.Common.SpanId);
@@tsBrand(Qyl.Api.Contracts.Common.SessionId);
@@tsBrand(Qyl.Api.Contracts.Common.UserId);
