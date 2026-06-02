// =============================================================================
// ANcpLua v2.0 - Seed Investigation Strategies (v1)
// =============================================================================
// 4 initial investigation strategies. Source: specs/telemetry-intelligence.md §5.3
// These compile to static registries in InvestigationStrategies.g.cs.
//
// Trigger patterns use category:X syntax for category-wide triggers.
// Query templates are abstract qyl investigation hints; the runtime decides how to execute them.
// =============================================================================

namespace Qyl.Api.Contracts.Intelligence.Seed;

// ---------------------------------------------------------------------------
// Strategy: investigate_error_issue
// Trigger: category:error (any error category pattern)
// Steps:
//   1. get_issue — SELECT * FROM error_issues WHERE id = ?
//   2. get_events — SELECT * FROM error_issue_events WHERE issue_id = ? ORDER BY timestamp DESC LIMIT 10
//   3. get_traces — SELECT * FROM spans WHERE trace_id IN (?) ORDER BY start_time_unix_nano
//   4. get_code_location — SELECT code_filepath, code_function, code_lineno FROM spans WHERE span_id = ?
//   5. correlate_deployment — SELECT * FROM deployments WHERE service_name = ? AND start_time <= ? ORDER BY start_time DESC LIMIT 1
//   6. check_fix_history — SELECT * FROM fix_runs WHERE issue_id = ?
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Strategy: investigate_latency
// Trigger: category:latency (any latency category pattern)
// Steps:
//   1. identify_service — SELECT service_name, AVG(duration_ns), PERCENTILE_CONT(0.99) ... GROUP BY service_name
//   2. compare_distributions — SELECT duration_ns FROM spans WHERE service_name = ? AND start_time BETWEEN ? AND ?
//   3. find_regression_window — Time-series analysis of p99 latency
//   4. correlate_deployment — SELECT * FROM deployments WHERE service_name = ? AND start_time <= ? ORDER BY start_time DESC LIMIT 1
//   5. inspect_slow_spans — SELECT * FROM spans WHERE service_name = ? AND duration_ns > ? ORDER BY duration_ns DESC LIMIT 20
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Strategy: investigate_cost
// Trigger: category:cost (any cost category pattern)
// Steps:
//   1. identify_model — SELECT gen_ai_request_model, SUM(gen_ai_cost_usd) ... GROUP BY gen_ai_request_model
//   2. identify_service — SELECT service_name, SUM(gen_ai_cost_usd) ... GROUP BY service_name
//   3. identify_session — SELECT session_id, SUM(gen_ai_cost_usd) ... GROUP BY session_id ORDER BY 2 DESC
//   4. trace_to_root — Follow session → traces → spans
//   5. compare_to_baseline — Compare current period vs previous period
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Strategy: investigate_genai
// Trigger: category:genai (any genai category pattern)
// Steps:
//   1. get_error_details — SELECT * FROM spans WHERE status_code = 2 AND gen_ai_provider_name IS NOT NULL
//   2. check_provider_status — Evaluate gen_ai_provider_name + error frequency
//   3. analyze_token_usage — SELECT gen_ai_input_tokens, gen_ai_output_tokens FROM spans WHERE gen_ai_request_model = ?
//   4. check_prompt_patterns — Inspect spans around the error for prompt size trends
//   5. suggest_mitigation — Pattern-specific recommendation
// ---------------------------------------------------------------------------
