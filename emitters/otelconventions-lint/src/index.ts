// Copyright (c) 2025-2026 ancplua
// SPDX-License-Identifier: MIT

import {
    createTypeSpecLibrary,
    paramMessage,
    setTypeSpecNamespace,
    type DecoratorContext,
    type Program,
    type Type,
} from "@typespec/compiler";
import { runAllRules } from "./rules.js";

export const $lib = createTypeSpecLibrary({
    name: "@ancplua/typespec-otelconventions-lint",
    diagnostics: {
        "upstream-collision": {
            severity: "error",
            messages: {
                default: paramMessage`ANcpLua-LINT-001: attribute '${"key"}' collides with upstream OTel namespace '${"prefix"}' — ANcpLua attributes must live under 'ancplua.'`,
            },
        },
        "unix-nanos-scalar-required": {
            severity: "error",
            messages: {
                default: paramMessage`ANcpLua-LINT-002: field '${"name"}' must use Qyl.Api.Contracts.Common.UnixNanos, not '${"actual"}'`,
            },
        },
        "duration-nanos-scalar-required": {
            severity: "error",
            messages: {
                default: paramMessage`ANcpLua-LINT-003: field '${"name"}' must use Qyl.Api.Contracts.Common.DurationNs, not '${"actual"}'`,
            },
        },
    },
    state: {
        ancpluaAttr: { description: "Collected ANcpLua attribute declarations (populated by @ancpluaAttr)" },
    },
} as const);

export const { reportDiagnostic, createDiagnostic, stateKeys } = $lib;

export type AncpluaAttrPrimitive = "string" | "int" | "long" | "double" | "boolean" | "string[]";
export type AncpluaAttrCardinality = "low" | "medium" | "high";
export type AncpluaAttrStability = "experimental" | "stable" | "deprecated";

export interface AncpluaAttrOptions {
    cardinality?: AncpluaAttrCardinality;
    stability?: AncpluaAttrStability;
    required?: boolean;
}

export interface AncpluaAttrRecord {
    key: string;
    type: AncpluaAttrPrimitive;
    cardinality?: AncpluaAttrCardinality;
    stability?: AncpluaAttrStability;
    required?: boolean;
    target: Type;
}

/**
 * Decorator implementation for `@ancpluaAttr`. Records the annotation in a state
 * map keyed by target symbol; `$onValidate` enumerates the map and runs the
 * rule set once per compile.
 */
export function $ancpluaAttr(
    context: DecoratorContext,
    target: Type,
    key: string,
    type: AncpluaAttrPrimitive,
    options?: AncpluaAttrOptions,
): void {
    const map = context.program.stateMap(stateKeys.ancpluaAttr);
    const bucket = (map.get(target) as AncpluaAttrRecord[] | undefined) ?? [];
    bucket.push({
        key,
        type,
        cardinality: options?.cardinality,
        stability: options?.stability,
        required: options?.required,
        target,
    });
    map.set(target, bucket);
}

// Bind the decorator implementation to the `Qyl.Api.Schema.Semconv` namespace declared in lib/main.tsp.
// Without this, TypeSpec auto-registers `$ancpluaAttr` at global scope and the fixture's
// `using Qyl.Api.Schema.Semconv;` then finds the decorator in two scopes → `ambiguous-symbol`.
setTypeSpecNamespace("Qyl.Api.Schema.Semconv", $ancpluaAttr);

/**
 * Compiler-invoked validator. Runs AFTER all decorators have applied, so the
 * state map is complete. Emits diagnostics ANcpLua-LINT-001..006.
 */
export function $onValidate(program: Program): void {
    runAllRules(program);
}

// Telemetry Control Graph policy rules (configurable via tspconfig linter options).
export { $linter, graphAttributeKeyRule, graphOrphanSignalsRule } from "./linter.js";
