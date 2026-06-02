// =============================================================================
// ANcpLua v2.0 - Test Semantic Conventions (OTel v1.40)
// =============================================================================
// Test execution telemetry attributes.
// =============================================================================

import "@typespec/openapi";
import "../common/types.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;

namespace Qyl.Api.Contracts.Domains.Observe.Test;

// =============================================================================
// Test Attributes
// =============================================================================

@doc("Test case attributes")
model TestAttributes {
  @doc("Test case name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Test.CaseName)
  caseName: string;

  @doc("Test case result")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Test.CaseResultStatus)
  caseResultStatus?: TestResultStatus;

  @doc("Test suite name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Test.SuiteName)
  suiteName?: string;

  @doc("Test suite run status")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Test.SuiteRunStatus)
  suiteRunStatus?: TestSuiteRunStatus;
}

// =============================================================================
// Test Enumerations
// =============================================================================

@doc("Test case result status")
enum TestResultStatus {
  @doc("Test passed")
  pass: "pass",

  @doc("Test failed")
  fail: "fail",
}

@doc("Test suite run status")
enum TestSuiteRunStatus {
  @doc("Suite succeeded")
  success: "success",

  @doc("Suite failed")
  failure: "failure",

  @doc("Suite skipped")
  skipped: "skipped",

  @doc("Suite aborted")
  aborted: "aborted",

  @doc("Suite timed out")
  timedOut: "timed_out",

  @doc("Suite in progress")
  inProgress: "in_progress",
}

// =============================================================================
// Test Run Entity
// =============================================================================

@doc("Test run entity")
@TypeSpec.OpenAPI.extension("x-csharp-type", "TestRunEntity")
model TestRunEntity {
  @doc("Test run ID")
  @key
  @encodedName("application/json", "run_id")
  runId: string;

  @doc("Test suite name")
  @encodedName("application/json", "suite_name")
  suiteName: string;

  @doc("Run status")
  status: TestSuiteRunStatus;

  @doc("Start time")
  @encodedName("application/json", "start_time")
  startTime: utcDateTime;

  @doc("End time")
  @encodedName("application/json", "end_time")
  endTime?: utcDateTime;

  @doc("Duration in milliseconds")
  @encodedName("application/json", "duration_ms")
  durationMs?: int64;

  @doc("Total test count")
  @encodedName("application/json", "total_count")
  totalCount: int32;

  @doc("Passed count")
  @encodedName("application/json", "passed_count")
  passedCount: int32;

  @doc("Failed count")
  @encodedName("application/json", "failed_count")
  failedCount: int32;

  @doc("Skipped count")
  @encodedName("application/json", "skipped_count")
  skippedCount: int32;

  @doc("Flaky count")
  @encodedName("application/json", "flaky_count")
  flakyCount?: int32;

  @doc("Test framework")
  framework?: TestFramework;

  @doc("CI/CD run ID")
  @encodedName("application/json", "cicd_run_id")
  cicdRunId?: string;

  @doc("Git commit SHA")
  @encodedName("application/json", "git_commit")
  gitCommit?: string;

  @doc("Git branch")
  @encodedName("application/json", "git_branch")
  gitBranch?: string;
}

@doc("Test frameworks")
enum TestFramework {
  @doc("Jest")
  jest: "jest",

  @doc("Mocha")
  mocha: "mocha",

  @doc("Vitest")
  vitest: "vitest",

  @doc("Playwright")
  playwright: "playwright",

  @doc("Cypress")
  cypress: "cypress",

  @doc("Selenium")
  selenium: "selenium",

  @doc("pytest")
  pytest: "pytest",

  @doc("unittest")
  unittest: "unittest",

  @doc("JUnit")
  junit: "junit",

  @doc("TestNG")
  testng: "testng",

  @doc("xUnit")
  xunit: "xunit",

  @doc("NUnit")
  nunit: "nunit",

  @doc("MSTest")
  mstest: "mstest",

  @doc("RSpec")
  rspec: "rspec",

  @doc("Go testing")
  goTest: "go_test",

  @doc("Rust cargo test")
  cargoTest: "cargo_test",

  @doc("Other")
  other: "other",
}

// =============================================================================
// Test Case Entity
// =============================================================================

@doc("Test case entity")
@TypeSpec.OpenAPI.extension("x-csharp-type", "TestCaseEntity")
model TestCaseEntity {
  @doc("Test case ID")
  @key
  @encodedName("application/json", "case_id")
  caseId: string;

  @doc("Test run ID")
  @encodedName("application/json", "run_id")
  runId: string;

  @doc("Test case name")
  name: string;

  @doc("Test file path")
  @encodedName("application/json", "file_path")
  filePath?: string;

  @doc("Result status")
  status: TestResultStatus;

  @doc("Duration in milliseconds")
  @encodedName("application/json", "duration_ms")
  durationMs?: int64;

  @doc("Error message (if failed)")
  @encodedName("application/json", "error_message")
  errorMessage?: string;

  @doc("Error stack trace")
  @encodedName("application/json", "stack_trace")
  stackTrace?: string;

  @doc("Retry count")
  @encodedName("application/json", "retry_count")
  retryCount?: int32;

  @doc("Is flaky")
  @encodedName("application/json", "is_flaky")
  isFlaky?: boolean;

  @doc("Tags")
  tags?: string[];
}

// =============================================================================
// Test Metrics
// =============================================================================

@doc("Test run count metric")
model TestRunCountMetric {
  @doc("Metric name")
  name: "test.runs";

  @doc("Metric unit")
  unit: "{run}";

  @doc("Suite name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Test.SuiteName)
  suiteName: string;

  @doc("Status")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Test.SuiteRunStatus)
  status: TestSuiteRunStatus;
}

@doc("Test case count metric")
model TestCaseCountMetric {
  @doc("Metric name")
  name: "test.cases";

  @doc("Metric unit")
  unit: "{test}";

  @doc("Suite name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Test.SuiteName)
  suiteName: string;

  @doc("Result status")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Test.CaseResultStatus)
  resultStatus: TestResultStatus;
}

@doc("Test duration metric")
model TestDurationMetric {
  @doc("Metric name")
  name: "test.duration";

  @doc("Metric unit (seconds)")
  unit: "s";

  @doc("Suite name")
  @encodedName("application/json", ANcpLua.OpenTelemetry.SemanticConventions.Keys.Test.SuiteName)
  suiteName: string;
}

// =============================================================================
// Test Coverage
// =============================================================================

@doc("Code coverage report")
model CoverageReport {
  @doc("Run ID")
  @encodedName("application/json", "run_id")
  runId: string;

  @doc("Overall line coverage")
  @encodedName("application/json", "line_coverage")
  lineCoverage: Percentage;

  @doc("Overall branch coverage")
  @encodedName("application/json", "branch_coverage")
  branchCoverage?: Percentage;

  @doc("Overall function coverage")
  @encodedName("application/json", "function_coverage")
  functionCoverage?: Percentage;

  @doc("Statement coverage")
  @encodedName("application/json", "statement_coverage")
  statementCoverage?: Percentage;

  @doc("Coverage by file")
  @encodedName("application/json", "by_file")
  byFile?: FileCoverage[];
}

@doc("File coverage")
model FileCoverage {
  @doc("File path")
  @encodedName("application/json", "file_path")
  filePath: string;

  @doc("Line coverage")
  @encodedName("application/json", "line_coverage")
  lineCoverage: Percentage;

  @doc("Covered lines")
  @encodedName("application/json", "covered_lines")
  coveredLines: int32;

  @doc("Total lines")
  @encodedName("application/json", "total_lines")
  totalLines: int32;

  @doc("Uncovered line numbers")
  @encodedName("application/json", "uncovered_lines")
  uncoveredLines?: int32[];
}
