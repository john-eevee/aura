# Aura Features

## Bill of Materials (BOM) Management

### Manual Entry
Create BOM entries one at a time with full control over:
- Tool/Package name
- Version
- Architecture (x64, ARM64, x86, ARM32)
- Purpose/Description

### Bulk Import from Manifest Files
Upload dependency manifest files to automatically populate your BOM:

**Supported Formats:**
- `mix.lock` (Elixir/Phoenix projects)
- `package.json` (Node.js projects)

**How it works:**
1. Navigate to your project's BOM tab
2. Click "Add BOM Entry"
3. Upload your manifest file
4. All dependencies are automatically imported

See [BOM_IMPORT_GUIDE.md](BOM_IMPORT_GUIDE.md) for detailed instructions.

### Webhook Integration
Automatically sync dependencies with your build pipeline:

**Endpoint:** `POST /api/webhooks/bom/:project_id`

**Use Cases:**
- CI/CD integration (GitHub Actions, GitLab CI, etc.)
- Post-build hooks
- Custom automation scripts
- Development workflow automation

**Example CI/CD Integration:**
```yaml
# GitHub Actions
- name: Update Aura BOM
  run: |
    curl -X POST "$AURA_URL/api/webhooks/bom/$PROJECT_ID" \
      -H "Content-Type: application/json" \
      -d "{\"manifest\": {\"filename\": \"mix.lock\", \"content\": $(cat mix.lock | jq -Rs .)}}"
```

See [BOM_WEBHOOK_API.md](BOM_WEBHOOK_API.md) for complete API documentation.

## Project Management

### Projects
- Create and manage projects
- Link projects to clients
- Track project status (In Quote, In Development, Maintenance, Done, Abandoned)
- Set project timelines (start/end dates)
- Define project goals and descriptions

### Subprojects
- Organize large projects into subprojects
- Platform-specific tracking (Web, Mobile, Desktop, Backend, etc.)
- Individual descriptions for each subproject

### Client Management
- Maintain client records
- Link projects to clients
- Track client contacts
- Organize work by client

## Permission System
Role-based access control for team collaboration:
- View projects
- Create projects
- Update projects
- Delete projects
- Manage clients
- Manage users
- Configure permissions

## User Management
- User registration and authentication
- Email confirmation
- Password reset
- Session management
- Multi-user support

## Dashboard
Centralized view of your projects and activities

## Future Enhancements

### Planned Features
- Additional manifest format support (requirements.txt, Gemfile.lock, composer.json, etc.)
- API token authentication for webhooks
- Vulnerability scanning integration
- License tracking
- Dependency update notifications
- BOM comparison across versions
- Export functionality (CSV, JSON, SBOM formats)
- Audit trails for BOM changes
- Automated dependency update suggestions

### Under Consideration
- Multi-project BOM templates
- Dependency graph visualization
- Integration with package registries (npm, hex.pm, etc.)
- Cost tracking for commercial dependencies
- Compliance reporting
