# BOM Import Feature Architecture

## Overview

This document describes the architecture of the dependency manifest import feature.

## Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        User Interface                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  BOMFormComponent (LiveView Component)                 │ │
│  │  - File upload UI                                      │ │
│  │  - Progress display                                    │ │
│  │  - Success/error feedback                              │ │
│  └────────────────────────────────────────────────────────┘ │
│                            │                                  │
│                            ▼                                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     API Layer (Optional)                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  BOMWebhookController                                  │ │
│  │  POST /api/webhooks/bom/:project_id                    │ │
│  │  - Receives JSON payload                               │ │
│  │  - Validates request                                   │ │
│  │  - Returns JSON response                               │ │
│  └────────────────────────────────────────────────────────┘ │
│                            │                                  │
│                            ▼                                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      Business Logic                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Projects Context                                      │ │
│  │  - import_bom_from_manifest/3                          │ │
│  │  - create_bom_entries_from_dependencies/2              │ │
│  │  - create_project_bom/1                                │ │
│  └────────────────────────────────────────────────────────┘ │
│                            │                                  │
│                            ▼                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  DependencyParser                                      │ │
│  │  - parse/2                                             │ │
│  │  - parse_mix_lock/1                                    │ │
│  │  - parse_package_json/1                                │ │
│  └────────────────────────────────────────────────────────┘ │
│                            │                                  │
│                            ▼                                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  ProjectBOM Schema                                     │ │
│  │  - id                                                  │ │
│  │  - tool_name                                           │ │
│  │  - version                                             │ │
│  │  - architecture (optional)                             │ │
│  │  - purpose (optional)                                  │ │
│  │  - project_id                                          │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Manual Upload Flow

```
1. User clicks "Add BOM Entry"
   │
   ▼
2. Modal opens with BOMFormComponent
   │
   ▼
3. User selects manifest file (mix.lock or package.json)
   │
   ▼
4. LiveView uploads file via Phoenix.LiveView.Upload
   │
   ▼
5. User clicks "Import Dependencies"
   │
   ▼
6. BOMFormComponent.handle_event("import_manifest")
   │
   ├─→ consume_uploaded_entries/3 - reads file content
   │
   ▼
7. Projects.import_bom_from_manifest/3
   │
   ├─→ DependencyParser.parse/2 - detects format and parses
   │   │
   │   ├─→ parse_mix_lock/1 OR parse_package_json/1
   │   │   - Extracts name and version for each dependency
   │   │
   │   └─→ Returns {:ok, [%{name: ..., version: ...}]}
   │
   ▼
8. Projects.create_bom_entries_from_dependencies/2
   │
   ├─→ For each dependency:
   │   └─→ Projects.create_project_bom/1
   │       └─→ Insert into database
   │
   ▼
9. Returns {:ok, %{created: N, failed: M, errors: [...]}}
   │
   ▼
10. UI updates with success message
    └─→ BOM table refreshed with new entries
```

### Webhook API Flow

```
1. Build tool/CI/CD triggers
   │
   ▼
2. HTTP POST to /api/webhooks/bom/:project_id
   │
   ├─→ Headers: Content-Type: application/json
   ├─→ Body: {"manifest": {"filename": "...", "content": "..."}}
   │
   ▼
3. BOMWebhookController.import/2
   │
   ├─→ Validates authentication
   ├─→ Extracts filename and content
   │
   ▼
4. Projects.import_bom_from_manifest/3
   │
   └─→ [Same parsing flow as manual upload]
   │
   ▼
5. Returns JSON response
   │
   ├─→ Success: {"success": true, "created": N, "failed": M}
   └─→ Error: {"success": false, "error": "..."}
```

## File Format Support

### mix.lock (Elixir)

**Format:**
```elixir
%{
  "package_name" => {:hex, :package_name, "version", "hash", [...], [...], "hexpm", ...}
}
```

**Parsing Strategy:**
1. Use `Code.eval_string/1` to parse Elixir term
2. Enumerate map entries
3. Extract package name (key) and version (3rd element of tuple)
4. Filter entries without valid versions

### package.json (Node.js)

**Format:**
```json
{
  "dependencies": {
    "package": "^1.0.0"
  },
  "devDependencies": {
    "dev-package": "~2.0.0"
  }
}
```

**Parsing Strategy:**
1. Use `Jason.decode/1` to parse JSON
2. Extract `dependencies` and `devDependencies` maps
3. For each entry, clean version string (remove ^, ~, >=, etc.)
4. Return list of all dependencies

## Error Handling

```
Parse Error
  ├─→ Invalid format: {:error, :unsupported_format}
  ├─→ Syntax error: {:error, "Failed to parse..."}
  └─→ Empty file: {:ok, []} (0 dependencies)

Creation Error
  ├─→ Duplicate entry: Continues, counts as failed
  ├─→ Validation error: Continues, counts as failed
  └─→ Returns summary: %{created: N, failed: M, errors: [...]}

UI Display
  ├─→ Success: Green alert with count
  ├─→ Partial: Green alert with count + warning for failures
  └─→ Error: Red alert with message
```

## Extension Points

### Adding New Format Support

To add support for a new manifest format:

1. **Update DependencyParser**
   ```elixir
   # Add to detect_format/1
   String.ends_with?(filename, "requirements.txt") -> :requirements_txt
   
   # Add new parse function
   def parse_requirements_txt(content) do
     # Parse logic
     {:ok, dependencies}
   end
   ```

2. **Update parse/2 case statement**
   ```elixir
   :requirements_txt -> parse_requirements_txt(content)
   ```

3. **Add tests**
   ```elixir
   test "parses requirements.txt" do
     # Test implementation
   end
   ```

4. **Update documentation**
   - BOM_IMPORT_GUIDE.md
   - BOM_WEBHOOK_API.md
   - FEATURES.md

### Adding Authentication for Webhooks

To add token-based authentication:

1. **Create API tokens table**
   ```elixir
   create table(:api_tokens) do
     add :token, :string
     add :user_id, references(:users)
     add :name, :string
     add :last_used_at, :utc_datetime
   end
   ```

2. **Create authentication plug**
   ```elixir
   defmodule AuraWeb.Plugs.APIAuth do
     def call(conn, _opts) do
       # Extract and validate token
     end
   end
   ```

3. **Update API pipeline**
   ```elixir
   pipeline :api_auth do
     plug AuraWeb.Plugs.APIAuth
   end
   ```

## Performance Considerations

- **File Size**: LiveView uploads are buffered to disk, handling large files
- **Parsing**: mix.lock files are typically < 100KB, parse in < 100ms
- **Database**: Bulk insert creates N individual INSERT statements
  - Consider batch insert for very large manifests (>1000 deps)
- **UI**: LiveView streams not used since full BOM refresh is needed

## Security Considerations

1. **File Upload**
   - File size limits enforced by Phoenix LiveView
   - Only text files accepted (.lock, .json)
   - Content parsed, not executed (except mix.lock via Code.eval_string)

2. **API Endpoint**
   - Requires authentication
   - Session-based (ready for token auth)
   - Project ownership verified via permissions

3. **Code Evaluation**
   - mix.lock: Uses `Code.eval_string/1` which is safe for trusted input
   - User uploads are treated as trusted (authenticated users only)
   - Consider sandboxing in future for additional security

## Testing Strategy

1. **Unit Tests** (dependency_parser_test.exs)
   - Parse valid files
   - Handle invalid formats
   - Handle edge cases (empty, malformed)

2. **Integration Tests** (future)
   - Upload file via LiveView
   - Import via API
   - Verify database entries

3. **Manual Testing**
   - Upload real mix.lock from project
   - Upload real package.json
   - Test webhook with curl
