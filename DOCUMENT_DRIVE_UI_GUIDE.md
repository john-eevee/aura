# Document Drive UI Guide

This document describes the user interface for the Document Drive feature.

## Project Show Page - Documents Tab

### Tab Navigation
The project show page now has a new "Documents" tab alongside existing tabs:

```
┌─────────────────────────────────────────────────────────┐
│ Project Name                                            │
│ Description text                                        │
│                                         [Edit Project]  │
├─────────────────────────────────────────────────────────┤
│  Overview | Subprojects | Bill of Materials | Documents│ ← NEW TAB
└─────────────────────────────────────────────────────────┘
```

### Documents List View

When the Documents tab is active:

```
┌─────────────────────────────────────────────────────────┐
│ Documents                             [Upload Document] │
├─────────────────────────────────────────────────────────┤
│                                                           │
│ Documents Table:                                          │
│                                                           │
│ ┌───────────────────────────────────────────────────┐   │
│ │ 📄 Name         │ Size   │ Visibility │ Uploaded  │   │
│ ├───────────────────────────────────────────────────┤   │
│ │ 📄 Project      │ 2.4 MB │ Public    │ admin@... │   │
│ │   Spec.pdf      │        │ ✅         │ Dec 15... │   │
│ │                 │        │           │[View][Del]│   │
│ ├───────────────────────────────────────────────────┤   │
│ │ 📄 Design       │ 15.8MB │ Private   │ john@...  │   │
│ │   Mockups.fig   │        │ 🔒         │ Dec 10... │   │
│ │                 │        │           │[View][Del]│   │
│ ├───────────────────────────────────────────────────┤   │
│ │ 📄 Budget       │ 0.3 MB │ Private   │ admin@... │   │
│ │   Q4-2024.xlsx  │        │ 🔒         │ Dec 05... │   │
│ │                 │        │           │[View][Del]│   │
│ └───────────────────────────────────────────────────┘   │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

### Upload Document Modal

Clicking "Upload Document" opens a modal:

```
┌─────────────────────────────────────────────────────────┐
│ Upload Document                                    [✕]  │
├─────────────────────────────────────────────────────────┤
│                                                           │
│ Use this form to upload a new document to this project.  │
│                                                           │
│ Document Name *                                           │
│ ┌───────────────────────────────────────────────────┐   │
│ │ Project Requirements                              │   │
│ └───────────────────────────────────────────────────┘   │
│                                                           │
│ Visibility *                                              │
│ ┌───────────────────────────────────────────────────┐   │
│ │ Public (All project members)              ▼       │   │
│ └───────────────────────────────────────────────────┘   │
│ Options: • Public (All project members)                  │
│          • Private (Only specific users)                 │
│                                                           │
│ File                                                      │
│ ┌───────────────────────────────────────────────────┐   │
│ │                                                     │   │
│ │              📤                                     │   │
│ │     [Upload a file] or drag and drop               │   │
│ │                                                     │   │
│ │     Any file up to 50MB                            │   │
│ │                                                     │   │
│ └───────────────────────────────────────────────────┘   │
│                                                           │
│                                 [Cancel] [Upload Document]│
└─────────────────────────────────────────────────────────┘
```

### Upload Progress

When a file is selected, it shows in the modal:

```
┌─────────────────────────────────────────────────────────┐
│ Upload Document                                    [✕]  │
├─────────────────────────────────────────────────────────┤
│                                                           │
│ Document Name *                                           │
│ ┌───────────────────────────────────────────────────┐   │
│ │ Project Requirements                              │   │
│ └───────────────────────────────────────────────────┘   │
│                                                           │
│ Visibility *                                              │
│ ┌───────────────────────────────────────────────────┐   │
│ │ Private (Only specific users)             ▼       │   │
│ └───────────────────────────────────────────────────┘   │
│                                                           │
│ File                                                      │
│ ┌───────────────────────────────────────────────────┐   │
│ │ 📄 requirements.pdf             (2.43 MB)    [✕]  │   │
│ └───────────────────────────────────────────────────┘   │
│                                                           │
│                                 [Cancel] [Upload Document]│
└─────────────────────────────────────────────────────────┘
```

## Document Viewing

When clicking "View" on a document, it opens in a new browser tab:

```
┌─────────────────────────────────────────────────────────┐
│ ← → ⟳ 🔒 localhost:4000/projects/.../documents/.../view│
├─────────────────────────────────────────────────────────┤
│                                                           │
│                   [Document Content]                      │
│                                                           │
│            Displayed inline in browser                    │
│         (PDF viewer, image, text, etc.)                  │
│                                                           │
│                 No download button                        │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

### Key UI Features

1. **Document List**
   - Clean table layout
   - Document icon for visual identification
   - Size displayed in megabytes
   - Visibility badge (green for public, gray for private)
   - Uploader email shown
   - Upload date formatted as "Month DD, YYYY"

2. **Upload Modal**
   - Clear form with labeled fields
   - Drag-and-drop file area with visual feedback
   - File size limit displayed (50MB)
   - Selected file shown with name and size
   - Option to remove selected file
   - Cancel and Upload buttons

3. **Visibility Indicators**
   - ✅ Public badge (green) - All project members can see
   - 🔒 Private badge (gray) - Only specific users can see

4. **Actions**
   - **View**: Opens document in new tab for in-browser viewing
   - **Delete**: Only shown if user is uploader or admin
     - Shows confirmation dialog: "Are you sure you want to delete this document?"

5. **Empty State** (no documents uploaded)
   ```
   ┌─────────────────────────────────────────────────────┐
   │ Documents                         [Upload Document] │
   ├─────────────────────────────────────────────────────┤
   │                                                       │
   │              No documents yet                         │
   │                                                       │
   │    Upload your first document to get started         │
   │                                                       │
   └─────────────────────────────────────────────────────┘
   ```

## User Flows

### Uploading a Document

1. Navigate to project
2. Click "Documents" tab
3. Click "Upload Document" button
4. Fill in document name
5. Select visibility (public or private)
6. Drag file or click to browse
7. Click "Upload Document"
8. Modal closes, success message appears
9. Document appears in list

### Viewing a Document

1. Navigate to project → Documents tab
2. Click "View" link on a document
3. New tab opens with document content
4. Document streams in browser
5. View recorded in audit log

### Deleting a Document (if authorized)

1. Navigate to project → Documents tab
2. Click "Delete" link on a document (only visible if authorized)
3. Confirmation dialog appears
4. Click "OK" to confirm
5. Document soft-deleted
6. Document removed from list
7. Success message appears

## Flash Messages

Success messages:
- ✅ "Document uploaded successfully"
- ✅ "Document deleted successfully"

Error messages:
- ❌ "You don't have permission to upload documents"
- ❌ "You don't have permission to view this document"
- ❌ "You don't have permission to delete this document"
- ❌ "Document file not found"
- ❌ "Failed to delete document"
- ❌ "Please select a file to upload"
- ❌ "File is too large (max 50MB)"

## Responsive Design

The UI is built with Tailwind CSS and follows responsive design principles:

- **Desktop**: Full table layout with all columns
- **Tablet**: Condensed table with wrapped text
- **Mobile**: Stacked card layout (if needed)

## Accessibility

- All forms have proper labels
- Upload area has keyboard navigation support
- Confirmation dialogs for destructive actions
- Clear visual feedback for all interactions
- Semantic HTML for screen readers

## Visual Design

The design follows the existing Aura design system:

- **Colors**:
  - Primary: Blue (#2563eb)
  - Success: Green (for public badge)
  - Danger: Red (for delete action)
  - Secondary: Gray (for private badge)
  
- **Typography**:
  - Headers: Bold, larger font
  - Body: Regular weight
  - Badges: Smaller, uppercase
  
- **Spacing**:
  - Consistent padding and margins
  - Adequate whitespace between elements
  - Clear visual hierarchy

- **Components**:
  - Buttons: Rounded, with hover states
  - Badges: Rounded pills with colored backgrounds
  - Tables: Striped rows for readability
  - Modals: Centered overlay with backdrop
