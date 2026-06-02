// =============================================================================
// ANcpLua v2.0 - Seed Diagnostic Patterns (v1)
// =============================================================================
// 19 initial diagnostic patterns (10 infra + 9 agent behavioral)
// Source: specs/telemetry-intelligence.md §5.1 + Microsoft Research AgentRx (March 2026)
// These compile to static registries in DiagnosticPatterns.g.cs.
//
// Signal attributes reference:
//   - OTel semantic attributes (status_code, duration_ns, etc.)
//   - qyl-derived attributes (gen_ai_provider_name, gen_ai_stop_reason, etc.)
//   - Computed fields (occurrence_rate, span_count_under_parent, etc.)
// =============================================================================

namespace Qyl.Api.Contracts.Intelligence.Seed;

// ---------------------------------------------------------------------------
// Pattern: genai_rate_limit
// Category: genai
// Signals: status_code=2, gen_ai_provider_name exists, error_type contains rate_limit
// Hypothesis: Provider throttling. Check quota, reduce concurrency, add backoff.
// Confidence: 0.9
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: genai_token_exhaustion
// Category: genai
// Signals: gen_ai_stop_reason=length
// Hypothesis: Context window exceeded. Reduce prompt size or switch to larger model.
// Confidence: 0.85
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: genai_content_filter
// Category: genai
// Signals: gen_ai_stop_reason contains content_filter
// Hypothesis: Content policy violation. Review prompt content.
// Confidence: 0.95
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: db_timeout
// Category: data
// Signals: exception_type=TimeoutException, db.system.name exists, duration_ns > 2000000000
// Hypothesis: Database query timeout. Check query plan, connection pool, lock contention.
// Confidence: 0.85
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: db_n_plus_one
// Category: data
// Signals: db.system.name exists, parent_span_id exists, span_count_under_parent > 10
// Hypothesis: N+1 query pattern. Batch or prefetch related data.
// Confidence: 0.80
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: http_5xx_cluster
// Category: error
// Signals: http.response.status_code gte 500, occurrence_rate > baseline * 3
// Hypothesis: Server error spike. Check recent deployments and upstream dependencies.
// Confidence: 0.75
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: deployment_regression
// Category: error
// Signals: error_type exists, first_seen_at > last_deployment_time
// Hypothesis: New error class after deployment. Compare with previous version.
// Confidence: 0.80
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: cascading_timeout
// Category: latency
// Signals: exception_type contains Timeout, downstream_service_error=true
// Hypothesis: Upstream failure causing downstream timeouts. Investigate root service first.
// Confidence: 0.70
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: memory_pressure_latency
// Category: latency
// Signals: process.runtime.dotnet.gc.duration gt 100, avg_latency > p99_baseline
// Hypothesis: GC pressure causing latency. Check memory allocation patterns.
// Confidence: 0.65
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: cost_spike
// Category: cost
// Signals: gen_ai_cost_usd > daily_average * 3
// Hypothesis: Abnormal cost increase. Identify the model, service, and session responsible.
// Confidence: 0.75
// ---------------------------------------------------------------------------

// =============================================================================
// Agent behavioral failure patterns (AgentRx taxonomy)
// Source: Microsoft Research AgentRx, March 2026
// 9 failure categories from Magentic-One and TAU-Retail benchmarks
// =============================================================================

// ---------------------------------------------------------------------------
// Pattern: agent_intent_plan_misalignment
// Category: agent
// Signals: gen_ai.agent.name exists, gen_ai.operation.name=invoke_agent, status_code=2
// Hypothesis: Agent plan diverges from user intent. Review task decomposition.
// Confidence: 0.70
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: agent_misinterpret_tool_info
// Category: agent
// Signals: gen_ai.tool.name exists, gen_ai.tool.call.id exists, error_type contains tool
// Hypothesis: Agent misinterpreted tool output or schema.
// Confidence: 0.75
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: agent_rai_policy_violation
// Category: agent
// Signals: gen_ai.agent.name exists, gen_ai.stop_reason contains content_filter
// Hypothesis: Agent triggered responsible AI policy violation.
// Confidence: 0.95
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: agent_plan_adherence_failure
// Category: agent
// Signals: gen_ai.agent.name exists, gen_ai.operation.name=invoke_agent, gen_ai.usage.output_tokens>0, child_span_count>20
// Hypothesis: Agent deviated from its own plan. Excessive tool calls suggest improvisation.
// Confidence: 0.65
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: agent_invent_new_info
// Category: agent
// Signals: gen_ai.agent.name exists, gen_ai.operation.name=invoke_agent
// Hypothesis: Agent fabricated information not in tool outputs. Cross-reference claims vs results.
// Confidence: 0.60
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: agent_invalid_invocation
// Category: agent
// Signals: gen_ai.tool.name exists, error_type contains invalid, gen_ai.agent.name exists
// Hypothesis: Agent called tool with invalid arguments or nonexistent name.
// Confidence: 0.85
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: agent_hallucination_doubt
// Category: agent
// Signals: gen_ai.agent.name exists, gen_ai.usage.output_tokens>500, gen_ai.tool.call.id not_exists
// Hypothesis: Long response without tool grounding. High hallucination risk.
// Confidence: 0.55
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: agent_instruction_adherence_failure
// Category: agent
// Signals: gen_ai.agent.name exists, gen_ai.operation.name=invoke_agent
// Hypothesis: Agent ignored or contradicted system prompt constraints.
// Confidence: 0.60
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pattern: agent_underspecified_intent
// Category: agent
// Signals: gen_ai.agent.name exists, gen_ai.operation.name=invoke_agent, gen_ai.usage.input_tokens<50
// Hypothesis: Ambiguous request with insufficient context for reliable execution.
// Confidence: 0.65
// ---------------------------------------------------------------------------
