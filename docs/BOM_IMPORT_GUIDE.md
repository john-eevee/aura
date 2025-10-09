# BOM Import Guide

This guide explains how to use the Bill of Materials (BOM) import feature in Aura.

## Overview

Aura provides two ways to add dependencies to your project's Bill of Materials:

1. **Manual Entry**: Add individual dependencies one at a time
2. **Bulk Import**: Upload a dependency manifest file to import all dependencies at once

## Using the Bulk Import Feature

### Step 1: Navigate to Your Project

1. Log in to Aura
2. Go to the Projects section
3. Click on the project where you want to add dependencies
4. Click the "Bill of Materials" tab

### Step 2: Start Adding a New BOM Entry

1. Click the "Add BOM Entry" button
2. You'll see a modal dialog with two options:
   - Import from Dependency Manifest (at the top)
   - Manual entry form (below)

### Step 3: Upload Your Manifest File

1. In the "Import from Dependency Manifest" section, click "Choose File"
2. Select your dependency file:
   - `mix.lock` for Elixir/Phoenix projects
   - `package.json` for Node.js projects
3. The system will show the filename once selected
4. Click "Import Dependencies" button

### Step 4: Review Import Results

After importing, you'll see:
- Success message with the number of dependencies imported
- The modal will close
- Your BOM table will be updated with all new entries

## Supported File Formats

### mix.lock (Elixir/Phoenix)

The system parses the standard Elixir lock file format and extracts:
- Package name
- Version number

Example entry from mix.lock:
```elixir
"phoenix": {:hex, :phoenix, "1.7.0", "abc123...", [:mix], [...], "hexpm", "..."}
```

Will be imported as:
- **Tool Name**: phoenix
- **Version**: 1.7.0

### package.json (Node.js)

The system parses both `dependencies` and `devDependencies` sections:

Example from package.json:
```json
{
  "dependencies": {
    "express": "^4.18.0",
    "lodash": "~4.17.21"
  },
  "devDependencies": {
    "jest": ">=29.0.0"
  }
}
```

Will import:
- **express** version **4.18.0** (version prefix removed)
- **lodash** version **4.17.21**
- **jest** version **29.0.0**

## Tips and Best Practices

### Before Importing

1. **Backup**: If you have existing BOM entries, note that import doesn't remove them
2. **Duplicates**: The import will attempt to create all entries; check for duplicates afterward
3. **File Size**: Ensure your manifest file is not too large (most are under 100KB)

### After Importing

1. **Review Entries**: Check the imported entries for accuracy
2. **Add Metadata**: Consider adding architecture and purpose information to important entries
3. **Clean Up**: Remove any duplicate or unwanted entries

### Keeping BOMs Updated

For ongoing projects, consider:
- Re-importing when dependencies change significantly
- Using the webhook API for automatic updates (see [BOM_WEBHOOK_API.md](BOM_WEBHOOK_API.md))
- Setting up CI/CD integration to push updates automatically

## Troubleshooting

### Import Failed

**Problem**: "Failed to import: unsupported format"
- **Solution**: Ensure your file is named `mix.lock` or `package.json`

**Problem**: "Failed to parse mix.lock: ..."
- **Solution**: Verify the file is a valid Elixir term. Try running `mix deps.get` to regenerate it

**Problem**: "Failed to parse package.json: ..."
- **Solution**: Verify the file is valid JSON. Try running it through a JSON validator

### No Dependencies Imported

**Problem**: Import succeeds but says "0 dependencies imported"
- **Solution**: Check if your manifest file actually contains dependencies
- For package.json: Ensure it has a `dependencies` or `devDependencies` section
- For mix.lock: Ensure it's not empty

### Some Dependencies Missing

The parser filters out entries that don't have version information. This is normal for:
- Git dependencies in mix.lock
- Path dependencies
- Linked dependencies

These need to be added manually if you want to track them.

## Example Workflow

Here's a typical workflow for a Phoenix project:

1. **Initial Setup**
   ```bash
   # Generate your project
   mix phx.new my_app
   cd my_app
   mix deps.get  # This creates/updates mix.lock
   ```

2. **Import to Aura**
   - Open your Aura project
   - Click "Bill of Materials" tab
   - Click "Add BOM Entry"
   - Upload `mix.lock`
   - Click "Import Dependencies"

3. **Update Later**
   ```bash
   # Add a new dependency
   mix deps.get
   ```
   - Return to Aura
   - Upload the updated `mix.lock`
   - Or set up webhook automation (see [BOM_WEBHOOK_API.md](BOM_WEBHOOK_API.md))

## Need Help?

- For webhook/API integration: See [BOM_WEBHOOK_API.md](BOM_WEBHOOK_API.md)
- For issues: Create an issue in the project repository
