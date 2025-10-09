# BOM Webhook API Documentation

This document describes how to integrate external build tools with Aura to automatically update Bill of Materials (BOM) entries when dependencies change.

## Overview

The BOM Webhook API allows you to automatically push dependency information from your build system to Aura whenever your dependencies change. This eliminates the need to manually upload manifest files through the web interface.

## Endpoint

```
POST /api/webhooks/bom/:project_id
```

Replace `:project_id` with your actual project ID.

## Authentication

The API requires authentication. You must be logged in and have the necessary permissions to update the project's BOM.

## Request Format

### Headers

```
Content-Type: application/json
```

### Body

```json
{
  "manifest": {
    "filename": "mix.lock",
    "content": "<file content as string>"
  }
}
```

### Supported File Formats

- `mix.lock` - Elixir/Phoenix projects
- `package.json` - Node.js projects

## Response Format

### Success Response (201 Created)

```json
{
  "success": true,
  "created": 15,
  "failed": 0,
  "skipped": 2,
  "message": "Successfully imported 15 dependencies",
  "errors": []
}
```

**Response Fields:**
- `success`: Boolean indicating overall success
- `created`: Number of new BOM entries created
- `failed`: Number of dependencies that failed to import
- `skipped`: Number of duplicate dependencies that were skipped
- `message`: Human-readable success message
- `errors`: Array of error details for failed imports (empty on success)

### Error Responses

#### Bad Request (400)

```json
{
  "success": false,
  "error": "Missing required fields: filename or content"
}
```

#### Forbidden (403)

```json
{
  "success": false,
  "error": "You don't have permission to update this project"
}
```

#### Not Found (404)

```json
{
  "success": false,
  "error": "Project not found"
}
```

#### Unprocessable Entity (422)

```json
{
  "success": false,
  "error": "Failed to parse mix.lock: <error details>"
}
```

## Integration Examples

### Using cURL

```bash
# Read the manifest file
PROJECT_ID="your-project-id"
MANIFEST_FILE="mix.lock"
CONTENT=$(cat $MANIFEST_FILE | jq -Rs .)

# Send the request
curl -X POST "https://your-aura-instance.com/api/webhooks/bom/$PROJECT_ID" \
  -H "Content-Type: application/json" \
  -b "your-session-cookie" \
  -d "{\"manifest\": {\"filename\": \"$MANIFEST_FILE\", \"content\": $CONTENT}}"
```

### Mix Task Integration (Elixir)

Create a custom Mix task to automatically push dependencies:

```elixir
defmodule Mix.Tasks.Aura.PushDeps do
  use Mix.Task

  @shortdoc "Push dependencies to Aura BOM"
  
  def run(_) do
    project_id = System.get_env("AURA_PROJECT_ID")
    aura_url = System.get_env("AURA_URL")
    
    # Read mix.lock
    lock_content = File.read!("mix.lock")
    
    # Send to Aura
    payload = %{
      manifest: %{
        filename: "mix.lock",
        content: lock_content
      }
    }
    
    # Use Req to send the request
    Req.post!("#{aura_url}/api/webhooks/bom/#{project_id}",
      json: payload
    )
    
    IO.puts("Dependencies pushed to Aura successfully!")
  end
end
```

Then run: `mix aura.push_deps`

### NPM Script Integration (Node.js)

Add to your `package.json`:

```json
{
  "scripts": {
    "push-deps": "node scripts/push-deps-to-aura.js"
  }
}
```

Create `scripts/push-deps-to-aura.js`:

```javascript
const fs = require('fs');
const https = require('https');

const projectId = process.env.AURA_PROJECT_ID;
const auraUrl = process.env.AURA_URL;

// Read package.json
const packageJson = fs.readFileSync('package.json', 'utf8');

// Prepare payload
const payload = JSON.stringify({
  manifest: {
    filename: 'package.json',
    content: packageJson
  }
});

// Send request
const url = new URL(`/api/webhooks/bom/${projectId}`, auraUrl);

const options = {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(payload)
  }
};

const req = https.request(url, options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  res.on('data', (d) => {
    process.stdout.write(d);
  });
});

req.on('error', (e) => {
  console.error(`Error: ${e.message}`);
});

req.write(payload);
req.end();
```

Then run: `npm run push-deps`

### CI/CD Integration

#### GitHub Actions

```yaml
name: Update Aura BOM

on:
  push:
    paths:
      - 'mix.lock'
      - 'package.json'

jobs:
  update-bom:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Push dependencies to Aura
        run: |
          curl -X POST "${{ secrets.AURA_URL }}/api/webhooks/bom/${{ secrets.AURA_PROJECT_ID }}" \
            -H "Content-Type: application/json" \
            -H "Cookie: _aura_key=${{ secrets.AURA_SESSION_COOKIE }}" \
            -d "{\"manifest\": {\"filename\": \"mix.lock\", \"content\": $(cat mix.lock | jq -Rs .)}}"
```

## Security Considerations

1. **Authentication**: Session-based authentication is required. All requests must be authenticated.
2. **Authorization**: Users must have the `update_projects` permission to import dependencies.
3. **Project Access**: The system validates that the project exists before processing.
4. **HTTPS**: Always use HTTPS in production to protect credentials and data.
5. **Duplicate Prevention**: The system automatically skips duplicate dependencies to prevent data pollution.
6. **Rate Limiting**: Consider implementing rate limiting to prevent abuse (not yet implemented).
7. **File Size**: Consider setting reasonable limits on manifest file sizes.

## Future Enhancements

- API token authentication (instead of session-based)
- Support for more manifest formats (requirements.txt, Gemfile.lock, etc.)
- Webhook signatures for verification
- Batch operations for multiple projects
