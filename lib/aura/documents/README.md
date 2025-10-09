# Document Drive

The Document Drive feature provides document storage and management for projects in Aura.

## Features

- **Pluggable Storage**: Support for multiple storage backends (Local filesystem, S3, etc.)
- **Access Control**: Public and private documents with granular viewer permissions
- **Audit Trail**: Complete logging of document views, uploads, and modifications
- **Soft Delete**: Documents are soft-deleted for 30 days before permanent removal
- **Browser Viewing**: Documents are viewed in-browser without download capability
- **Authorization**: Only uploaders or admins can delete documents

## Architecture

### Storage Adapters

The system uses a behaviour-based architecture for storage, defined in `Aura.Storage.Behaviour`. This allows you to swap storage backends without changing application code.

#### Local Storage (Default)

The `Aura.Storage.Local` adapter stores files on the local filesystem in `priv/storage/`.

#### Adding S3 or Other Storage

To add S3 support:

1. Create a new module `Aura.Storage.S3` that implements `Aura.Storage.Behaviour`
2. Update `config/config.exs` to use the new adapter:
   ```elixir
   config :aura,
     storage_adapter: Aura.Storage.S3,
     # ... S3-specific configuration
   ```

### Database Schema

#### project_documents
- Main document table
- Fields: name, file_path, visibility, mime_type, size, soft_deleted_at
- Belongs to: project, uploader (user)

#### document_viewers
- Junction table for private document access control
- Links documents to users who can view them

#### document_audit_logs
- Audit trail for document actions
- Tracks: view, upload, update, delete, restore, add_viewer, remove_viewer

### Context API

The `Aura.Documents` context provides:

- `list_project_documents/3` - List documents for a project (filtered by access)
- `get_document_with_access/2` - Get document if user has access
- `create_document/2` - Upload a new document
- `update_document/3` - Update document metadata
- `soft_delete_document/2` - Soft delete (marks for cleanup)
- `add_document_viewer/3` - Grant access to private document
- `remove_document_viewer/3` - Revoke access to private document
- `log_document_view/2` - Log document access for audit trail

### Permissions

Document operations require the following permissions:

- `upload_document` - Upload documents to projects
- `view_document` - View project documents (checked alongside visibility rules)
- `update_document` - Update document metadata
- `delete_document` - Delete documents (only uploader or admin)
- `manage_document_viewers` - Manage who can view private documents

### Automatic Cleanup

The `Aura.Documents.Cleaner` GenServer runs daily to permanently delete documents that have been soft-deleted for more than 30 days (configurable).

Configuration:
```elixir
config :aura,
  document_cleanup_days: 30  # Adjust as needed
```

## Usage

### Uploading Documents

1. Navigate to a project
2. Click the "Documents" tab
3. Click "Upload Document"
4. Fill in the form:
   - Document name
   - Visibility (public or private)
   - Select file (up to 50MB)
5. Submit

### Viewing Documents

Documents are streamed to the browser for viewing. Downloads are not supported to maintain document security.

### Managing Access

For private documents, the uploader or admin can:
- Add viewers to grant access
- Remove viewers to revoke access

### Deleting Documents

Only the uploader or system admin can delete documents. Deleted documents are soft-deleted and will be permanently removed after 30 days.

## Configuration

In `config/config.exs`:

```elixir
config :aura,
  storage_adapter: Aura.Storage.Local,  # Storage backend
  storage_path: "priv/storage",         # Local storage path
  document_cleanup_days: 30             # Days before permanent deletion
```
