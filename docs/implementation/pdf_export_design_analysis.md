# PDF Export Design Analysis

## 1. Purpose

This document is analysis and implementation planning only. It does not implement PDF export changes, does not modify Swift code, and does not change export, premium, StoreKit, test, or data logic.

The goal is to decide what kind of PDF BudgetMeter should generate for users, then define a practical plan for improving the current technically working but visually weak PDF export.

## 2. Current Problem

Premium testing confirmed that PDF export works technically: the app creates and shares a PDF file. The problem is the output quality. The current PDF looks like a basic debug/report dump rather than a polished premium document.

Likely issues:

- weak typography hierarchy
- cramped spacing
- plain black text with little visual structure
- no meaningful first-page summary
- no BudgetMeter visual identity beyond the title text
- weak table/list layout
- no page header/footer system
- no page numbers
- no clear report period treatment
- hardcoded English PDF strings
- limited readability for sharing with someone who has not opened the app

This aligns with `docs/premium_test_findings.md`, which marks `PDF export tasarımı` as `Çirkin, düzenlenmeli`.

## 3. Current Implementation Summary

PDF export is generated in `budgetmeter.ios/CoreKit/Sources/Export/DataExportService.swift`.

Current flow:

- `DataExportService.exportData(format:dateRange:)` checks `PremiumManager.shared.hasAccess(to: .dataExport)`.
- `gatherExportData(dateRange:)` fetches:
  - `FinancialCategory`
  - `RecurringTransaction`
  - first `AppSettings`
- `.pdf` export calls `exportToPDF(_:)`.
- `exportToPDF(_:)` writes a file named `BudgetMeter_Export_<date>.pdf` to the app Documents directory.
- `generatePDFData(_:)` builds the PDF.

Current rendering approach:

- Uses `UIGraphicsPDFRenderer`.
- Uses manual UIKit/CoreGraphics-style text drawing.
- Imports `PDFKit`, but the current PDF layout is not built with a PDFKit document/page abstraction.
- Uses US Letter size: 8.5 x 11 inches.
- Manually tracks `yPosition` and starts a new page when content crosses a rough threshold.

Current PDF content:

- Title: `BudgetMeter Export Report`
- Export date
- Simple summary:
  - total financial categories
  - total recurring transactions
  - total income
  - total expenses
  - net balance
- Financial category list
- Recurring transaction list

Current limitations:

- PDF strings are hardcoded in English inside `DataExportService`.
- The UI description says PDF is a formatted report with charts and summaries, but the current PDF has no charts and only a plain text summary.
- `dateRange` is only applied to recurring transactions. `FinancialCategory` has no date field, so all categories are included.
- The PDF does not include a polished monthly summary layout.
- It does not show savings goals.
- It does not use BudgetMeter design-system styling.
- It does not have branded headers, footers, page numbers, repeated table headers, or a clear appendix.
- It draws list rows as plain text rather than readable report tables.
- It includes less data than JSON and CSV.
- JSON includes internal/settings fields, but those should not appear in a user-facing PDF.

The export UI is in `budgetmeter.ios/Features/DataExportFeature/View/DataExportView.swift`. It offers PDF, CSV, and JSON, date range selection, export progress, and a share sheet. Current localized UI keys exist in `budgetmeter.ios/Resources/UI.xcstrings` for export options and descriptions, but the PDF body text itself is not localized.

## 4. User Needs

A BudgetMeter PDF should feel like a shareable financial document, not a raw export.

Users likely expect:

- a clean financial summary they can understand quickly
- a document that can be shared with a spouse, family member, accountant, advisor, or future self
- a report that makes sense without opening the app
- clear income, expense, net balance, and savings context
- category-level detail where useful
- enough detail for review, but not a raw database dump
- professional formatting because PDF export is a premium feature
- correct currency and date formatting for their locale
- predictable page structure when printed or opened in Files, Preview, Mail, or messaging apps

The PDF should answer: “What happened in this period, and am I moving forward or slowing down?”

## 5. Recommended PDF Types

### A. Monthly Summary PDF

This should be the primary MVP report.

Recommended content:

- period title
- generated date
- total income
- total expenses
- net balance / net pace
- savings progress
- category breakdown
- short status sentence
- optional notes

This is the most user-facing and most aligned with BudgetMeter’s calm money pace positioning.

### B. Full Data Export PDF

This should remain available as a more detailed export, but it should not be the first design target.

Recommended content:

- date range
- income list
- expense list
- recurring transaction list
- savings goals if available
- table-heavy appendix format

This is useful for users who need records, but it is less emotionally and visually valuable than a monthly summary.

### C. Optional Future: Insights Report PDF

This can come later if BudgetMeter adds stronger insights or generated observations.

Potential content:

- charts
- month-over-month changes
- category trends
- pace observations
- lightweight recommendations

This should not be part of the MVP PDF redesign unless the data and insight model are already stable.

Recommended first improvement: **Monthly Summary PDF**.

## 6. Product Recommendation

For MVP, improve one main PDF: **Monthly Financial Summary Report**.

This is better than trying to redesign every export type at once because:

- it creates a clear premium-quality artifact quickly
- it aligns with BudgetMeter’s core promise: calm money pace awareness
- it avoids bloating the first implementation with every possible table and data type
- it gives QA a focused output to validate
- it leaves CSV/JSON as machine-readable or spreadsheet-oriented exports
- it avoids mixing “beautiful report” and “complete data dump” into one confused PDF

The PDF should feel like a personal finance summary, not an accounting ledger and not a noisy dashboard.

## 7. Proposed PDF Structure

### Page 1

- BudgetMeter logo/name
- Report title: `Monthly Financial Summary`
- Date range
- Generated date
- Hero summary card:
  - total income
  - total expenses
  - net balance / net pace
  - savings progress
- Short status sentence:
  - Example meaning: “You ended this period ahead by …” or “Expenses were higher than income this period.”

### Page 2

- Income breakdown
- Expense breakdown
- Top categories
- Recurring vs one-time summary if available
- Simple category table with:
  - category name
  - type
  - amount
  - share of total where safe

### Page 3

- Savings goals summary
- Active goals
- current amount
- target amount
- progress
- target date where available

### Optional Appendix

- Detailed transaction/category table
- Recurring transaction list
- Export metadata:
  - date range
  - generated timestamp
  - app name/version if safe and useful

The appendix should come after summaries, never before them.

## 8. Visual Design Direction

BudgetMeter’s PDF should use the same product language as the app:

- calm fintech
- neutral page background
- clear hierarchy
- soft cards
- subtle accent color
- no noisy dashboard
- no excessive decoration
- professional export, not childish

Typography:

- Title: large, calm, high contrast
- Section headings: medium weight, consistent spacing
- Metric labels: small, secondary
- Metric values: clear and readable
- Body/table text: compact but not cramped
- Footers: small, secondary

Spacing:

- generous page margins
- consistent vertical rhythm
- grouped sections with breathing room
- avoid long uninterrupted blocks of text

Table styling:

- column headers
- right-aligned currency amounts
- alternating row tint or subtle row dividers
- repeated headers on new pages if a table spans pages
- totals row at the bottom where useful
- long names should wrap or truncate gracefully

Section headers:

- clear but restrained
- use subtle accent line or small accent label
- avoid heavy filled bars

Accent usage:

- use the selected/current app accent only as an accent layer where practical
- use accent for report title detail, selected/highlight metrics, small dividers, or neutral progress visuals
- do not flood pages with theme color

Semantic colors:

- income/positive remains green
- expense/negative remains red/coral
- warning/error/destructive colors remain semantic
- financial meaning should not be overridden by premium theme accent

Logo/header/footer treatment:

- header should include `BudgetMeter` and report title context
- footer should include generated timestamp and page number
- page numbers should appear on every page
- generated timestamp should use locale-aware date/time formatting

The output should look premium because it is clear, calm, and useful, not because it is colorful.

## 9. What Should Be Included

Include these fields when available:

- report period
- generated date
- app name
- total income
- total expense
- net balance
- money pace / status if available from the shared summary model
- category names
- category type
- category amounts
- recurring/one-time labels if available
- recurring transaction names
- recurring frequency
- savings goal names
- savings goal current amounts
- savings goal target amounts
- savings goal target dates
- savings goal progress
- currency-formatted amounts
- date-range note when the selected date range cannot fully filter a data type

The PDF should prefer user-facing names and labels over internal entity names.

## 10. What Should Not Be Included

Avoid:

- dense raw database dump as the first page
- too many colors
- emoji-heavy output
- debug fields
- premium entitlement fields
- internal technical IDs
- Core Data IDs
- `uniqueID`
- `selectedTheme`
- `customAppIcon`
- `isPremiumUser`
- raw backup/sync fields
- overly large tables before summaries
- hardcoded Turkish text
- hardcoded English text
- hardcoded currency symbols
- implementation details such as StoreKit, CloudKit, or Supabase internals

CSV/JSON can remain more technical if product decides that is acceptable, but the PDF should be user-facing.

## 11. Localization + Currency Requirements

All static PDF labels must use localization.

Requirements:

- no hardcoded English PDF body labels
- no hardcoded Turkish PDF labels
- no hardcoded TRY/USD symbols
- amounts must use the app/user currency formatter
- dates must use locale-aware formatting
- date ranges must use locale-aware formatting
- generated timestamp must use locale-aware formatting
- report title and labels should work in English first, then the other app languages
- long translated strings must wrap safely
- right-to-left languages should be considered before claiming full localization polish

The app already has localized export UI keys in `UI.xcstrings`, but the generated PDF content needs its own localized label strategy.

## 12. Technical Implementation Options

### A. CoreGraphics Manual PDF Rendering

Pros:

- matches current implementation
- predictable PDF output
- good control over pagination, tables, headers, and footers
- no new rendering dependency
- easiest safe first step from `UIGraphicsPDFRenderer`

Cons:

- verbose drawing code
- easy to create layout bugs
- needs custom helpers for text wrapping, cards, tables, and page breaks
- less reusable than SwiftUI components

Fit for BudgetMeter:

- best fit for the first redesign because the current code already uses `UIGraphicsPDFRenderer`
- safest path for improving output without changing export architecture broadly

Risk:

- medium, mostly layout correctness and long-content handling

### B. SwiftUI View Rendered to PDF

Pros:

- can reuse app design thinking and component structure
- easier for visual iteration
- familiar to the app codebase

Cons:

- pagination is harder
- table continuation across pages is harder
- rendered output may vary by iOS version
- app UI components are optimized for screens, not print/PDF pages
- risk of importing too much app UI complexity into export

Fit for BudgetMeter:

- attractive later for simple one-page summaries, but risky for detailed multi-page reports

Risk:

- medium to high for multi-page, table-heavy exports

### C. HTML Template Rendered to PDF

Pros:

- good for document layouts
- CSS is expressive for typography and tables
- easier to preview outside the app
- common approach for invoices and reports

Cons:

- adds HTML/CSS template complexity
- print CSS pagination can be tricky
- requires a reliable rendering path on iOS
- may add maintenance overhead for localization and assets

Fit for BudgetMeter:

- viable for a future reporting engine, but probably too much for the first fix

Risk:

- medium, mainly around rendering consistency and template maintenance

### D. UIKit/PDFKit Hybrid

Pros:

- keeps `UIGraphicsPDFRenderer` for drawing
- can use PDFKit where useful for post-processing or inspection
- stays close to current service boundaries
- allows a dedicated renderer/helper while preserving export flow

Cons:

- still requires custom layout primitives
- PDFKit does not solve report design by itself

Fit for BudgetMeter:

- recommended practical path: keep UIKit/CoreGraphics rendering, optionally organize it into a small PDF report renderer/helper

Risk:

- low to medium if phased carefully

Recommendation:

Use the current `UIGraphicsPDFRenderer` approach for the first implementation, but refactor the PDF drawing into structured report primitives or a dedicated helper. Do not switch to SwiftUI or HTML in the first pass unless there is a strong reason after prototyping.

## 13. Recommended Implementation Phases

### Phase 1

Improve the current PDF template visually without changing the data model.

- add report header
- add footer/page number support
- improve typography
- add margins and section spacing
- replace plain list drawing with simple table-like rows
- keep current export data sources

### Phase 2

Add structured Monthly Summary PDF layout.

- define a first-page summary
- add metric cards
- add period title
- add generated date
- add simple status sentence
- separate summary from appendix-style details

### Phase 3

Add localization/currency/date formatting polish.

- move PDF labels to localized strings
- verify user currency formatting
- verify locale-aware dates
- remove hardcoded report body text

### Phase 4

Add optional charts or category breakdown visuals if safe.

- simple bars or progress rows before complex charts
- avoid noisy dashboard visuals
- keep semantic colors intact

### Phase 5

QA with edge cases.

- light/dark app modes
- different currencies
- long category names
- empty data
- many categories
- long translations
- PDF opened outside the app

## 14. Recommended Files to Change Per Phase

### Phase 1

Likely files:

- `budgetmeter.ios/CoreKit/Sources/Export/DataExportService.swift`
  - improve current PDF drawing structure
  - add header/footer/page number drawing
  - improve section and row layout

Optional if the renderer becomes large:

- `budgetmeter.ios/CoreKit/Sources/Export/PDFReportRenderer.swift`
  - isolate PDF layout primitives from export orchestration

### Phase 2

Likely files:

- `budgetmeter.ios/CoreKit/Sources/Export/DataExportService.swift`
  - map existing `ExportData` into a monthly summary model
- optional `budgetmeter.ios/CoreKit/Sources/Export/PDFReportRenderer.swift`
  - draw hero summary, metric cards, and detail sections

Potential read-only dependencies to inspect:

- shared financial summary builder/model files if the report should use money pace values
- savings goal manager/model files if savings goals are added to the report

### Phase 3

Likely files:

- `budgetmeter.ios/Resources/UI.xcstrings`
  - add PDF report body labels
- `budgetmeter.ios/CoreKit/Sources/Export/DataExportService.swift`
  - replace hardcoded labels with localized strings
- date/currency formatter helper files only if existing formatters are insufficient

### Phase 4

Likely files:

- `budgetmeter.ios/CoreKit/Sources/Export/DataExportService.swift`
  - generate category breakdown data
- optional `budgetmeter.ios/CoreKit/Sources/Export/PDFReportRenderer.swift`
  - draw simple bars/progress rows
- chart-related app code should be used only as reference, not copied wholesale into PDF rendering

### Phase 5

Likely files:

- focused export tests if existing test infrastructure supports PDF validation
- snapshot/golden PDF tests only if stable enough for CI
- no production files unless QA reveals bugs

## 15. Risks

- breaking export generation
- unreadable PDFs with long data
- localized labels overflowing
- right-to-left layout problems
- currency formatting mistakes
- hardcoded symbols or labels remaining
- large PDF size
- slow rendering on older devices
- inconsistent design vs the app
- too much color making the report feel noisy
- confusing financial meaning by recoloring income/expense/status values
- overdesigning before the core report structure is stable
- date range mismatch because `FinancialCategory` currently has no date field
- adding savings data before the export data model is ready
- accidentally changing premium entitlement behavior while working near export code

## 16. Test Plan

Manual checks:

- export PDF with normal data
- export PDF with no data
- export PDF with many categories
- export PDF with long category names
- export PDF with long recurring transaction names
- export PDF with different currency
- export PDF in English app language
- export PDF after app language change
- export PDF with a custom date range
- verify any date-range limitation is clear
- open PDF in Files
- open PDF in Preview
- share PDF through the system share sheet
- verify no debug/internal fields
- verify no premium/internal IDs
- verify generated date appears
- verify page numbers appear
- verify first page is understandable without opening the app
- verify income green and expense red/coral remain semantic
- verify report still works when there are enough rows to span pages

Automated checks, if practical:

- PDF export returns a valid file URL
- generated PDF data is non-empty
- no entitlement behavior changes
- empty-data export does not crash
- long-name export does not crash
- localized labels exist for new PDF strings

## 17. Acceptance Criteria

- [ ] PDF looks professional
- [ ] first page is understandable in 5 seconds
- [ ] key metrics are clear
- [ ] report period is clear
- [ ] generated date is clear
- [ ] tables are readable
- [ ] long names do not break layout
- [ ] multi-page output has page numbers
- [ ] currency formatting is correct
- [ ] date formatting is locale-aware
- [ ] PDF labels are localization-ready
- [ ] no internal/debug fields are shown
- [ ] no hardcoded currency symbols
- [ ] no hardcoded Turkish text
- [ ] no full dashboard clutter
- [ ] financial semantic colors are preserved
- [ ] export sharing still works
- [ ] premium gating still works
- [ ] build and tests pass

## 18. Final Recommendation

Improve the **Monthly Financial Summary Report** first.

Use a calm fintech document style: neutral page, clear hierarchy, restrained accent, semantic financial colors, readable tables, and a strong first-page summary. The first implementation should be a focused visual/report-structure improvement on top of the existing `UIGraphicsPDFRenderer` path, not a full export-system rewrite.

Depth:

- Phase 1 and Phase 2 are appropriate for Codex/Composer-level implementation because they require careful code inspection, layout judgment, and preserving premium/export behavior.
- Small localized label additions can be assisted by Cursor Auto after the structure is stable.
- Avoid broad automated refactors in the first pass because this code sits near premium gating, export file generation, localization, and currency formatting.

The first fix should make the PDF feel like a premium BudgetMeter report while keeping CSV/JSON as data-oriented exports.
