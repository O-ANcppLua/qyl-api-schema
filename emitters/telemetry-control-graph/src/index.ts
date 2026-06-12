// Copyright (c) 2025-2026 ancplua
// SPDX-License-Identifier: MIT

import {
    createTypeSpecLibrary,
    NoTarget,
    paramMessage,
    resolvePath,
    setTypeSpecNamespace,
    type DecoratorContext,
    type EmitContext,
    type Program,
    type Type,
} from "@typespec/compiler";
import { stringify as toYaml } from "yaml";

const SIGNAL_KINDS = ["span", "metric", "log", "profile"] as const;
const EXPORT_PROTOCOLS = ["otlp_grpc", "otlp_http"] as const;
const ATTRIBUTE_REQUIREMENTS = ["required", "recommended", "opt_in"] as const;
const DEFAULT_FILE_TYPES = ["json", "yaml"] as const;

export const $lib = createTypeSpecLibrary({
    name: "@qyl/telemetry-control-graph",
    diagnostics: {
        "multiple-instances": {
            severity: "error",
            messages: {
                default: paramMessage`TCG-001: exactly one @instance graph is allowed per compilation; found ${"count"}`,
            },
        },
        "invalid-shape": {
            severity: "error",
            messages: {
                default: paramMessage`TCG-002: graph instance is not a TelemetryControlGraph v1 value: ${"detail"}`,
            },
        },
        "duplicate-service": {
            severity: "error",
            messages: {
                default: paramMessage`TCG-003: duplicate service node '${"serviceName"}' - service names are graph keys`,
            },
        },
        "duplicate-signal": {
            severity: "error",
            messages: {
                default: paramMessage`TCG-004: service '${"serviceName"}' declares signal '${"kind"}:${"name"}' more than once`,
            },
        },
        "duplicate-attribute": {
            severity: "error",
            messages: {
                default: paramMessage`TCG-005: service '${"serviceName"}' signal '${"kind"}:${"name"}' declares attribute '${"key"}' more than once`,
            },
        },
        "duplicate-exporter": {
            severity: "error",
            messages: {
                default: paramMessage`TCG-006: service '${"serviceName"}' declares exporter id '${"exporterId"}' more than once`,
            },
        },
        "export-undeclared-kind": {
            severity: "error",
            messages: {
                default: paramMessage`TCG-007: service '${"serviceName"}' exports signal kind '${"kind"}' over '${"exporterId"}' but never declares a signal of that kind`,
            },
        },
        "service-without-signals": {
            severity: "error",
            messages: {
                default: paramMessage`TCG-008: service '${"serviceName"}' must declare at least one telemetry signal`,
            },
        },
        "service-without-exports": {
            severity: "error",
            messages: {
                default: paramMessage`TCG-009: service '${"serviceName"}' must declare at least one export edge`,
            },
        },
        "bad-emitter-option": {
            severity: "error",
            messages: {
                default: paramMessage`TCG-010: invalid @qyl/telemetry-control-graph option '${"option"}': ${"detail"}`,
            },
        },
    },
    state: {
        tcgInstance: { description: "Telemetry Control Graph instances recorded by @instance" },
    },
} as const);

export const { reportDiagnostic, stateKeys } = $lib;

export type TcgSignalKind = (typeof SIGNAL_KINDS)[number];
export type TcgExportProtocol = (typeof EXPORT_PROTOCOLS)[number];
export type TcgAttributeRequirement = (typeof ATTRIBUTE_REQUIREMENTS)[number];

export interface TcgDeclaredAttribute {
    key: string;
    requirement: TcgAttributeRequirement;
}

export interface TcgDeclaredSignal {
    kind: TcgSignalKind;
    name: string;
    attributes: TcgDeclaredAttribute[];
}

export interface TcgExportEdge {
    exporter_id: string;
    protocol: TcgExportProtocol;
    endpoint_env_var: string;
    signals: TcgSignalKind[];
}

export interface TcgServiceNode {
    service_name: string;
    profile_id: string;
    declares: TcgDeclaredSignal[];
    exports: TcgExportEdge[];
}

export interface TcgGraph {
    schema_version: "1";
    services: TcgServiceNode[];
}

export interface TcgInstanceRecord {
    graph: TcgGraph;
    target: Type;
}

export interface TcgEmitterOptions {
    "file-types"?: readonly string[] | string;
    "include-schema"?: boolean;
    "include-conformance-plan"?: boolean;
    "include-report"?: boolean;
    "schema-id"?: string;
}

interface TcgRawInstanceRecord {
    graph: unknown;
    target: Type;
}

interface InstrumentationProfilesArtifact {
    schema_version: "1";
    profiles: InstrumentationProfileRef[];
}

interface InstrumentationProfileRef {
    profile_id: string;
    service_names: string[];
}

interface DeclaredSignalsArtifact {
    schema_version: "1";
    services: DeclaredSignalsService[];
}

interface DeclaredSignalsService {
    service_name: string;
    profile_id: string;
    signals: TcgDeclaredSignal[];
}

interface ExportEdgesArtifact {
    schema_version: "1";
    edges: ExportEdgeBinding[];
}

interface ExportEdgeBinding {
    service_name: string;
    signal_kind: TcgSignalKind;
    exporter_id: string;
    protocol: TcgExportProtocol;
    endpoint_env_var: string;
}

interface ConformancePlan {
    schema_version: "1";
    graph_schema_version: "1";
    services: ConformanceService[];
}

interface ConformanceService {
    service_name: string;
    profile_id: string;
    expected_signals: ConformanceSignal[];
    export_edges: TcgExportEdge[];
}

interface ConformanceSignal {
    kind: TcgSignalKind;
    name: string;
    required_attributes: string[];
    recommended_attributes: string[];
    opt_in_attributes: string[];
    exporter_ids: string[];
}

interface NormalizationResult {
    graph?: TcgGraph;
    defects: string[];
}

/**
 * All valid graph instances recorded in this program. Invalid instances are
 * filtered; diagnostics are emitted by `$onValidate` against the original target.
 */
export function getTcgInstances(program: Program): TcgInstanceRecord[] {
    const out: TcgInstanceRecord[] = [];
    for (const rec of rawInstances(program)) {
        const normalized = normalizeGraph(rec.graph);
        if (normalized.graph) out.push({ graph: normalized.graph, target: rec.target });
    }
    return out;
}

export function $instance(context: DecoratorContext, target: Type, graph: unknown): void {
    context.program.stateMap(stateKeys.tcgInstance).set(target, { graph, target } satisfies TcgRawInstanceRecord);
}

setTypeSpecNamespace("Qyl.Api.Schema.Tcg", $instance);

/** Hard graph invariants. Policy-only rules belong in otelconventions-lint. */
export function $onValidate(program: Program): void {
    const instances = rawInstances(program);
    if (instances.length === 0) return;

    if (instances.length > 1) {
        for (const rec of instances) {
            reportDiagnostic(program, {
                code: "multiple-instances",
                target: rec.target,
                format: { count: String(instances.length) },
            });
        }
        return;
    }

    const rec = instances[0];
    const normalized = normalizeGraph(rec.graph);
    for (const defect of normalized.defects) {
        reportDiagnostic(program, {
            code: "invalid-shape",
            target: rec.target,
            format: { detail: defect },
        });
    }
    if (!normalized.graph) return;

    validateGraph(program, rec.target, normalized.graph);
}

/** Emits the full v1 artifact set under the configured emitter-output-dir. */
export async function $onEmit(context: EmitContext<TcgEmitterOptions>): Promise<void> {
    if (context.program.compilerOptions.dryRun) return;

    const options = parseEmitterOptions(context);
    if (!options) return;

    const instances = getTcgInstances(context.program);
    if (instances.length !== 1) return;

    const graph = instances[0].graph;
    await context.program.host.mkdirp(context.emitterOutputDir);

    if (options.fileTypes.has("json")) await writeJson(context, "control-graph.json", graph);
    if (options.fileTypes.has("yaml")) await writeYaml(context, "control-graph.yaml", graph);

    await writeJson(context, "instrumentation-profiles.json", buildInstrumentationProfiles(graph));
    await writeJson(context, "declared-signals.json", buildDeclaredSignals(graph));
    await writeJson(context, "export-edges.json", buildExportEdges(graph));

    if (options.includeSchema) await writeJson(context, "control-graph.schema.json", graphJsonSchema(options.schemaId));
    if (options.includeConformancePlan) await writeJson(context, "conformance-plan.json", buildConformancePlan(graph));
    if (options.includeReport) await writeText(context, "control-graph.report.md", buildReport(graph));
}

function rawInstances(program: Program): TcgRawInstanceRecord[] {
    const out: TcgRawInstanceRecord[] = [];
    for (const [, rec] of program.stateMap(stateKeys.tcgInstance)) out.push(rec as TcgRawInstanceRecord);
    return out;
}

function normalizeGraph(input: unknown): NormalizationResult {
    const defects: string[] = [];
    const graph = asRecord(input);
    if (!graph) return { defects: ["value is not an object"] };

    const schemaVersion = stringValue(graph.schema_version);
    if (schemaVersion !== "1") defects.push(`schema_version must be \"1\", got '${String(graph.schema_version)}'`);

    if (!Array.isArray(graph.services)) {
        defects.push("services must be an array");
        return { defects };
    }

    const services: TcgServiceNode[] = [];
    for (const [serviceIndex, rawService] of graph.services.entries()) {
        const service = asRecord(rawService);
        if (!service) {
            defects.push(`services[${serviceIndex}] must be an object`);
            continue;
        }

        const serviceName = requiredString(defects, service.service_name, `services[${serviceIndex}].service_name`);
        const profileId = requiredString(defects, service.profile_id, `services[${serviceIndex}].profile_id`);
        const declares = normalizeSignals(defects, service.declares, serviceName || `services[${serviceIndex}]`);
        const exports = normalizeExports(defects, service.exports, serviceName || `services[${serviceIndex}]`);

        if (serviceName && profileId) services.push({ service_name: serviceName, profile_id: profileId, declares, exports });
    }

    if (defects.length > 0) return { defects };

    return {
        defects: [],
        graph: {
            schema_version: "1",
            services: services.sort(by((x) => x.service_name)),
        },
    };
}

function normalizeSignals(defects: string[], value: unknown, serviceName: string): TcgDeclaredSignal[] {
    if (!Array.isArray(value)) {
        defects.push(`service '${serviceName}': declares must be an array`);
        return [];
    }

    const signals: TcgDeclaredSignal[] = [];
    for (const [signalIndex, rawSignal] of value.entries()) {
        const signal = asRecord(rawSignal);
        if (!signal) {
            defects.push(`service '${serviceName}': declares[${signalIndex}] must be an object`);
            continue;
        }

        const kind = enumValue(defects, signal.kind, SIGNAL_KINDS, `service '${serviceName}': declares[${signalIndex}].kind`);
        const name = requiredString(defects, signal.name, `service '${serviceName}': declares[${signalIndex}].name`);
        const attributes = normalizeAttributes(defects, signal.attributes ?? [], serviceName, kind, name);

        if (kind && name) signals.push({ kind, name, attributes });
    }

    return signals.sort(by((x) => `${x.kind}:${x.name}`));
}

function normalizeAttributes(
    defects: string[],
    value: unknown,
    serviceName: string,
    kind: string | undefined,
    signalName: string | undefined,
): TcgDeclaredAttribute[] {
    if (!Array.isArray(value)) {
        defects.push(`service '${serviceName}' signal '${kind ?? "?"}:${signalName ?? "?"}': attributes must be an array`);
        return [];
    }

    const attributes: TcgDeclaredAttribute[] = [];
    for (const [attributeIndex, rawAttribute] of value.entries()) {
        const attribute = asRecord(rawAttribute);
        if (!attribute) {
            defects.push(`service '${serviceName}' signal '${kind ?? "?"}:${signalName ?? "?"}': attributes[${attributeIndex}] must be an object`);
            continue;
        }

        const key = requiredString(defects, attribute.key, `service '${serviceName}' signal '${kind ?? "?"}:${signalName ?? "?"}': attributes[${attributeIndex}].key`);
        const requirement =
            attribute.requirement === undefined
                ? "recommended"
                : enumValue(defects, attribute.requirement, ATTRIBUTE_REQUIREMENTS, `service '${serviceName}' signal '${kind ?? "?"}:${signalName ?? "?"}': attributes[${attributeIndex}].requirement`);

        if (key && requirement) attributes.push({ key, requirement });
    }

    return attributes.sort(by((x) => x.key));
}

function normalizeExports(defects: string[], value: unknown, serviceName: string): TcgExportEdge[] {
    if (!Array.isArray(value)) {
        defects.push(`service '${serviceName}': exports must be an array`);
        return [];
    }

    const exports: TcgExportEdge[] = [];
    for (const [edgeIndex, rawEdge] of value.entries()) {
        const edge = asRecord(rawEdge);
        if (!edge) {
            defects.push(`service '${serviceName}': exports[${edgeIndex}] must be an object`);
            continue;
        }

        const exporterId = requiredString(defects, edge.exporter_id, `service '${serviceName}': exports[${edgeIndex}].exporter_id`);
        const protocol = enumValue(defects, edge.protocol, EXPORT_PROTOCOLS, `service '${serviceName}': exports[${edgeIndex}].protocol`);
        const endpointEnvVar = requiredString(defects, edge.endpoint_env_var, `service '${serviceName}': exports[${edgeIndex}].endpoint_env_var`);
        const signals = normalizeSignalKindArray(defects, edge.signals, `service '${serviceName}': exports[${edgeIndex}].signals`);

        if (endpointEnvVar && !/^[A-Z_][A-Z0-9_]*$/.test(endpointEnvVar)) {
            defects.push(`service '${serviceName}': exports[${edgeIndex}].endpoint_env_var must be an environment variable name, got '${endpointEnvVar}'`);
        }

        if (exporterId && protocol && endpointEnvVar) exports.push({ exporter_id: exporterId, protocol, endpoint_env_var: endpointEnvVar, signals });
    }

    return exports.sort(by((x) => x.exporter_id));
}

function normalizeSignalKindArray(defects: string[], value: unknown, path: string): TcgSignalKind[] {
    if (!Array.isArray(value)) {
        defects.push(`${path} must be an array`);
        return [];
    }

    const out: TcgSignalKind[] = [];
    for (const [index, raw] of value.entries()) {
        const kind = enumValue(defects, raw, SIGNAL_KINDS, `${path}[${index}]`);
        if (kind) out.push(kind);
    }
    return unique(out).sort();
}

function validateGraph(program: Program, target: Type, graph: TcgGraph): void {
    const seenServices = new Set<string>();

    for (const service of graph.services) {
        if (seenServices.has(service.service_name)) {
            reportDiagnostic(program, { code: "duplicate-service", target, format: { serviceName: service.service_name } });
        }
        seenServices.add(service.service_name);

        if (service.declares.length === 0) reportDiagnostic(program, { code: "service-without-signals", target, format: { serviceName: service.service_name } });
        if (service.exports.length === 0) reportDiagnostic(program, { code: "service-without-exports", target, format: { serviceName: service.service_name } });

        const declaredKinds = new Set<TcgSignalKind>();
        const seenSignals = new Set<string>();
        for (const signal of service.declares) {
            declaredKinds.add(signal.kind);
            const signalKey = `${signal.kind}:${signal.name}`;
            if (seenSignals.has(signalKey)) {
                reportDiagnostic(program, { code: "duplicate-signal", target, format: { serviceName: service.service_name, kind: signal.kind, name: signal.name } });
            }
            seenSignals.add(signalKey);

            const seenAttributes = new Set<string>();
            for (const attribute of signal.attributes) {
                if (seenAttributes.has(attribute.key)) {
                    reportDiagnostic(program, {
                        code: "duplicate-attribute",
                        target,
                        format: { serviceName: service.service_name, kind: signal.kind, name: signal.name, key: attribute.key },
                    });
                }
                seenAttributes.add(attribute.key);
            }
        }

        const seenExporters = new Set<string>();
        for (const edge of service.exports) {
            if (seenExporters.has(edge.exporter_id)) {
                reportDiagnostic(program, { code: "duplicate-exporter", target, format: { serviceName: service.service_name, exporterId: edge.exporter_id } });
            }
            seenExporters.add(edge.exporter_id);

            for (const kind of edge.signals) {
                if (!declaredKinds.has(kind)) {
                    reportDiagnostic(program, { code: "export-undeclared-kind", target, format: { serviceName: service.service_name, kind, exporterId: edge.exporter_id } });
                }
            }
        }
    }
}

function parseEmitterOptions(context: EmitContext<TcgEmitterOptions>):
    | {
          fileTypes: Set<"json" | "yaml">;
          includeSchema: boolean;
          includeConformancePlan: boolean;
          includeReport: boolean;
          schemaId: string;
      }
    | undefined {
    const fileTypes = parseFileTypes(context);
    if (!fileTypes) return undefined;

    return {
        fileTypes,
        includeSchema: context.options["include-schema"] ?? true,
        includeConformancePlan: context.options["include-conformance-plan"] ?? true,
        includeReport: context.options["include-report"] ?? false,
        schemaId: context.options["schema-id"] ?? "https://qyl.dev/schemas/telemetry-control-graph.v1.schema.json",
    };
}

function parseFileTypes(context: EmitContext<TcgEmitterOptions>): Set<"json" | "yaml"> | undefined {
    const raw = context.options["file-types"] ?? DEFAULT_FILE_TYPES;
    const values = Array.isArray(raw) ? raw : [raw];
    const fileTypes = new Set<"json" | "yaml">();

    for (const value of values) {
        if (value !== "json" && value !== "yaml") {
            reportDiagnostic(context.program, {
                code: "bad-emitter-option",
                format: { option: "file-types", detail: `unsupported file type '${String(value)}'; expected json or yaml` },
                target: NoTarget,
            });
            return undefined;
        }
        fileTypes.add(value);
    }

    if (fileTypes.size === 0) {
        reportDiagnostic(context.program, { code: "bad-emitter-option", format: { option: "file-types", detail: "at least one file type is required" }, target: NoTarget });
        return undefined;
    }

    return fileTypes;
}

function buildInstrumentationProfiles(graph: TcgGraph): InstrumentationProfilesArtifact {
    const map = new Map<string, Set<string>>();
    for (const service of graph.services) {
        const services = map.get(service.profile_id) ?? new Set<string>();
        services.add(service.service_name);
        map.set(service.profile_id, services);
    }

    return {
        schema_version: "1",
        profiles: [...map.entries()]
            .map(([profile_id, serviceNames]) => ({ profile_id, service_names: [...serviceNames].sort() }))
            .sort(by((x) => x.profile_id)),
    };
}

function buildDeclaredSignals(graph: TcgGraph): DeclaredSignalsArtifact {
    return {
        schema_version: "1",
        services: graph.services.map((service) => ({
            service_name: service.service_name,
            profile_id: service.profile_id,
            signals: service.declares,
        })),
    };
}

function buildExportEdges(graph: TcgGraph): ExportEdgesArtifact {
    const edges: ExportEdgeBinding[] = [];
    for (const service of graph.services) {
        for (const edge of service.exports) {
            for (const kind of edge.signals) {
                edges.push({
                    service_name: service.service_name,
                    signal_kind: kind,
                    exporter_id: edge.exporter_id,
                    protocol: edge.protocol,
                    endpoint_env_var: edge.endpoint_env_var,
                });
            }
        }
    }

    return { schema_version: "1", edges: edges.sort(by((x) => `${x.service_name}:${x.signal_kind}:${x.exporter_id}`)) };
}

function buildConformancePlan(graph: TcgGraph): ConformancePlan {
    return {
        schema_version: "1",
        graph_schema_version: graph.schema_version,
        services: graph.services.map((service) => ({
            service_name: service.service_name,
            profile_id: service.profile_id,
            expected_signals: service.declares.map((signal) => ({
                kind: signal.kind,
                name: signal.name,
                required_attributes: attributesByRequirement(signal, "required"),
                recommended_attributes: attributesByRequirement(signal, "recommended"),
                opt_in_attributes: attributesByRequirement(signal, "opt_in"),
                exporter_ids: exportersForKind(service, signal.kind),
            })),
            export_edges: service.exports,
        })),
    };
}

function attributesByRequirement(signal: TcgDeclaredSignal, requirement: TcgAttributeRequirement): string[] {
    return signal.attributes.filter((x) => x.requirement === requirement).map((x) => x.key).sort();
}

function exportersForKind(service: TcgServiceNode, kind: TcgSignalKind): string[] {
    return service.exports.filter((edge) => edge.signals.includes(kind)).map((edge) => edge.exporter_id).sort();
}

function graphJsonSchema(schemaId: string): Record<string, unknown> {
    const attributeRequirement = { enum: ATTRIBUTE_REQUIREMENTS };
    const signalKind = { enum: SIGNAL_KINDS };
    const exportProtocol = { enum: EXPORT_PROTOCOLS };

    return {
        $schema: "https://json-schema.org/draft/2020-12/schema",
        $id: schemaId,
        title: "Telemetry Control Graph v1",
        type: "object",
        additionalProperties: false,
        required: ["schema_version", "services"],
        properties: {
            schema_version: { const: "1" },
            services: { type: "array", items: { $ref: "#/$defs/serviceNode" } },
        },
        $defs: {
            serviceNode: {
                type: "object",
                additionalProperties: false,
                required: ["service_name", "profile_id", "declares", "exports"],
                properties: {
                    service_name: { type: "string", minLength: 1 },
                    profile_id: { type: "string", minLength: 1 },
                    declares: { type: "array", minItems: 1, items: { $ref: "#/$defs/declaredSignal" } },
                    exports: { type: "array", minItems: 1, items: { $ref: "#/$defs/exportEdge" } },
                },
            },
            declaredSignal: {
                type: "object",
                additionalProperties: false,
                required: ["kind", "name", "attributes"],
                properties: {
                    kind: signalKind,
                    name: { type: "string", minLength: 1 },
                    attributes: { type: "array", items: { $ref: "#/$defs/declaredAttribute" } },
                },
            },
            declaredAttribute: {
                type: "object",
                additionalProperties: false,
                required: ["key", "requirement"],
                properties: {
                    key: { type: "string", minLength: 1 },
                    requirement: attributeRequirement,
                },
            },
            exportEdge: {
                type: "object",
                additionalProperties: false,
                required: ["exporter_id", "protocol", "endpoint_env_var", "signals"],
                properties: {
                    exporter_id: { type: "string", minLength: 1 },
                    protocol: exportProtocol,
                    endpoint_env_var: { type: "string", pattern: "^[A-Z_][A-Z0-9_]*$" },
                    signals: { type: "array", minItems: 1, items: signalKind },
                },
            },
        },
    };
}

function buildReport(graph: TcgGraph): string {
    const services = graph.services.length;
    const signals = graph.services.reduce((sum, service) => sum + service.declares.length, 0);
    const attributes = graph.services.reduce((sum, service) => sum + service.declares.reduce((inner, signal) => inner + signal.attributes.length, 0), 0);
    const exports = graph.services.reduce((sum, service) => sum + service.exports.length, 0);

    const lines = [
        "# Telemetry Control Graph v1",
        "",
        `- Schema version: ${graph.schema_version}`,
        `- Services: ${services}`,
        `- Signals: ${signals}`,
        `- Attributes: ${attributes}`,
        `- Export edges: ${exports}`,
        "",
        "## Services",
        "",
    ];

    for (const service of graph.services) {
        lines.push(`### ${service.service_name}`, "", `- Profile: ${service.profile_id}`, `- Declared signals: ${service.declares.length}`, `- Export edges: ${service.exports.length}`, "");
        lines.push("| Signal | Attributes | Exporters |", "| --- | ---: | --- |");
        for (const signal of service.declares) {
            lines.push(`| ${signal.kind}:${signal.name} | ${signal.attributes.length} | ${exportersForKind(service, signal.kind).join(", ") || "-"} |`);
        }
        lines.push("");
    }

    return lines.join("\n");
}

async function writeJson(context: EmitContext<TcgEmitterOptions>, fileName: string, value: unknown): Promise<void> {
    await writeText(context, fileName, JSON.stringify(value, undefined, 2) + "\n");
}

async function writeYaml(context: EmitContext<TcgEmitterOptions>, fileName: string, value: unknown): Promise<void> {
    await writeText(context, fileName, toYaml(value));
}

async function writeText(context: EmitContext<TcgEmitterOptions>, fileName: string, content: string): Promise<void> {
    await context.program.host.writeFile(resolvePath(context.emitterOutputDir, fileName), content.endsWith("\n") ? content : `${content}\n`);
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
    return typeof value === "object" && value !== null && !Array.isArray(value) ? (value as Record<string, unknown>) : undefined;
}

function requiredString(defects: string[], value: unknown, path: string): string | undefined {
    const str = stringValue(value);
    if (str === undefined || str.length === 0) {
        defects.push(`${path} must be a non-empty string`);
        return undefined;
    }
    return str;
}

function stringValue(value: unknown): string | undefined {
    return typeof value === "string" ? value.trim() : undefined;
}

function enumValue<const T extends readonly string[]>(defects: string[], value: unknown, allowed: T, path: string): T[number] | undefined {
    const str = stringValue(value);
    if (str !== undefined && (allowed as readonly string[]).includes(str)) return str as T[number];
    defects.push(`${path} must be one of: ${allowed.join(", ")}`);
    return undefined;
}

function unique<const T>(values: readonly T[]): T[] {
    return [...new Set(values)];
}

function by<T>(selector: (value: T) => string): (left: T, right: T) => number {
    return (left, right) => selector(left).localeCompare(selector(right));
}
