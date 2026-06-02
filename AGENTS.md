# qyl-api-schema — Agent Notes

This repo is qyl's API schema source of truth. It publishes `@o-ancpplua/qyl-api-schema`
and emits the `Qyl.Api.Contracts` NuGet package.

## Architecture

```text
@ancplua/typespec-otel-semconv
  -> qyl-api-schema
  -> OpenAPI / JSON Schema / Qyl.Api.Contracts / TypeScript contract types
  -> qyl runtime and generated clients
```

`@ancplua/typespec-otel-semconv` is the generic OpenTelemetry semantic-convention key
projection. This repo is qyl-specific. Keep those identities separate.

## Allowed outputs

- OpenAPI JSON
- JSON Schema
- BCL-only C# DTO contracts in `Qyl.Api.Contracts`
- TypeScript schema/types

## Forbidden outputs

- ASP.NET server scaffolds
- generated controllers
- generated mock implementations
- SwaggerUI starter projects
- generated starter docs that tell maintainers to fill in mock business logic
- DuckDB/storage-schema emitters or artifacts
- compatibility shims, aliases, adapters, or packages for old identities

## Naming

- npm package: `@o-ancpplua/qyl-api-schema`
- NuGet package: `Qyl.Api.Contracts`
- qyl API namespaces: `Qyl.Api.Contracts.*`
- generic semconv key namespace: `ANcpLua.OpenTelemetry.SemanticConventions.Keys.*`

Do not reintroduce legacy qyl API package IDs or namespaces. The only qyl API
identity in this repository is `Qyl.Api.Contracts`.

## Generated files

Never hand-edit generated output. Change TypeSpec sources, emitter code, or generator inputs,
then regenerate. If generated output is stale or wrong, delete/regenerate it rather than patching
the generated file.

## Verification

Use the local gate before publishing:

```bash
npm ci
npm run lint
npm run lint:public
npm run compile
./build.sh PackContractsNuget
```

If GitHub Actions is blocked, do not trigger CI. Use local verification and publish manually only
with credentials supplied through environment variables.
