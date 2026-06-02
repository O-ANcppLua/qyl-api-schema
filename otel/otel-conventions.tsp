// =============================================================================
// otel/otel-conventions.tsp — OTel core barrel
// =============================================================================
// Exposed via the public subpath `@o-ancpplua/qyl-api-schema/otel` for
// consumers that want only the OpenTelemetry-shaped signal models without the
// rest of the qyl API surface.
// =============================================================================

import "./enums.tsp";
import "./resource.tsp";
import "./span.tsp";
import "./logs.tsp";
import "./metrics.tsp";
import "./profiles.tsp";
