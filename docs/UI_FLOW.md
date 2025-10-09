# BOM Import UI Flow

This document describes the user interface flow for importing dependencies.

## UI Components

### Main Project View

When viewing a project's Bill of Materials tab, users see:

```
┌─────────────────────────────────────────────────────────┐
│  Project: My Phoenix App                                 │
│  ┌──────┬──────────┬─────────────────────────┐          │
│  │ Overview │ Subprojects │ Bill of Materials │ ◄─ Active│
│  └──────┴──────────┴─────────────────────────┘          │
│                                                           │
│  Bill of Materials                    [Add BOM Entry]    │
│  ┌─────────────────────────────────────────────────┐    │
│  │ Tool         │ Version │ Architecture │ Actions │    │
│  ├─────────────────────────────────────────────────┤    │
│  │ phoenix      │ 1.7.0   │ x64         │ Edit/Del│    │
│  │ ecto         │ 3.10.0  │ x64         │ Edit/Del│    │
│  │ ...          │ ...     │ ...         │ ...     │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### Import Modal - Initial State

When clicking "Add BOM Entry", a modal opens showing:

```
┌─────────────────────────────────────────────────────────┐
│  New BOM Entry                                      [X]   │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ╔═══════════════════════════════════════════════════╗  │
│  ║  Import from Dependency Manifest                  ║  │
│  ╠═══════════════════════════════════════════════════╣  │
│  ║                                                   ║  │
│  ║  Upload a dependency manifest file (mix.lock,    ║  │
│  ║  package.json) to automatically import deps.     ║  │
│  ║                                                   ║  │
│  ║  Dependency File                                 ║  │
│  ║  ┌─────────────────────────────────────────┐    ║  │
│  ║  │ [Choose File]                  No file  │    ║  │
│  ║  └─────────────────────────────────────────┘    ║  │
│  ║                                                   ║  │
│  ║  [ Import Dependencies ] ◄─ Disabled             ║  │
│  ║                                                   ║  │
│  ╚═══════════════════════════════════════════════════╝  │
│                                                           │
│  ─────────────────── OR ───────────────────              │
│                                                           │
│  Tool Name                                                │
│  ┌───────────────────────────────────────────────────┐  │
│  │                                                   │  │
│  └───────────────────────────────────────────────────┘  │
│                                                           │
│  Version                                                  │
│  ┌───────────────────────────────────────────────────┐  │
│  │                                                   │  │
│  └───────────────────────────────────────────────────┘  │
│                                                           │
│  ...                                                      │
│                                              [Save Entry] │
└─────────────────────────────────────────────────────────┘
```

### Import Modal - File Selected

After selecting a file:

```
┌─────────────────────────────────────────────────────────┐
│  New BOM Entry                                      [X]   │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ╔═══════════════════════════════════════════════════╗  │
│  ║  Import from Dependency Manifest                  ║  │
│  ╠═══════════════════════════════════════════════════╣  │
│  ║                                                   ║  │
│  ║  Dependency File                                 ║  │
│  ║  ┌─────────────────────────────────────────┐    ║  │
│  ║  │ [Choose File]          mix.lock         │    ║  │
│  ║  └─────────────────────────────────────────┘    ║  │
│  ║                                                   ║  │
│  ║  ┌─────────────────────────────────────────┐    ║  │
│  ║  │ ℹ️  File ready: mix.lock                 │    ║  │
│  ║  └─────────────────────────────────────────┘    ║  │
│  ║                                                   ║  │
│  ║  [📥 Import Dependencies] ◄─ Now enabled         ║  │
│  ║                                                   ║  │
│  ╚═══════════════════════════════════════════════════╝  │
│                                                           │
│  ─────────────────── OR ───────────────────              │
│                                                           │
│  (Manual entry form below...)                             │
└─────────────────────────────────────────────────────────┘
```

### Import Modal - Success

After clicking "Import Dependencies" and successful import:

```
┌─────────────────────────────────────────────────────────┐
│  New BOM Entry                                      [X]   │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ╔═══════════════════════════════════════════════════╗  │
│  ║  Import from Dependency Manifest                  ║  │
│  ╠═══════════════════════════════════════════════════╣  │
│  ║                                                   ║  │
│  ║  Dependency File                                 ║  │
│  ║  ┌─────────────────────────────────────────┐    ║  │
│  ║  │ [Choose File]          mix.lock         │    ║  │
│  ║  └─────────────────────────────────────────┘    ║  │
│  ║                                                   ║  │
│  ║  ┌─────────────────────────────────────────┐    ║  │
│  ║  │ ✅ Successfully imported 37 dependencies │    ║  │
│  ║  └─────────────────────────────────────────┘    ║  │
│  ║                                                   ║  │
│  ║  [📥 Import Dependencies]                        ║  │
│  ║                                                   ║  │
│  ╚═══════════════════════════════════════════════════╝  │
│                                                           │
│  (Modal automatically closes after showing success)       │
└─────────────────────────────────────────────────────────┘
```

### Import Modal - Error

If import fails:

```
┌─────────────────────────────────────────────────────────┐
│  New BOM Entry                                      [X]   │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ╔═══════════════════════════════════════════════════╗  │
│  ║  Import from Dependency Manifest                  ║  │
│  ╠═══════════════════════════════════════════════════╣  │
│  ║                                                   ║  │
│  ║  Dependency File                                 ║  │
│  ║  ┌─────────────────────────────────────────┐    ║  │
│  ║  │ [Choose File]       invalid.txt         │    ║  │
│  ║  └─────────────────────────────────────────┘    ║  │
│  ║                                                   ║  │
│  ║  ┌─────────────────────────────────────────┐    ║  │
│  ║  │ ⚠️  Failed to import: unsupported format│    ║  │
│  ║  └─────────────────────────────────────────┘    ║  │
│  ║                                                   ║  │
│  ║  [📥 Import Dependencies]                        ║  │
│  ║                                                   ║  │
│  ╚═══════════════════════════════════════════════════╝  │
│                                                           │
│  ─────────────────── OR ───────────────────              │
│                                                           │
│  (Can still use manual entry form as fallback)           │
└─────────────────────────────────────────────────────────┘
```

### Updated BOM Table

After successful import, the table is refreshed:

```
┌─────────────────────────────────────────────────────────┐
│  Project: My Phoenix App                                 │
│  ┌──────┬──────────┬─────────────────────────┐          │
│  │ Overview │ Subprojects │ Bill of Materials │          │
│  └──────┴──────────┴─────────────────────────┘          │
│                                                           │
│  ┌────────────────────────────────────────────────┐     │
│  │ ✅ Successfully imported 37 dependencies       │     │
│  └────────────────────────────────────────────────┘     │
│                                                           │
│  Bill of Materials                    [Add BOM Entry]    │
│  ┌─────────────────────────────────────────────────┐    │
│  │ Tool         │ Version │ Architecture │ Actions │    │
│  ├─────────────────────────────────────────────────┤    │
│  │ phoenix      │ 1.7.0   │ -           │ Edit/Del│    │
│  │ ecto         │ 3.10.0  │ -           │ Edit/Del│    │
│  │ phoenix_html │ 4.1.0   │ -           │ Edit/Del│    │
│  │ jason        │ 1.4.0   │ -           │ Edit/Del│    │
│  │ ... (33 more entries)               │ ...     │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## User Interactions

### Import Flow Steps

1. **Start**: User clicks "Add BOM Entry" button
2. **Modal Opens**: Shows import section at top, manual form below
3. **Select File**: User clicks "Choose File" and selects manifest
4. **File Loaded**: UI shows filename, enables Import button
5. **Import**: User clicks "Import Dependencies"
6. **Processing**: Button shows loading state (disabled with "Importing...")
7. **Complete**: Success/error message displays
8. **Refresh**: If successful, modal closes and table refreshes

### Alternative Flow - Manual Entry

1. User can skip import section
2. Scroll down to manual entry form
3. Fill in Tool Name, Version, Architecture, Purpose
4. Click "Save Entry"
5. Single entry created

## Styling Notes

The UI uses Tailwind CSS with DaisyUI components:

- **Import Section**: Light background (`bg-base-200/50`) with border
- **File Input**: DaisyUI `file-input` component
- **Alerts**: 
  - Info: Blue background with document icon
  - Success: Green background with check icon
  - Error: Red background with warning icon
- **Buttons**: Primary style for import, standard for save
- **Divider**: Horizontal line with "OR" text

## Accessibility

- All buttons have descriptive text
- File input has proper label
- Error messages are clear and actionable
- Success messages confirm action taken
- Icons supplement text, not replace it
- Keyboard navigation supported
- Screen reader friendly

## Responsive Design

- Mobile: Single column layout
- Tablet: Same as mobile
- Desktop: Full modal width with proper spacing
- File input: Full width on all devices
- Buttons: Full width on mobile, auto on desktop

## Animation/Transitions

- Modal: Smooth fade in/out
- Alert boxes: Slide down when appearing
- Loading states: Button text changes, disabled state
- Success: Brief delay before modal closes
- Table refresh: Smooth transition of new entries

## Edge Cases Handled

1. **No file selected**: Import button disabled
2. **Invalid file format**: Error message, can try again
3. **Parse error**: Descriptive error, suggests manual entry
4. **Empty manifest**: Success but 0 created, can add manually
5. **Partial failure**: Shows created count and failed count
6. **Large file**: Progress feedback during upload
7. **Network error**: Retry option available
