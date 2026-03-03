# Raw Data Viewer — Functional & Technical Requirements

## Overview

The **Raw Data Viewer** is a standalone HTML page (`raw-data-viewer.html`) that provides interactive, paginated, filterable, and exportable access to the JSON data files produced by the Zero Trust Assessment PowerShell export process. It must integrate visually with the existing Zero Trust Assessment report application and be usable without any build step (self-contained HTML/CSS/JS).

---

## 1. Functional Requirements

### 1.1 Page Title & Branding

- The page title (browser tab and visible heading) must be **"Raw Data Viewer"**.
- The page must include the Zero Trust Assessment logo, application name, and GitHub link, matching the style of the existing HTML report pages.
- Light/dark mode toggle must be present and functional, matching the existing report UI.

### 1.2 JSON File Selection

- A dropdown (select control) at the top of the page must list all available JSON export files by their base name (e.g., `User`, `Device`, `ServicePrincipal`, `Application`, `SignIn`, `RoleAssignment`, etc.).
- The list of available files must be discovered dynamically from the local `export/` folder relative to the page (the folder populated by the Zero Trust Assessment PowerShell module).
- The dropdown must default to the first available file on page load.
- Changing the selection must immediately load and display the corresponding file's data without a full page reload.
- The full list of known file names (used as a discovery hint) includes, but is not limited to:
  - `User`
  - `Application`
  - `ServicePrincipal`
  - `ServicePrincipalSignIn`
  - `Device`
  - `ConfigurationPolicy`
  - `RoleDefinition`
  - `RoleAssignment`
  - `RoleAssignmentScheduleInstance`
  - `RoleEligibilityScheduleInstance`
  - `RoleManagementPolicyAssignment`
  - `RoleAssignmentGroup`
  - `RoleAssignmentScheduleInstanceGroup`
  - `RoleEligibilityScheduleInstanceGroup`
  - `UserRegistrationDetails`
  - `SignIn`

### 1.3 Data Parsing & Display

- Each JSON file follows the Microsoft Graph API envelope format: `{ "@odata.context": "...", "value": [ {...}, {...} ] }`. Records must be extracted from the `value` array.
- Each record must be displayed as a single row in a table. Nested objects and arrays within a record must be flattened or serialised to a human-readable string (e.g., comma-separated list or `key: value` pairs) so that no JSON markup, brackets, or braces appear in the displayed cells.
- Internal framework/helper fields (e.g., `isZtModelRow`, `@odata.*`) must be excluded from the displayed columns.
- Column headers must be derived automatically from the keys of the first record in the loaded file.
- Each row must be displayed on a separate line with visible row separators; rows must not run together.
- Empty or null field values must be rendered as an em-dash (`—`) or other clear placeholder rather than blank cells.

### 1.4 Column Sorting

- Every column header must be clickable to toggle ascending/descending sort on that column.
- Sort direction must cycle through three states: ascending (▲) → descending (▼) → unsorted (no indicator), returning the table to its original load order.
- Only one column may be sorted at a time (single-column sort).

### 1.5 Column Filtering

- A search/filter input must appear either above the table (global search) or below each column header (per-column filter), or both.
- **Global search**: A single text input that filters rows by matching any cell value (case-insensitive substring match).
- **Per-column filter**: Each column header must include an accessible input that filters rows to those matching the typed value in that specific column.
- Filters must be applied in real time as the user types (no submit button required).
- Active filters must be clearly indicated (e.g., highlighted input border or filter icon badge).
- A "Clear all filters" button must be provided.

### 1.6 Pagination

- The table must support paginated display of records.
- The user must be able to select the number of rows per page from the following options: **10**, **25**, **100**, **All**.
- Navigation controls must include: First Page, Previous Page, page number indicator (`Page X of Y`), Next Page, Last Page.
- The total record count for the current filtered result set must be displayed (e.g., "Showing 1–25 of 342 records").
- Changing the rows-per-page setting must reset the view to page 1.

### 1.7 Export — Individual File (CSV)

- A **"Export CSV"** button must be present and enabled whenever a file is loaded.
- Clicking it must download the currently displayed dataset (applying active filters) as a `.csv` file.
- The CSV filename must follow the pattern `<EntityName>-export-<YYYY-MM-DD>.csv`.
- Nested/array values must be serialised to a readable string consistent with the table display.
- All columns must be included; values containing commas or newlines must be quoted per RFC 4180.

### 1.8 Export — Individual File (PDF)

- A **"Export PDF"** button must be present and enabled whenever a file is loaded.
- Clicking it must generate and download a `.pdf` of the currently visible table (applying active filters and current pagination range, or all matching records when "All" is selected).
- The PDF filename must follow the pattern `<EntityName>-export-<YYYY-MM-DD>.pdf`.
- The PDF must include: page header with "Zero Trust Assessment — Raw Data Viewer", entity name, export timestamp, and page numbers.
- Table rows must be clear and legible; long text must wrap within cells rather than overflow.

### 1.9 Export — Master PDF (All Files)

- A **"Export Master PDF"** button must be present in the page header or toolbar area.
- Clicking it must generate and download a single `.pdf` file containing the data from **all** available JSON export files.
- The PDF must be organised by section with a heading for each file (e.g., **Users**, **Devices**, **Service Principals**) acting as a visual separator.
- Section headings must be formatted distinctly from table rows (larger, bold, or differently coloured).
- No JSON markup, brackets, or structural formatting must appear; only the tabular record data is shown.
- The master PDF filename must follow the pattern `ZeroTrustAssessment-RawData-<YYYY-MM-DD>.pdf`.
- The PDF must include a cover page or document header with: "Zero Trust Assessment — Raw Data Export", tenant context information (if available from the report JSON), and the export date/time.
- Page numbers must be included on all pages.

### 1.10 Accessibility & Responsiveness

- The page must be keyboard-navigable (tab order for all interactive controls).
- All interactive controls must have ARIA labels or `title` attributes where the visual label is not self-describing.
- The table must scroll horizontally on narrow viewports; column widths must not cause the page to overflow horizontally.
- The page must be functional on modern versions of Chrome, Edge, and Firefox without any server-side runtime.

---

## 2. Technical Requirements

### 2.1 Technology Stack

The following libraries and technologies must be used, consistent with the existing project:

| Concern | Library / Technology | Version Guidance |
|---|---|---|
| Layout & Styling | [Tailwind CSS](https://tailwindcss.com/) | v3 (match existing `tailwind.config.js`) |
| UI Components | [shadcn/ui](https://ui.shadcn.com/) patterns (Radix UI primitives) | Match existing component styles |
| Table | [@tanstack/react-table](https://tanstack.com/table) **or** a pure-JS equivalent | Match sort/filter patterns used in `data-table.tsx` |
| Icons | [Lucide](https://lucide.dev/) icon set | Match existing `lucide-react` usage |
| PDF Generation | [jsPDF](https://github.com/parallax/jsPDF) + [jspdf-autotable](https://github.com/simonbengtsson/jsPDF-AutoTable) | Latest stable |
| CSV Export | Native `Blob` / `URL.createObjectURL` (no extra library needed) | — |
| Dark Mode | CSS custom properties toggled via a `data-theme` attribute on `<html>` | Match existing `darkMode: ["class"]` Tailwind config |
| Build | **Self-contained single HTML file** (no build step required at runtime; CDN or inlined assets acceptable) | — |

> **Note:** Because this is a standalone HTML file (not integrated into the Vite/React build pipeline), CDN-hosted versions of the above libraries (via `<script>` tags with integrity hashes) are acceptable for the initial implementation. The file must work by opening it directly in a browser alongside the `export/` folder.

### 2.2 File Structure

```
src/report/
├── raw-data-viewer.html          ← new standalone page (this deliverable)
├── raw-data-viewer-requirements.md  ← this file
└── ...
```

The `raw-data-viewer.html` file must be self-contained: all CSS and JavaScript either inlined or loaded from CDN. No local build toolchain dependency.

### 2.3 JSON File Loading

- Files must be loaded via the `fetch()` API using relative paths (e.g., `fetch('./export/Device.json')`).
- The page must detect which JSON files are present by attempting to fetch each known entity name and catching 404 responses gracefully.
- Files that are not found must be excluded from the dropdown silently.
- Large files (tens of thousands of records) must be handled without blocking the UI thread; use async/await and show a loading indicator while parsing.

### 2.4 Data Flattening Algorithm

The following rules must be applied when converting a JSON record object to a flat row for display:

1. **Scalar fields** (`string`, `number`, `boolean`, `null`): rendered as-is. `null` → `—`.
2. **Nested objects** (depth = 1): rendered as `key: value; key: value; …` (semicolon-separated `key: value` pairs).
3. **Arrays of scalars**: rendered as comma-separated values.
4. **Arrays of objects**: rendered as a comma-separated list of flattened object representations (same rule as #2 applied to each item, each item enclosed in `{ … }`).
5. **`@odata.*` prefixed keys**: excluded.
6. **`isZtModelRow`**: excluded.
7. Maximum displayed string length per cell: **256 characters** (truncate with `…` for display; full value shown in a tooltip on hover).

### 2.5 Table Component Specification

| Feature | Specification |
|---|---|
| Header row | Sticky (remains visible on vertical scroll within the table container) |
| Sort indicator | Arrow icon in column header; toggles `asc` → `desc` → unsorted |
| Global filter | Text input above table; debounced 300 ms before applying |
| Per-column filter | Input rendered beneath each `<th>`; filtered independently and combined with global filter via AND logic |
| Pagination bar | Below the table; contains rows-per-page selector and page navigation |
| Row hover | Subtle background highlight (`hover:bg-muted/50` Tailwind class equivalent) |
| Zebra striping | Alternate row shading for readability |
| Column width | `min-width: 120px`; columns may expand to fill available space |

### 2.6 Export Implementation Details

#### 2.6.1 CSV

```javascript
// Pseudocode
function exportCSV(entityName, rows, columns) {
  const header = columns.join(',');
  const body = rows.map(row =>
    columns.map(col => csvEscape(row[col] ?? '')).join(',')
  ).join('\n');
  const blob = new Blob([header + '\n' + body], { type: 'text/csv' });
  triggerDownload(blob, `${entityName}-export-${isoDate()}.csv`);
}
```

#### 2.6.2 Single-Entity PDF

- Use `jsPDF` with `jspdf-autotable`.
- Page orientation: **landscape** for tables with more than 6 columns; **portrait** otherwise.
- Font size: 8pt for table body, 10pt for headers.
- Add header row on every page via `autoTable`'s `didDrawPage` hook.

#### 2.6.3 Master PDF

- Iterate over all loaded entity datasets in alphabetical order.
- For each entity: add a section header row (full-width merged cell) followed by `autoTable` rows.
- Add `jsPDF.addPage()` before each new entity section (except the first).
- After all entities, add page numbers via a final iteration over all pages using `jsPDF.getNumberOfPages()`.

### 2.7 Dark Mode Implementation

- On page load, read `localStorage.getItem('zt-theme')` to restore user preference.
- The mode toggle button must write `'dark'` or `'light'` to `localStorage` and toggle a `dark` class on `<html>` (matching the existing Tailwind `darkMode: ["class"]` configuration).
- All Tailwind dark-mode variants (`dark:bg-*`, `dark:text-*`) must be applied consistently with the existing component palette.

### 2.8 Non-Goals / Out of Scope

- This page must **not** modify any existing files in the repository.
- This page must **not** make live calls to Microsoft Graph API or require an authentication token.
- This page must **not** require any server-side runtime or build step to function.
- Integration into the React Router (`Router.tsx`) or the Vite build pipeline is **out of scope** for the initial implementation described here; it may be considered as a future enhancement.

---

## 3. UI Layout Specification

```
┌─────────────────────────────────────────────────────────────────┐
│ [Logo] Zero Trust Assessment          [🌙 Mode Toggle] [GitHub] │  ← Header (sticky)
├─────────────────────────────────────────────────────────────────┤
│ Raw Data Viewer                                                  │  ← Page heading (h1)
├──────────────────────────┬──────────────────────────────────────┤
│ File: [▾ Select file…  ] │ [🔍 Global search…]  [Clear filters] │  ← Controls bar
│                          │ [Export CSV] [Export PDF]            │
│                          │ [Export Master PDF]                  │
├──────────────────────────┴──────────────────────────────────────┤
│ ┌──────┬──────────────┬──────────────┬──────────────────────┐   │
│ │ ID ▲ │ Display Name │ Account Enab.│  …                   │   │  ← Table header
│ ├──────┼──────────────┼──────────────┼──────────────────────┤   │
│ │[filt]│ [filter    ] │ [filter    ] │ …                    │   │  ← Per-column filters
│ ├──────┼──────────────┼──────────────┼──────────────────────┤   │
│ │  …   │  …           │  …           │  …                   │   │  ← Data rows
│ └──────┴──────────────┴──────────────┴──────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│ Showing 1–25 of 342 records   Rows: [10][25][100][All]          │  ← Pagination bar
│                    [⏮][◀] Page 1 of 14 [▶][⏭]                  │
├─────────────────────────────────────────────────────────────────┤
│ Zero Trust Assessment · Raw Data Viewer · v1.0                  │  ← Footer
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Acceptance Criteria

| # | Criterion |
|---|---|
| AC-1 | Page opens in a browser directly from the file system without any build or server step. |
| AC-2 | All JSON files present in the `export/` folder appear in the file dropdown; missing files do not appear. |
| AC-3 | Selecting a file populates the table with one row per record, with no JSON markup visible. |
| AC-4 | Clicking a column header sorts the table; clicking again reverses the sort; a third click removes the sort. |
| AC-5 | Typing in the global search input filters rows in real time to those matching in any column. |
| AC-6 | Typing in a per-column filter restricts rows to those matching that specific column. |
| AC-7 | Rows-per-page selector controls the number of rows displayed; navigation buttons move between pages correctly. |
| AC-8 | "Export CSV" produces a valid, RFC 4180-compliant CSV file containing all filtered rows. |
| AC-9 | "Export PDF" produces a readable PDF with page headers, entity name, timestamp, and page numbers. |
| AC-10 | "Export Master PDF" produces a single PDF covering all available entity files, organised by section heading, with a cover page and page numbers. |
| AC-11 | Dark/light mode toggle works and preference is persisted across page reloads. |
| AC-12 | No existing files in the repository are modified. |
| AC-13 | Page is keyboard-navigable and all interactive controls have accessible labels. |
| AC-14 | Page renders correctly in Chrome, Edge, and Firefox (latest stable). |

---

## 5. Suggested Implementation Order

1. **Scaffold HTML/CSS**: Create `raw-data-viewer.html` with header, page heading, controls bar, empty table area, and footer using CDN-sourced Tailwind CSS and matching the existing colour scheme.
2. **Dark Mode**: Implement the mode toggle backed by `localStorage`.
3. **File Discovery & Dropdown**: Implement the `fetch`-based file detection loop and populate the `<select>` dropdown.
4. **JSON Loading & Flattening**: Implement the data flattening algorithm and load the first available file on page load.
5. **Table Rendering**: Render flattened records into `<table>` with sticky header, zebra striping, and overflow scroll.
6. **Sorting**: Add click-to-sort on column headers.
7. **Global Search & Per-Column Filters**: Add filter inputs and real-time filtering logic.
8. **Pagination**: Add the pagination bar with rows-per-page selector and navigation controls.
9. **CSV Export**: Implement single-entity CSV download.
10. **PDF Export (Single)**: Integrate jsPDF + jspdf-autotable for single-entity PDF download.
11. **PDF Export (Master)**: Extend PDF export to iterate all entities and produce the master PDF.
12. **Polish & Accessibility**: Add ARIA labels, keyboard navigation, tooltip for truncated cells, loading indicator, and responsive layout fixes.
