// Copyright (c) 2025-2026 ancplua
// SPDX-License-Identifier: MIT
//
// Graph POLICY rules for the Telemetry Control Graph. Hard invariants (broken
// shape, impossible references) are compile errors in @qyl/telemetry-control-graph's
// $onValidate — these rules are the tunable hygiene layer on top.

import { createRule, defineLinter, paramMessage, type DiagnosticTarget } from "@typespec/compiler";
import { getTcgInstances } from "@qyl/telemetry-control-graph";
import { RESERVED_PREFIXES } from "./registry.js";

export interface GraphAttributeKeyOptions {
    readonly pattern: string;
    readonly allowedRoots: readonly string[];
}

/**
 * Policy: declared attribute keys must be well-formed, and keys outside the
 * upstream OTel namespaces must live under an approved private root. Both the
 * format and the roots are tunable per project via rule options (TypeSpec 1.12+).
 */
export const graphAttributeKeyRule = createRule({
    name: "graph-attribute-key",
    severity: "warning",
    description: "Telemetry Control Graph attribute keys must be well-formed and custom keys must use an approved private root.",
    messages: {
        format: paramMessage`TCG attribute key '${"key"}' (service '${"serviceName"}') does not match required pattern '${"pattern"}'`,
        root: paramMessage`TCG attribute key '${"key"}' (service '${"serviceName"}') is neither an upstream OTel namespace key nor under an approved private root (${"roots"})`,
    },
    defaultOptions: {
        pattern: "^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$",
        allowedRoots: ["qyl", "ancplua"],
    } satisfies GraphAttributeKeyOptions,
    create(context) {
        return {
            exit: () => {
                const options = context.options as GraphAttributeKeyOptions;
                const pattern = new RegExp(options.pattern);

                const checkKey = (key: string, serviceName: string, target: DiagnosticTarget): void => {
                    if (!pattern.test(key)) {
                        context.reportDiagnostic({
                            messageId: "format",
                            format: { key, serviceName, pattern: options.pattern },
                            target,
                        });
                        return;
                    }
                    const isUpstream = RESERVED_PREFIXES.some((p) => key.startsWith(p));
                    const root = key.split(".", 1)[0];
                    if (!isUpstream && !options.allowedRoots.includes(root)) {
                        context.reportDiagnostic({
                            messageId: "root",
                            format: { key, serviceName, roots: options.allowedRoots.join(", ") },
                            target,
                        });
                    }
                };

                for (const rec of getTcgInstances(context.program)) {
                    for (const service of rec.graph.services) {
                        for (const signal of service.declares) {
                            for (const attribute of signal.attributes) {
                                checkKey(attribute.key, service.service_name, rec.target);
                            }
                        }
                    }
                }
            },
        };
    },
});

/**
 * Whole-program policy (exit event): a service that declares a signal kind no
 * export edge carries is an orphan — telemetry produced but contractually
 * routed nowhere. Warning, not error: staged rollouts legitimately pass
 * through this state.
 */
export const graphOrphanSignalsRule = createRule({
    name: "graph-orphan-signals",
    severity: "warning",
    description: "Every declared signal kind of a service should be carried by at least one export edge.",
    messages: {
        default: paramMessage`service '${"serviceName"}' declares signal kind '${"kind"}' but no export edge carries it`,
    },
    create(context) {
        return {
            exit: () => {
                for (const rec of getTcgInstances(context.program)) {
                    for (const service of rec.graph.services) {
                        const exported = new Set(service.exports.flatMap((e) => e.signals));
                        for (const kind of new Set(service.declares.map((d) => d.kind))) {
                            if (!exported.has(kind)) {
                                context.reportDiagnostic({
                                    format: { serviceName: service.service_name, kind },
                                    target: rec.target,
                                });
                            }
                        }
                    }
                }
            },
        };
    },
});

export const $linter = defineLinter({
    rules: [graphAttributeKeyRule, graphOrphanSignalsRule],
    ruleSets: {
        recommended: {
            enable: {
                [`@ancplua/typespec-otelconventions-lint/${graphAttributeKeyRule.name}`]: true,
                [`@ancplua/typespec-otelconventions-lint/${graphOrphanSignalsRule.name}`]: true,
            },
        },
    },
});
