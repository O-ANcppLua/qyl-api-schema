// =============================================================================
// ANcpLua v2.0 - Unified Search Entities
// =============================================================================
// Search documents, inverted index, query telemetry.
// =============================================================================

import "@typespec/openapi";
import "../common/types.tsp";

using TypeSpec.OpenAPI;
using Qyl.Api.Contracts.Common;

namespace Qyl.Api.Contracts.Domains.Search;

// =============================================================================
// Search Document
// =============================================================================

@doc("Canonical search document across all entity types")
@extension("x-csharp-type", "SearchDocumentEntity")
model SearchDocumentEntity {
  @doc("Document ID")
  @key
  id: string;

  @doc("Source entity type (span, log, issue, workflow, etc.)")
  @encodedName("application/json", "entity_type")
  entityType: SearchEntityType;

  @doc("Source entity ID")
  @encodedName("application/json", "entity_id")
  entityId: string;

  @doc("Owning project")
  @encodedName("application/json", "project_id")
  projectId?: string;

  @doc("Document title")
  title: string;

  @doc("Document body (searchable text)")
  body?: string;

  @doc("Link to source entity")
  url?: string;

  @doc("Document tags")
  @encodedName("application/json", "tags_json")
  tagsJson?: string;

  @doc("Additional metadata")
  @encodedName("application/json", "metadata_json")
  metadataJson?: string;

  @doc("Relevance boost factor")
  boost: float64;

  @doc("Last indexed timestamp")
  @encodedName("application/json", "indexed_at")
  indexedAt: utcDateTime;

  @doc("Last update timestamp")
  @encodedName("application/json", "updated_at")
  updatedAt: utcDateTime;
}

@doc("Searchable entity types")
enum SearchEntityType {
  @doc("Trace/span")
  span: "span",

  @doc("Log entry")
  log: "log",

  @doc("Error issue")
  issue: "issue",

  @doc("Workflow run")
  workflow: "workflow",

  @doc("Deployment")
  deployment: "deployment",

  @doc("Session")
  session: "session",

  @doc("Alert")
  alert: "alert",

  @doc("Fix run")
  fix: "fix",
}

// =============================================================================
// Search Term (Inverted Index)
// =============================================================================

@doc("Inverted token index entry")
@extension("x-csharp-type", "SearchTermEntity")
model SearchTermEntity {
  @doc("Normalized term")
  term: string;

  @doc("Document containing this term")
  @encodedName("application/json", "document_id")
  documentId: string;

  @doc("Field where term appears (title, body, tags)")
  field: string;

  @doc("Term frequency in this document/field")
  @encodedName("application/json", "term_frequency")
  termFrequency: int32;

  @doc("Position offsets for highlighting")
  @encodedName("application/json", "position_offsets_json")
  positionOffsetsJson?: string;
}

// =============================================================================
// Search Query Audit
// =============================================================================

@doc("Search query telemetry entry")
@extension("x-csharp-type", "SearchQueryAuditEntity")
model SearchQueryAuditEntity {
  @doc("Audit entry ID")
  @key
  id: string;

  @doc("Search query text")
  @encodedName("application/json", "query_text")
  queryText: string;

  @doc("Query type")
  @encodedName("application/json", "query_type")
  queryType: string;

  @doc("Filtered entity types")
  @encodedName("application/json", "entity_types_json")
  entityTypesJson?: string;

  @doc("Project scope")
  @encodedName("application/json", "project_id")
  projectId?: string;

  @doc("Number of results returned")
  @encodedName("application/json", "result_count")
  resultCount: int32;

  @doc("Clicked result document ID")
  @encodedName("application/json", "clicked_result_id")
  clickedResultId?: string;

  @doc("Position of clicked result")
  @encodedName("application/json", "clicked_position")
  clickedPosition?: int32;

  @doc("Query execution time in ms")
  @encodedName("application/json", "duration_ms")
  durationMs?: int32;

  @doc("Querying user")
  @encodedName("application/json", "user_id")
  userId?: string;

  @doc("Query timestamp")
  timestamp: utcDateTime;
}

// =============================================================================
// Search Request/Response (API models, not stored)
// =============================================================================

@doc("Unified search request")
model SearchRequest {
  @doc("Search query text")
  query: string;

  @doc("Entity type filters")
  @encodedName("application/json", "entity_types")
  entityTypes?: SearchEntityType[];

  @doc("Project scope")
  @encodedName("application/json", "project_id")
  projectId?: string;

  @doc("Maximum results")
  @minValue(1)
  @maxValue(100)
  limit?: int32 = 20;

  @doc("Cursor for pagination")
  cursor?: string;
}

@doc("Unified search response")
model SearchResponse {
  @doc("Search results")
  results: SearchResult[];

  @doc("Total matching documents")
  @encodedName("application/json", "total_count")
  totalCount: int64;

  @doc("Query execution time in ms")
  @encodedName("application/json", "duration_ms")
  durationMs: int32;

  @doc("Next page cursor")
  @encodedName("application/json", "next_cursor")
  nextCursor?: string;

  @doc("Search suggestions")
  suggestions?: string[];
}

@doc("Individual search result")
model SearchResult {
  @doc("Document ID")
  @encodedName("application/json", "document_id")
  documentId: string;

  @doc("Entity type")
  @encodedName("application/json", "entity_type")
  entityType: SearchEntityType;

  @doc("Entity ID")
  @encodedName("application/json", "entity_id")
  entityId: string;

  @doc("Result title")
  title: string;

  @doc("Result snippet with highlights")
  snippet?: string;

  @doc("Relevance score")
  score: float64;

  @doc("Link to entity")
  url?: string;
}
