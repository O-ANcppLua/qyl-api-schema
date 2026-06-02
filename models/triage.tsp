// =============================================================================
// ANcpLua v2.0 - Triage Models (Loom Pipeline)
// =============================================================================
// AI-powered triage pipeline: score fixability, summarize, and route errors.
// =============================================================================

import "@typespec/openapi";
import "../common/types.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;

namespace Qyl.Api.Contracts.Domains.Loom.Triage;

// =============================================================================
// Triage Automation Level
// =============================================================================

@doc("Automation level determined by fixability score")
enum TriageAutomationLevel {
  @doc("Auto-fix: score >= 0.8, proceed without human review")
  auto: "auto",

  @doc("Assisted: 0.5 <= score < 0.8, suggest fix with human review")
  assisted: "assisted",

  @doc("Manual: 0.2 <= score < 0.5, provide context but human must fix")
  manual: "manual",

  @doc("Skip: score < 0.2, not actionable for automated fix")
  skip: "skip",
}

// =============================================================================
// Triage Result Entity
// =============================================================================

@doc("AI triage assessment for an error issue")
@TypeSpec.OpenAPI.extension("x-csharp-type", "TriageResultEntity")
model TriageResultEntity {
  @doc("Triage result ID")
  @key
  @encodedName("application/json", "triage_id")
  triageId: string;

  @doc("Associated error issue ID")
  @encodedName("application/json", "issue_id")
  issueId: string;

  @doc("Fixability score (0.0 to 1.0)")
  @encodedName("application/json", "fixability_score")
  fixabilityScore: float64;

  @doc("Automation level derived from score")
  @encodedName("application/json", "automation_level")
  automationLevel: TriageAutomationLevel;

  @doc("AI-generated summary of the issue")
  @encodedName("application/json", "ai_summary")
  aiSummary?: string;

  @doc("Root cause hypothesis from AI analysis")
  @encodedName("application/json", "root_cause_hypothesis")
  rootCauseHypothesis?: string;

  @doc("What triggered this triage")
  @encodedName("application/json", "triggered_by")
  triggeredBy: TriageTrigger;

  @doc("Linked fix run ID (if auto-routed)")
  @encodedName("application/json", "fix_run_id")
  fixRunId?: string;

  @doc("Whether scoring was done by LLM or heuristic fallback")
  @encodedName("application/json", "scoring_method")
  scoringMethod: TriageScoringMethod;

  @doc("When this triage was created")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;
}

// =============================================================================
// Triage Trigger
// =============================================================================

@doc("What triggered the triage assessment")
enum TriageTrigger {
  @doc("New issue created from error ingestion")
  newIssue: "new_issue",

  @doc("Previously resolved issue regressed")
  regression: "regression",

  @doc("Manually triggered by user or agent")
  manual: "manual",

  @doc("Re-triage due to updated context")
  retriage: "retriage",
}

// =============================================================================
// Scoring Method
// =============================================================================

@doc("How the fixability score was determined")
enum TriageScoringMethod {
  @doc("LLM-based structured scoring")
  llm: "llm",

  @doc("Heuristic fallback (no LLM configured)")
  heuristic: "heuristic",
}
