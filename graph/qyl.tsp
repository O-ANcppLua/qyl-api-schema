// =============================================================================
// ANcpLua v2.0 - Telemetry Control Graph instance: the qyl deployment
// =============================================================================
// The declared telemetry surface of qyl itself (services/qyl.collector,
// services/qyl.dashboard). Wire-shape values (snake_case) — structurally
// validated by @qyl/telemetry-control-graph's $onValidate, policy-checked by
// otelconventions-lint, emitted to generated/control-graph/ for the runtime
// verifier (qyl/internal/qyl.conformance).
//
// LOCAL ONLY (main.tsp): depends on the file:-linked emitter package, which
// registry consumers of index.tsp do not receive.
// =============================================================================

import "@qyl/telemetry-control-graph";
import "../models/control-graph.tsp";

@Qyl.Api.Schema.Tcg.instance(#{
  schema_version: "1",
  services: #[
    #{
      service_name: "qyl.collector",
      profile_id: "qyl-default",
      declares: #[
        #{
          kind: "span",
          name: "http.server.request",
          attributes: #[
            #{ key: "http.request.method", requirement: "required" },
            #{ key: "http.response.status_code", requirement: "recommended" },
            #{ key: "url.path", requirement: "recommended" },
          ],
        },
        #{
          kind: "metric",
          name: "http.server.request.duration",
          attributes: #[
            #{ key: "http.request.method", requirement: "required" },
            #{ key: "http.response.status_code", requirement: "recommended" },
          ],
        },
        #{
          kind: "log",
          name: "qyl.collector.ingest",
          attributes: #[
            #{ key: "qyl.session.id", requirement: "recommended" },
          ],
        },
      ],
      exports: #[
        #{
          exporter_id: "collector-primary",
          protocol: "otlp_grpc",
          endpoint_env_var: "OTEL_EXPORTER_OTLP_ENDPOINT",
          signals: #["span", "metric", "log"],
        },
      ],
    },
    #{
      service_name: "qyl.dashboard",
      profile_id: "qyl-default",
      declares: #[
        #{
          kind: "span",
          name: "http.client.request",
          attributes: #[
            #{ key: "http.request.method", requirement: "required" },
            #{ key: "server.address", requirement: "recommended" },
          ],
        },
      ],
      exports: #[
        #{
          exporter_id: "collector-primary",
          protocol: "otlp_http",
          endpoint_env_var: "QYL_OTLP_HTTP_ENDPOINT",
          signals: #["span"],
        },
      ],
    },
  ],
})
namespace Qyl.Graph.Instance;
