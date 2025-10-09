# Document Drive Architecture

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Projects Show Page (Phoenix LiveView)                           │
│  ├── Overview Tab                                                │
│  ├── Subprojects Tab                                             │
│  ├── Bill of Materials Tab                                       │
│  └── Documents Tab ⭐ NEW                                        │
│      ├── Document List                                           │
│      │   ├── Name, Size, Visibility, Uploader, Date             │
│      │   ├── View Action (opens in browser)                     │
│      │   └── Delete Action (if authorized)                      │
│      └── Upload Button (opens modal)                            │
│                                                                   │
│  Upload Modal (Phoenix LiveComponent)                            │
│  ├── Document Name Input                                         │
│  ├── Visibility Selector (Public/Private)                        │
│  ├── File Upload (drag & drop, up to 50MB)                      │
│  └── Submit Button                                               │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Application Layer                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Aura.Documents Context ⭐ NEW                                   │
│  ├── list_project_documents/3   (with access filtering)         │
│  ├── get_document_with_access/2 (permission check)              │
│  ├── create_document/2          (with audit log)                │
│  ├── update_document/3          (only uploader/admin)           │
│  ├── soft_delete_document/2     (marks for cleanup)             │
│  ├── add_document_viewer/3      (grant access)                  │
│  ├── remove_document_viewer/3   (revoke access)                 │
│  ├── log_document_view/2        (audit trail)                   │
│  └── store_file/3               (delegates to storage)          │
│                                                                   │
│  Document Controller ⭐ NEW                                      │
│  └── view/2 (streams document to browser)                       │
│                                                                   │
│  Background Jobs                                                 │
│  └── Aura.Documents.Cleaner ⭐ NEW                              │
│      ├── Runs every 24 hours                                    │
│      ├── Finds documents soft-deleted > 30 days                 │
│      └── Permanently deletes (DB + storage)                     │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│   Storage Layer          │  │    Database Layer        │
├──────────────────────────┤  ├──────────────────────────┤
│                          │  │                          │
│ Storage Behaviour ⭐     │  │ project_documents ⭐     │
│ (Pluggable Interface)    │  │ ├── id (UUID)            │
│                          │  │ ├── name                 │
│ Implementations:         │  │ ├── file_path            │
│                          │  │ ├── visibility           │
│ Local Adapter ⭐         │  │ ├── mime_type            │
│ ├── store()              │  │ ├── size                 │
│ ├── retrieve()           │  │ ├── soft_deleted_at      │
│ ├── delete()             │  │ ├── project_id (FK)      │
│ └── stream()             │  │ └── uploader_id (FK)     │
│                          │  │                          │
│ Future: S3 Adapter       │  │ document_viewers ⭐      │
│ Future: Azure Adapter    │  │ ├── id (UUID)            │
│                          │  │ ├── document_id (FK)     │
│ Storage Location:        │  │ └── user_id (FK)         │
│ └── priv/storage/        │  │                          │
│     └── documents/       │  │ document_audit_logs ⭐   │
│         └── {project_id}/│  │ ├── id (UUID)            │
│             └── {uuid}   │  │ ├── action (enum)        │
│                          │  │ ├── metadata (jsonb)     │
│                          │  │ ├── document_id (FK)     │
│                          │  │ └── user_id (FK)         │
│                          │  │                          │
└──────────────────────────┘  └──────────────────────────┘
```

## Data Flow Diagrams

### Document Upload Flow

```
User fills upload form
         │
         ▼
LiveComponent validates
         │
         ▼
File uploaded to LiveView socket
         │
         ▼
consume_uploaded_entries()
         │
         ▼
Storage.Local.store(file, destination)
         │
         ├─── Copy file to priv/storage/documents/{project_id}/{uuid}
         └─── Return storage path
         │
         ▼
Documents.create_document(scope, attrs)
         │
         ├─── Check "upload_document" permission
         ├─── Insert into project_documents table
         └─── Log "upload" action to audit_logs
         │
         ▼
Notify parent LiveView
         │
         ▼
Refresh documents list
         │
         ▼
Close modal, show success flash
```

### Document View Flow

```
User clicks "View" link
         │
         ▼
DocumentController.view(conn, params)
         │
         ├─── Get document by ID
         ├─── Check access permission
         │    ├─── Public document? → Allow
         │    ├─── Uploader? → Allow
         │    └─── In viewers list? → Allow
         │
         ├─── Log "view" action to audit_logs
         │
         ├─── Storage.Local.stream(file_path)
         │    └─── Create file stream
         │
         └─── Stream chunks to browser
              ├─── Set Content-Type header
              ├─── Set Content-Disposition: inline
              └─── Send chunked response
```

### Document Delete Flow

```
User clicks "Delete" button
         │
         ▼
ProjectsLive.Show.handle_event("delete_document")
         │
         ▼
Documents.soft_delete_document(scope, document)
         │
         ├─── Check authorization
         │    ├─── Is admin? → Allow
         │    ├─── Is uploader? → Check "delete_document" permission
         │    └─── Otherwise → Deny
         │
         ├─── Update soft_deleted_at = now()
         └─── Log "delete" action to audit_logs
         │
         ▼
Refresh documents list (soft-deleted docs hidden)
         │
         ▼
Show success flash
```

### Automated Cleanup Flow

```
Every 24 hours
         │
         ▼
Documents.Cleaner.cleanup_documents()
         │
         ▼
Find documents where soft_deleted_at < (now - 30 days)
         │
         ▼
For each document:
         │
         ├─── Documents.delete_document_permanently(document)
         │    │
         │    ├─── Delete from database (cascades to viewers & audit_logs)
         │    └─── Storage.Local.delete(file_path)
         │         └─── Remove file from filesystem
         │
         └─── Log cleanup operation
```

## Access Control Matrix

| Action                | Public Document | Private Document (Not Viewer) | Private Document (Viewer) | Uploader | Admin |
|-----------------------|-----------------|-------------------------------|---------------------------|----------|-------|
| View                  | ✅              | ❌                            | ✅                        | ✅       | ✅    |
| Upload                | ✅ (with perm)  | ✅ (with perm)                | ✅ (with perm)            | ✅       | ✅    |
| Update                | ❌              | ❌                            | ❌                        | ✅       | ✅    |
| Delete                | ❌              | ❌                            | ❌                        | ✅       | ✅    |
| Add Viewer            | N/A             | ❌                            | ❌                        | ✅       | ✅    |
| Remove Viewer         | N/A             | ❌                            | ❌                        | ✅       | ✅    |

## Permission Requirements

| Permission              | Required For                                    |
|-------------------------|-------------------------------------------------|
| `upload_document`       | Uploading documents                             |
| `view_document`         | Viewing documents (checked with visibility)     |
| `update_document`       | Updating document metadata (if uploader/admin)  |
| `delete_document`       | Deleting documents (if uploader/admin)          |
| `manage_document_viewers`| Adding/removing viewers (if uploader/admin)    |
| `system_admin`          | Bypass uploader check for all operations        |

## Audit Trail Events

| Action         | Logged When                                | Metadata Captured           |
|----------------|--------------------------------------------|-----------------------------|
| `upload`       | Document is uploaded                       | -                           |
| `view`         | Document is viewed                         | -                           |
| `update`       | Document metadata is updated               | Changed fields              |
| `delete`       | Document is soft-deleted                   | -                           |
| `restore`      | Document is restored (future feature)      | -                           |
| `add_viewer`   | User is granted access to private document | `viewer_user_id`            |
| `remove_viewer`| User access is revoked                     | `viewer_user_id`            |

## Configuration Options

```elixir
# config/config.exs
config :aura,
  # Storage adapter (default: Aura.Storage.Local)
  storage_adapter: Aura.Storage.Local,
  
  # Base path for local storage (default: "priv/storage")
  storage_path: "priv/storage",
  
  # Days before permanent deletion (default: 30)
  document_cleanup_days: 30

# Future S3 configuration example:
# config :aura,
#   storage_adapter: Aura.Storage.S3,
#   s3_bucket: "my-documents-bucket",
#   s3_region: "us-east-1"
```

## Security Considerations

1. **No Downloads**: Documents are streamed with `Content-Disposition: inline` to prevent downloads
2. **Access Verification**: Every view is checked against visibility and viewer permissions
3. **Audit Trail**: All actions are logged with user ID and timestamp
4. **Soft Delete**: 30-day grace period allows recovery of accidentally deleted documents
5. **Permission Checks**: All operations require appropriate permissions
6. **File Validation**: File size limited to 50MB (configurable)
7. **Secure Storage**: Files stored outside web root (priv/storage/)
8. **Path Traversal Protection**: File paths validated by storage adapter

## Extension Points

### Adding a New Storage Adapter

1. Create a new module (e.g., `Aura.Storage.S3`)
2. Implement the `Aura.Storage.Behaviour` callbacks:
   - `store/3` - Upload file to S3
   - `retrieve/2` - Download file from S3 (if needed)
   - `delete/2` - Delete file from S3
   - `stream/2` - Stream file from S3
3. Update configuration to use new adapter

### Adding Document Features

All features can be added by extending the existing modules:

- **Versioning**: Add `document_versions` table
- **Comments**: Add `document_comments` table
- **Categories**: Add `category` field to documents
- **Expiry**: Add `expires_at` field to documents
- **Sharing**: Add `document_shares` table for temporary links
- **Preview**: Add `preview_path` field for thumbnails
