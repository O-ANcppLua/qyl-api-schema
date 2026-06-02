// =============================================================================
// @o-ancpplua/qyl-api-schema — published entry point
// =============================================================================
// Consumer-facing barrel. Mirrors main.tsp minus local emit routing.
// The local emitters depend on `file:` packages
// (@ancplua/typespec-emit-*) which are not shipped to registry consumers and
// would break TypeSpec import resolution.
//
// Use main.tsp inside this repo for local `tsp compile`; downstream consumers
// reach the public surface through this file via the `.` export.
// =============================================================================

import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi";
import "@typespec/openapi3";
import "@typespec/versioning";
import "@typespec/sse";
import "@typespec/events";

import "./generated/otel-keys.gen.tsp";

import "./common/types.tsp";
import "./common/errors.tsp";
import "./common/pagination.tsp";

import "./otel/enums.tsp";
import "./otel/resource.tsp";
import "./otel/span.tsp";
import "./otel/logs.tsp";
import "./otel/metrics.tsp";
import "./otel/profiles.tsp";

import "./models/genai.tsp";
import "./models/http.tsp";
import "./models/rpc.tsp";
import "./models/messaging.tsp";
import "./models/db.tsp";
import "./models/session.tsp";
import "./models/otel-config.tsp";
import "./models/log.tsp";
import "./models/error.tsp";
import "./models/test.tsp";
import "./models/deployment.tsp";
import "./models/system.tsp";
import "./models/identity.tsp";

import "./api/routes.tsp";
import "./api/streaming.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;
using TypeSpec.OpenAPI;
using TypeSpec.Versioning;
