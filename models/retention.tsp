// =============================================================================
// ANcpLua v2.0 - Ops & Retention Entities
// =============================================================================
// Retention policies, compaction state, backfill jobs.
// =============================================================================

import "@typespec/openapi";
import "../common/types.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;

namespace Qyl.Api.Contracts.Domains.Ops.Retention;

// =============================================================================
// Retention Policy
// =============================================================================

@doc("Per-table data retention rule")
@extension("x-csharp-type", "RetentionPolicyEntity")
model RetentionPolicyEntity {
  @doc("Policy ID")
  @key
  id: string;

  @doc("Target DuckDB table")
  @encodedName("application/json", "target_table")
  targetTable: string;

  @doc("Retention period in days")
  @encodedName("application/json", "retention_days")
  retentionDays: int32;

  @doc("Maximum row count (null = unlimited)")
  @encodedName("application/json", "max_row_count")
  maxRowCount?: int64;

  @doc("Cleanup strategy")
  @encodedName("application/json", "cleanup_strategy")
  cleanupStrategy: CleanupStrategy;

  @doc("Last cleanup timestamp")
  @encodedName("application/json", "last_cleanup_at")
  lastCleanupAt?: utcDateTime;

  @doc("Total rows cleaned")
  @encodedName("application/json", "rows_cleaned")
  rowsCleaned: int64;

  @doc("Whether policy is enabled")
  enabled: boolean;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;

  @doc("Last update timestamp")
  @encodedName("application/json", "updated_at")
  updatedAt: utcDateTime;
}

@doc("Data cleanup strategies")
enum CleanupStrategy {
  @doc("Delete old rows")
  delete: "delete",

  @doc("Archive to cold storage")
  archive: "archive",

  @doc("Compact/aggregate old data")
  compact: "compact",
}

// =============================================================================
// Compaction State
// =============================================================================

@doc("DuckDB compaction progress tracker")
@extension("x-csharp-type", "CompactionStateEntity")
model CompactionStateEntity {
  @doc("State ID")
  @key
  id: string;

  @doc("Target DuckDB table")
  @encodedName("application/json", "target_table")
  targetTable: string;

  @doc("High watermark (newest compacted row)")
  @encodedName("application/json", "high_watermark")
  highWatermark?: utcDateTime;

  @doc("Low watermark (oldest retained row)")
  @encodedName("application/json", "low_watermark")
  lowWatermark?: utcDateTime;

  @doc("Total rows compacted")
  @encodedName("application/json", "rows_compacted")
  rowsCompacted: int64;

  @doc("Rows remaining")
  @encodedName("application/json", "rows_remaining")
  rowsRemaining: int64;

  @doc("Last compaction timestamp")
  @encodedName("application/json", "last_compaction_at")
  lastCompactionAt?: utcDateTime;

  @doc("Last compaction duration in ms")
  @encodedName("application/json", "last_duration_ms")
  lastDurationMs?: int32;

  @doc("Next scheduled compaction")
  @encodedName("application/json", "next_scheduled_at")
  nextScheduledAt?: utcDateTime;

  @doc("Compaction status")
  status: CompactionStatus;

  @doc("Creation timestamp")
  @encodedName("application/json", "created_at")
  createdAt: utcDateTime;

  @doc("Last update timestamp")
  @encodedName("application/json", "updated_at")
  updatedAt: utcDateTime;
}

@doc("Compaction status")
enum CompactionStatus {
  @doc("Idle/waiting")
  idle: "idle",

  @doc("Currently compacting")
  running: "running",

  @doc("Scheduled for next run")
  scheduled: "scheduled",

  @doc("Failed")
  failed: "failed",
}

// =============================================================================
// Backfill Job
// =============================================================================

@doc("Bulk data maintenance job (backfill, reindex, repair)")
@extension("x-csharp-type", "BackfillJobEntity")
model BackfillJobEntity {
  @doc("Job ID")
  @key
  id: string;

  @doc("Job type")
  @encodedName("application/json", "job_type")
  jobType: BackfillJobType;

  @doc("Target table")
  @encodedName("application/json", "target_table")
  targetTable: string;

  @doc("Job description")
  description?: string;

  @doc("Row filter")
  @encodedName("application/json", "filter_json")
  filterJson?: string;

  @doc("Job status")
  status: BackfillJobStatus;

  @doc("Error message if failed")
  @encodedName("application/json", "error_message")
  errorMessage?: string;

  @doc("Total rows to process")
  @encodedName("application/json", "total_rows")
  totalRows?: int64;

  @doc("Rows processed so far")
  @encodedName("application/json", "processed_rows")
  processedRows: int64;

  @doc("Progress percentage")
  @encodedName("application/json", "progress_pct")
  progressPct: float64;

  @doc("Queue timestamp")
  @encodedName("application/json", "queued_at")
  queuedAt: utcDateTime;

  @doc("Start timestamp")
  @encodedName("application/json", "started_at")
  startedAt?: utcDateTime;

  @doc("Completion timestamp")
  @encodedName("application/json", "completed_at")
  completedAt?: utcDateTime;

  @doc("Duration in milliseconds")
  @encodedName("application/json", "duration_ms")
  durationMs?: int32;
}

@doc("Backfill job types")
enum BackfillJobType {
  @doc("Backfill missing data")
  backfill: "backfill",

  @doc("Rebuild search index")
  reindex: "reindex",

  @doc("Repair data integrity")
  repair: "repair",

  @doc("Migrate data format")
  migrate: "migrate",
}

@doc("Backfill job status")
enum BackfillJobStatus {
  @doc("Pending execution")
  pending: "pending",

  @doc("Currently running")
  running: "running",

  @doc("Paused")
  paused: "paused",

  @doc("Successfully completed")
  completed: "completed",

  @doc("Failed")
  failed: "failed",

  @doc("Cancelled")
  cancelled: "cancelled",
}
