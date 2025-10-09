# Document Drive Implementation Summary

This document summarizes the implementation of the Document Drive feature for the Aura project management system.

## Overview

The Document Drive feature allows each project to have its own document storage, with fine-grained access control, audit logging, and automated cleanup of deleted documents.

## Key Features Implemented

### 1. Pluggable Storage Infrastructure
- **Storage Behaviour** (`Aura.Storage.Behaviour`): Defines the interface for storage adapters
- **Local Storage Adapter** (`Aura.Storage.Local`): Implements local filesystem storage
- **Extensible Design**: Easy to add S3, Azure Blob Storage, or other backends

### 2. Database Schema
Three new tables were added:

#### `project_documents`
- Stores document metadata
- Tracks: name, file path, visibility (public/private), MIME type, size
- Supports soft deletion with `soft_deleted_at` timestamp
- Belongs to project and uploader (user)

#### `document_viewers`
- Junction table for access control
- Links users to private documents they can view
- Enforces unique constraint to prevent duplicate permissions

#### `document_audit_logs`
- Complete audit trail of all document actions
- Tracks: view, upload, update, delete, restore, add_viewer, remove_viewer
- Immutable logs (no updated_at timestamp)

### 3. Business Logic (`Aura.Documents` Context)
Comprehensive API for document management:

- **CRUD Operations**: Create, read, update, soft delete documents
- **Access Control**: Filter documents by visibility and viewer permissions
- **Authorization**: Integrates with existing permission system
- **Audit Logging**: Automatic logging of all document actions
- **File Storage**: Abstracted through storage adapter interface
- **Cleanup**: Query for documents ready for permanent deletion

### 4. User Interface
Enhanced the Projects Show page with a new "Documents" tab:

#### Document List View
- Displays all documents the user has access to
- Shows: name, size, visibility, uploader, upload date
- Actions: View (in browser), Delete (if authorized)

#### Document Upload
- Modal form for uploading new documents
- Fields: name, visibility (public/private), file selection
- Drag-and-drop support
- File size limit: 50MB
- Real-time validation

#### Document Viewing
- Streams documents to browser (no download option)
- Logs every view in audit trail
- Respects access permissions

### 5. Permissions System
Five new permissions added:

- `upload_document`: Upload documents to projects
- `view_document`: View project documents
- `update_document`: Update document metadata
- `delete_document`: Delete documents (only uploader or admin)
- `manage_document_viewers`: Manage private document access

### 6. Automated Cleanup
Background job (`Aura.Documents.Cleaner`):

- Runs daily (configurable interval)
- Permanently deletes soft-deleted documents after 30 days (configurable)
- Removes both database records and physical files
- Logs cleanup operations

### 7. Security Features
- **No Downloads**: Documents are streamed for viewing only (disallow download requirement)
- **Access Control**: Public vs. private visibility with granular viewer management
- **Authorization Checks**: Only uploader or admin can delete
- **Audit Trail**: Complete logging of views and modifications
- **Soft Delete**: 30-day grace period before permanent deletion

## File Structure

```
lib/aura/
├── documents/
│   ├── document.ex              # Main document schema
│   ├── document_viewer.ex       # Viewer junction table schema
│   ├── document_audit_log.ex    # Audit log schema
│   ├── cleaner.ex              # Cleanup GenServer
│   └── README.md               # Usage documentation
├── documents.ex                # Documents context
└── storage/
    ├── behaviour.ex            # Storage adapter behaviour
    └── local.ex               # Local filesystem adapter

lib/aura_web/
├── controllers/
│   └── document_controller.ex  # Document streaming controller
└── live/
    ├── documents_live/
    │   └── upload_component.ex # Document upload LiveComponent
    └── projects_live/
        ├── show.ex            # Enhanced with documents support
        └── show.html.heex     # Added documents tab

priv/repo/migrations/
└── 20251009041858_create_project_documents_tables.exs
```

## Configuration

Added to `config/config.exs`:

```elixir
config :aura,
  storage_adapter: Aura.Storage.Local,
  storage_path: "priv/storage",
  document_cleanup_days: 30
```

## Routes Added

```elixir
# LiveView routes (authenticated)
live "/projects/:id/documents", ProjectsLive.Show, :show
live "/projects/:id/documents/upload", ProjectsLive.Show, :upload_document

# Controller route for document viewing
get "/projects/:project_id/documents/:id/view", AuraWeb.DocumentController, :view
```

## Integration Points

### With Projects
- Added `has_many :documents` relationship to `Aura.Projects.Project`
- Documents tab integrated into project show page
- Documents are deleted when project is deleted (cascade)

### With Accounts
- Uses existing `Scope` for authorization
- Leverages permission system for access control
- Tracks uploader and viewers via user relationships

### Application Supervision
- `Aura.Documents.Cleaner` added to supervision tree
- Starts automatically with application

## Future Enhancements

The following features can be easily added:

1. **S3 Storage Adapter**: Implement `Aura.Storage.S3` behaviour
2. **Document Versioning**: Track document revisions
3. **Document Comments**: Allow users to comment on documents
4. **Document Search**: Full-text search across documents
5. **Document Categories**: Organize documents by category/type
6. **Bulk Operations**: Upload/delete multiple documents
7. **Document Expiry**: Auto-delete documents after specified period
8. **Document Sharing**: Generate temporary share links
9. **Download Option**: Add permission-based download capability
10. **Document Preview**: Generate thumbnails for common file types

## Testing Considerations

While tests were not added (per project guidelines), the following should be tested:

- Document upload with various file types and sizes
- Access control (public vs private documents)
- Viewer management (add/remove viewers)
- Soft delete and recovery
- Automated cleanup process
- Document streaming and viewing
- Audit log creation
- Permission enforcement
- Storage adapter functionality

## Notes

- The implementation follows Phoenix and Elixir best practices
- Uses existing patterns from the codebase (similar to Projects, Subprojects, BOM)
- Minimal changes to existing code (only added, never removed functionality)
- Fully integrated with existing authentication and authorization system
- Storage path (`priv/storage/`) is gitignored to prevent accidental commits
