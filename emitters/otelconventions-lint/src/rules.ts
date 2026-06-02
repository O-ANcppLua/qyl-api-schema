// Copyright (c) 2025-2026 ancplua
// SPDX-License-Identifier: MIT

import {
    isArrayModelType,
    navigateProgram,
    type ModelProperty,
    type Program,
    type Scalar,
    type Type,
} from "@typespec/compiler";
import { reportDiagnostic, stateKeys, type AncpluaAttrRecord } from "./index.js";
import { RESERVED_PREFIXES } from "./registry.js";

/**
 * Flatten the per-target state map buckets into a single array.
 */
function collectAll(program: Program): AncpluaAttrRecord[] {
    const map = program.stateMap(stateKeys.ancpluaAttr);
    const out: AncpluaAttrRecord[] = [];
    for (const bucket of map.values()) {
        for (const rec of bucket as AncpluaAttrRecord[]) out.push(rec);
    }
    return out;
}

/**
 * ANcpLua-LINT-001 — attribute must live in the ANcpLua registry namespace.
 *
 * ANcpLua-owned telemetry keys must not collide with upstream OTel namespaces.
 * Any `@ancpluaAttr`-annotated key left inside the TypeSpec pipeline must use
 * the ANcpLua registry prefix.
 */
function checkUpstreamCollision(program: Program, records: readonly AncpluaAttrRecord[]): void {
    for (const r of records) {
        const collision = RESERVED_PREFIXES.find((p) => r.key.startsWith(p));
        if (collision) {
            reportDiagnostic(program, {
                code: "upstream-collision",
                target: r.target,
                format: { key: r.key, prefix: collision.slice(0, -1) },
            });
        }
    }
}

function checkNanosecondContractScalars(program: Program): void {
    navigateProgram(program, {
        model: (model) => {
            if (isInTypeSpecNamespace(model)) return;
            for (const [, prop] of model.properties) {
                checkNanosecondProperty(program, prop);
            }
        },
    });
}

function checkNanosecondProperty(program: Program, prop: ModelProperty): void {
    if (isUnixNanosField(prop.name) && scalarName(prop.type) !== "UnixNanos") {
        reportDiagnostic(program, {
            code: "unix-nanos-scalar-required",
            target: prop,
            format: { name: prop.name, actual: displayType(prop.type) },
        });
    }

    if (isDurationNanosField(prop.name) && scalarName(prop.type) !== "DurationNs") {
        reportDiagnostic(program, {
            code: "duration-nanos-scalar-required",
            target: prop,
            format: { name: prop.name, actual: displayType(prop.type) },
        });
    }
}

function isUnixNanosField(name: string): boolean {
    return /unixnanos?$/i.test(name);
}

function isDurationNanosField(name: string): boolean {
    return !/^avg/i.test(name) && /(durationns|durationnano)$/i.test(name);
}

function scalarName(type: Type): string | undefined {
    if (type.kind === "Scalar") return (type as Scalar).name;
    if (type.kind === "Model" && isArrayModelType(type)) return scalarName(type.indexer!.value);
    return undefined;
}

function displayType(type: Type): string {
    if (type.kind === "Scalar") return (type as Scalar).name;
    if (type.kind === "Model" && isArrayModelType(type)) return `${displayType(type.indexer!.value)}[]`;
    return "kind" in type ? type.kind : "unknown";
}

function isInTypeSpecNamespace(type: { namespace?: { name?: string; namespace?: unknown } }): boolean {
    let cursor: { name?: string; namespace?: unknown } | undefined = type.namespace;
    while (cursor) {
        if (cursor.name === "TypeSpec") return true;
        cursor = cursor.namespace as typeof cursor;
    }
    return false;
}

export function runAllRules(program: Program): void {
    const records = collectAll(program);
    if (records.length > 0) checkUpstreamCollision(program, records);
    checkNanosecondContractScalars(program);
}
