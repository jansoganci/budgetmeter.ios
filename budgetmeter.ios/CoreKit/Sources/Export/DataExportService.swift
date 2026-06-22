import Foundation
import CoreData
import PDFKit
import UIKit
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable {
    case pdf = "pdf"
    case csv = "csv"
    case json = "json"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .pdf: return String(localized: "export.format.pdf", defaultValue: "PDF Report", table: "UI")
        case .csv: return String(localized: "export.format.csv", defaultValue: "CSV Data", table: "UI")
        case .json: return String(localized: "export.format.json", defaultValue: "JSON Data", table: "UI")
        }
    }
    
    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .csv: return "csv"
        case .json: return "json"
        }
    }
    
    var utType: UTType {
        switch self {
        case .pdf: return .pdf
        case .csv: return .commaSeparatedText
        case .json: return .json
        }
    }
}

struct ExportData {
    let financialCategories: [FinancialCategory]
    let recurringTransactions: [RecurringTransaction]
    let appSettings: AppSettings?
    let exportDate: Date
    let dateRange: DateInterval?
}

private struct PDFReportSummary {
    let totalIncome: Double
    let totalExpenses: Double
    let netBalance: Double
    let categoryCount: Int
    let recurringCount: Int
    let statusText: String
}

private struct PDFCategoryRow {
    let name: String
    let type: String
    let amount: Double
    let frequency: String
    let isIncome: Bool
}

private struct PDFRecurringRow {
    let title: String
    let category: String
    let type: String
    let amount: Double
    let frequency: String
    let isActive: Bool
}

private struct PDFMetric {
    let label: String
    let value: String
    let color: UIColor
}

private struct PDFLayout {
    let pageRect: CGRect
    let margin: CGFloat = 54
    let contentTop: CGFloat = 116
    let contentBottom: CGFloat

    var contentWidth: CGFloat {
        pageRect.width - (margin * 2)
    }

    init(pageRect: CGRect) {
        self.pageRect = pageRect
        self.contentBottom = pageRect.height - 58
    }
}

private struct PDFPalette {
    let pageBackground = UIColor(red: 0.972, green: 0.980, blue: 0.988, alpha: 1)
    let cardBackground = UIColor.white
    let metricBackground = UIColor(red: 0.973, green: 0.976, blue: 0.984, alpha: 1)
    let tableHeader = UIColor(red: 0.941, green: 0.957, blue: 0.976, alpha: 1)
    let cardBorder = UIColor(red: 0.867, green: 0.894, blue: 0.925, alpha: 1)
    let cardShadow = UIColor(white: 0, alpha: 0.035)
    let divider = UIColor(red: 0.886, green: 0.910, blue: 0.941, alpha: 1)
    let primaryText = UIColor(red: 0.059, green: 0.090, blue: 0.165, alpha: 1)
    let secondaryText = UIColor(red: 0.282, green: 0.333, blue: 0.412, alpha: 1)
    let mutedText = UIColor(red: 0.392, green: 0.455, blue: 0.545, alpha: 1)
    let accent = UIColor(red: 0.945, green: 0.431, blue: 0.329, alpha: 1)
    let positive = UIColor(red: 0.063, green: 0.725, blue: 0.506, alpha: 1)
    let negative = UIColor(red: 0.937, green: 0.267, blue: 0.267, alpha: 1)
}

final class DataExportService {
    static let shared = DataExportService()
    
    private let persistenceService: PersistenceService
    
    private init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
    }
    
    func exportData(format: ExportFormat, dateRange: DateInterval? = nil) async throws -> URL {
        let canExport = await MainActor.run {
            PremiumManager.shared.hasAccess(to: BudgetMeterCapability.dataExport)
        }
        guard canExport else {
            throw PremiumError.featureLocked(.dataExport)
        }

        let exportData = try await gatherExportData(dateRange: dateRange)
        
        switch format {
        case .pdf:
            return try await exportToPDF(exportData)
        case .csv:
            return try await exportToCSV(exportData)
        case .json:
            return try await exportToJSON(exportData)
        }
    }
    
    private func gatherExportData(dateRange: DateInterval? = nil) async throws -> ExportData {
        let context = persistenceService.viewContext
        
        // Fetch financial categories
        let categoriesRequest: NSFetchRequest<FinancialCategory> = FinancialCategory.fetchRequest()
        if dateRange != nil {
            // Note: FinancialCategory doesn't have a date field, so we'll include all for now
            // In a real implementation, you might want to add a date field to track when transactions were created
        }
        let financialCategories = try context.fetch(categoriesRequest)
        
        // Fetch recurring transactions
        let recurringRequest: NSFetchRequest<RecurringTransaction> = RecurringTransaction.fetchRequest()
        if let dateRange = dateRange {
            recurringRequest.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", 
                                                   dateRange.start as NSDate, dateRange.end as NSDate)
        }
        let recurringTransactions = try context.fetch(recurringRequest)
        
        // Fetch app settings
        let settingsRequest: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()
        let appSettings = try context.fetch(settingsRequest).first
        
        return ExportData(
            financialCategories: financialCategories,
            recurringTransactions: recurringTransactions,
            appSettings: appSettings,
            exportDate: Date(),
            dateRange: dateRange
        )
    }
    
    private func exportToPDF(_ data: ExportData) async throws -> URL {
        let fileName = "BudgetMeter_Export_\(formatDate(data.exportDate)).pdf"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        let pdfData = try await generatePDFData(data)
        try pdfData.write(to: fileURL)
        
        return fileURL
    }
    
    private func exportToCSV(_ data: ExportData) async throws -> URL {
        let fileName = "BudgetMeter_Export_\(formatDate(data.exportDate)).csv"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        let csvContent = generateCSVContent(data)
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    private func exportToJSON(_ data: ExportData) async throws -> URL {
        let fileName = "BudgetMeter_Export_\(formatDate(data.exportDate)).json"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        let jsonData = try generateJSONData(data)
        try jsonData.write(to: fileURL)
        
        return fileURL
    }
    
    private func generatePDFData(_ data: ExportData) async throws -> Data {
        let reportTitle = localized("export.pdf.title", defaultValue: "Monthly Financial Summary")
        let generatedLabel = localized("export.pdf.generated", defaultValue: "Generated")
        let periodLabel = localized("export.pdf.period", defaultValue: "Period")
        let generatedDate = formatDate(data.exportDate)
        let periodText = formatDateRange(data.dateRange)
        let summary = makePDFSummary(data)
        let categoryRows = makeCategoryRows(data.financialCategories)
        let recurringRows = makeRecurringRows(data.recurringTransactions)

        let pdfMetaData = [
            kCGPDFContextCreator: "BudgetMeter",
            kCGPDFContextAuthor: "BudgetMeter App",
            kCGPDFContextTitle: reportTitle
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let layout = PDFLayout(pageRect: pageRect)
        let palette = PDFPalette()
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let pdfData = renderer.pdfData { context in
            var pageNumber = 0
            
            func beginPage() -> CGFloat {
                pageNumber += 1
                context.beginPage()
                drawPageChrome(
                    context: context,
                    layout: layout,
                    palette: palette,
                    reportTitle: reportTitle,
                    periodText: periodText,
                    generatedText: "\(generatedLabel): \(generatedDate)",
                    pageNumber: pageNumber
                )
                return layout.contentTop
            }
            
            func ensureSpace(_ yPosition: CGFloat, requiredHeight: CGFloat) -> CGFloat {
                if yPosition + requiredHeight > layout.contentBottom {
                    return beginPage()
                }
                return yPosition
            }

            var yPosition = beginPage()
            yPosition = drawHeroSummary(
                summary,
                yPosition: yPosition,
                layout: layout,
                palette: palette,
                periodLabel: periodLabel,
                periodText: periodText
            )

            yPosition += 18
            yPosition = ensureSpace(yPosition, requiredHeight: 86)
            yPosition = drawStatusCard(
                summary.statusText,
                yPosition: yPosition,
                layout: layout,
                palette: palette,
                color: summary.netBalance >= 0 ? palette.positive : palette.negative
            )

            yPosition += 22
            yPosition = ensureSpace(yPosition, requiredHeight: 150)
            yPosition = drawCategoryBreakdown(
                rows: categoryRows,
                yPosition: yPosition,
                layout: layout,
                palette: palette
            )

            yPosition += 22
            if !categoryRows.isEmpty {
                yPosition = drawCategoryTable(
                    rows: categoryRows,
                    yPosition: yPosition,
                    layout: layout,
                    palette: palette,
                    ensureSpace: ensureSpace
                )
            }

            yPosition += 22
            if !recurringRows.isEmpty {
                yPosition = drawRecurringTable(
                    rows: recurringRows,
                    yPosition: yPosition,
                    layout: layout,
                    palette: palette,
                    ensureSpace: ensureSpace
                )
            }

            if categoryRows.isEmpty && recurringRows.isEmpty {
                yPosition = ensureSpace(yPosition, requiredHeight: 90)
                _ = drawEmptyState(yPosition: yPosition, layout: layout, palette: palette)
            }
        }
        
        return pdfData
    }

    private func makePDFSummary(_ data: ExportData) -> PDFReportSummary {
        let incomeCategories = data.financialCategories.filter { $0.type == "income" }
        let expenseCategories = data.financialCategories.filter { $0.type == "expense" }
        let totalIncome = incomeCategories.reduce(0) { $0 + $1.amount }
        let totalExpenses = expenseCategories.reduce(0) { $0 + $1.amount }
        let netBalance = totalIncome - totalExpenses
        let statusFormat = netBalance >= 0
            ? localized("export.pdf.status.positive", defaultValue: "You ended this period ahead by %@.")
            : localized("export.pdf.status.negative", defaultValue: "Expenses were higher than income by %@ this period.")
        let statusText = String(format: statusFormat, formatCurrency(abs(netBalance)))

        return PDFReportSummary(
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netBalance: netBalance,
            categoryCount: data.financialCategories.count,
            recurringCount: data.recurringTransactions.count,
            statusText: statusText
        )
    }

    private func makeCategoryRows(_ categories: [FinancialCategory]) -> [PDFCategoryRow] {
        categories
            .sorted {
                if $0.type != $1.type {
                    return ($0.type ?? "") < ($1.type ?? "")
                }
                return abs($0.amount) > abs($1.amount)
            }
            .map { category in
                PDFCategoryRow(
                    name: DataSeedingService.displayName(for: category),
                    type: localizedCategoryType(category.type),
                    amount: category.amount,
                    frequency: localizedFrequency(category.frequency),
                    isIncome: category.type == "income"
                )
            }
    }

    private func makeRecurringRows(_ transactions: [RecurringTransaction]) -> [PDFRecurringRow] {
        transactions
            .sorted { ($0.title ?? "") < ($1.title ?? "") }
            .map { transaction in
                PDFRecurringRow(
                    title: transaction.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                        ? transaction.title ?? ""
                        : localized("export.pdf.unknown_item", defaultValue: "Unknown item"),
                    category: transaction.categoryName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                        ? transaction.categoryName ?? ""
                        : localized("export.pdf.uncategorized", defaultValue: "Uncategorized"),
                    type: localizedCategoryType(transaction.categoryType),
                    amount: transaction.amount,
                    frequency: localizedFrequency(transaction.frequency),
                    isActive: transaction.isActive
                )
            }
    }

    private func drawPageChrome(
        context: UIGraphicsPDFRendererContext,
        layout: PDFLayout,
        palette: PDFPalette,
        reportTitle: String,
        periodText: String,
        generatedText: String,
        pageNumber: Int
    ) {
        palette.pageBackground.setFill()
        UIBezierPath(rect: layout.pageRect).fill()

        let brandMarkRect = CGRect(x: layout.margin, y: 36, width: 34, height: 34)
        palette.accent.setFill()
        UIBezierPath(roundedRect: brandMarkRect, cornerRadius: 10).fill()
        drawText(
            "B",
            in: brandMarkRect.offsetBy(dx: 0, dy: 6),
            font: .boldSystemFont(ofSize: 15),
            color: .white,
            alignment: .center
        )

        drawText(
            "BudgetMeter",
            in: CGRect(x: brandMarkRect.maxX + 12, y: 35, width: 190, height: 18),
            font: .boldSystemFont(ofSize: 13),
            color: palette.primaryText
        )
        drawText(
            reportTitle,
            in: CGRect(x: brandMarkRect.maxX + 12, y: 54, width: 260, height: 22),
            font: .systemFont(ofSize: 13, weight: .medium),
            color: palette.secondaryText
        )
        drawText(
            periodText,
            in: CGRect(x: layout.pageRect.width - layout.margin - 220, y: 40, width: 220, height: 18),
            font: .systemFont(ofSize: 10, weight: .medium),
            color: palette.secondaryText,
            alignment: .right
        )
        drawText(
            generatedText,
            in: CGRect(x: layout.pageRect.width - layout.margin - 220, y: 58, width: 220, height: 18),
            font: .systemFont(ofSize: 9),
            color: palette.mutedText,
            alignment: .right
        )

        palette.divider.setStroke()
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: layout.margin, y: 92))
        divider.addLine(to: CGPoint(x: layout.pageRect.width - layout.margin, y: 92))
        divider.lineWidth = 1
        divider.stroke()

        let footerY = layout.pageRect.height - 34
        drawText(
            localized("export.pdf.footer", defaultValue: "BudgetMeter financial report"),
            in: CGRect(x: layout.margin, y: footerY, width: 230, height: 14),
            font: .systemFont(ofSize: 8),
            color: palette.mutedText
        )
        drawText(
            String(format: localized("export.pdf.page", defaultValue: "Page %d"), pageNumber),
            in: CGRect(x: layout.pageRect.width - layout.margin - 90, y: footerY, width: 90, height: 14),
            font: .systemFont(ofSize: 8),
            color: palette.mutedText,
            alignment: .right
        )
    }

    private func drawHeroSummary(
        _ summary: PDFReportSummary,
        yPosition: CGFloat,
        layout: PDFLayout,
        palette: PDFPalette,
        periodLabel: String,
        periodText: String
    ) -> CGFloat {
        let cardRect = CGRect(x: layout.margin, y: yPosition, width: layout.contentWidth, height: 186)
        drawCard(cardRect, palette: palette)

        drawText(
            localized("export.pdf.hero.title", defaultValue: "Financial snapshot"),
            in: CGRect(x: cardRect.minX + 22, y: cardRect.minY + 18, width: 260, height: 24),
            font: .boldSystemFont(ofSize: 20),
            color: palette.primaryText
        )
        drawText(
            "\(periodLabel): \(periodText)",
            in: CGRect(x: cardRect.minX + 22, y: cardRect.minY + 45, width: 280, height: 18),
            font: .systemFont(ofSize: 10, weight: .medium),
            color: palette.secondaryText
        )

        let metricsTop = cardRect.minY + 82
        let metricGap: CGFloat = 12
        let metricWidth = (cardRect.width - 44 - (metricGap * 3)) / 4
        let metrics = [
            PDFMetric(label: localized("export.pdf.metric.income", defaultValue: "Income"), value: formatCurrency(summary.totalIncome), color: palette.positive),
            PDFMetric(label: localized("export.pdf.metric.expenses", defaultValue: "Expenses"), value: formatCurrency(summary.totalExpenses), color: palette.negative),
            PDFMetric(label: localized("export.pdf.metric.net", defaultValue: "Net balance"), value: formatCurrency(summary.netBalance), color: summary.netBalance >= 0 ? palette.positive : palette.negative),
            PDFMetric(label: localized("export.pdf.metric.recurring", defaultValue: "Recurring"), value: "\(summary.recurringCount)", color: palette.accent)
        ]

        for (index, metric) in metrics.enumerated() {
            let x = cardRect.minX + 22 + CGFloat(index) * (metricWidth + metricGap)
            drawMetric(metric, in: CGRect(x: x, y: metricsTop, width: metricWidth, height: 76), palette: palette)
        }

        return cardRect.maxY
    }

    private func drawStatusCard(
        _ text: String,
        yPosition: CGFloat,
        layout: PDFLayout,
        palette: PDFPalette,
        color: UIColor
    ) -> CGFloat {
        let rect = CGRect(x: layout.margin, y: yPosition, width: layout.contentWidth, height: 58)
        drawCard(rect, palette: palette)

        color.setFill()
        UIBezierPath(roundedRect: CGRect(x: rect.minX, y: rect.minY, width: 5, height: rect.height), cornerRadius: 2.5).fill()
        drawText(
            localized("export.pdf.status.title", defaultValue: "Status"),
            in: CGRect(x: rect.minX + 20, y: rect.minY + 12, width: 100, height: 14),
            font: .boldSystemFont(ofSize: 10),
            color: palette.secondaryText
        )
        drawText(
            text,
            in: CGRect(x: rect.minX + 20, y: rect.minY + 29, width: rect.width - 40, height: 18),
            font: .systemFont(ofSize: 12, weight: .medium),
            color: palette.primaryText
        )

        return rect.maxY
    }

    private func drawCategoryBreakdown(
        rows: [PDFCategoryRow],
        yPosition: CGFloat,
        layout: PDFLayout,
        palette: PDFPalette
    ) -> CGFloat {
        let sectionHeight: CGFloat = rows.isEmpty ? 98 : 150
        let rect = CGRect(x: layout.margin, y: yPosition, width: layout.contentWidth, height: sectionHeight)
        drawSectionTitle(localized("export.pdf.section.breakdown", defaultValue: "Income and expense breakdown"), yPosition: yPosition, layout: layout, palette: palette)

        guard !rows.isEmpty else {
            drawText(
                localized("export.pdf.empty.categories", defaultValue: "No categories are available for this export."),
                in: CGRect(x: rect.minX, y: rect.minY + 34, width: rect.width, height: 36),
                font: .systemFont(ofSize: 11),
                color: palette.secondaryText
            )
            return rect.maxY
        }

        let incomeTotal = rows.filter(\.isIncome).reduce(0) { $0 + $1.amount }
        let expenseTotal = rows.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        let total = max(incomeTotal + expenseTotal, 1)
        let barTop = yPosition + 42
        let barWidth = layout.contentWidth
        let incomeWidth = barWidth * CGFloat(incomeTotal / total)

        palette.divider.setFill()
        UIBezierPath(roundedRect: CGRect(x: layout.margin, y: barTop, width: barWidth, height: 12), cornerRadius: 6).fill()
        palette.positive.setFill()
        UIBezierPath(roundedRect: CGRect(x: layout.margin, y: barTop, width: max(incomeWidth, incomeTotal > 0 ? 5 : 0), height: 12), cornerRadius: 6).fill()
        palette.negative.setFill()
        UIBezierPath(roundedRect: CGRect(x: layout.margin + incomeWidth, y: barTop, width: max(barWidth - incomeWidth, expenseTotal > 0 ? 5 : 0), height: 12), cornerRadius: 6).fill()

        let labelY = barTop + 25
        drawLegend(label: localized("export.pdf.metric.income", defaultValue: "Income"), value: formatCurrency(incomeTotal), color: palette.positive, x: layout.margin, y: labelY, palette: palette)
        drawLegend(label: localized("export.pdf.metric.expenses", defaultValue: "Expenses"), value: formatCurrency(expenseTotal), color: palette.negative, x: layout.margin + 210, y: labelY, palette: palette)

        let topRows = Array(rows.sorted { abs($0.amount) > abs($1.amount) }.prefix(3))
        var topY = labelY + 42
        drawText(
            localized("export.pdf.section.top_categories", defaultValue: "Top categories"),
            in: CGRect(x: layout.margin, y: topY, width: layout.contentWidth, height: 16),
            font: .boldSystemFont(ofSize: 11),
            color: palette.primaryText
        )
        topY += 22

        for row in topRows {
            let color = row.isIncome ? palette.positive : palette.negative
            drawLegend(label: row.name, value: formatCurrency(row.amount), color: color, x: layout.margin, y: topY, palette: palette)
            topY += 20
        }

        return max(topY, rect.maxY)
    }

    private func drawCategoryTable(
        rows: [PDFCategoryRow],
        yPosition: CGFloat,
        layout: PDFLayout,
        palette: PDFPalette,
        ensureSpace: (CGFloat, CGFloat) -> CGFloat
    ) -> CGFloat {
        var currentY = ensureSpace(yPosition, 72)
        drawSectionTitle(localized("export.pdf.section.categories", defaultValue: "Categories"), yPosition: currentY, layout: layout, palette: palette)
        currentY += 30
        currentY = drawCategoryTableHeader(yPosition: currentY, layout: layout, palette: palette)

        for row in rows {
            currentY = ensureSpace(currentY, 36)
            if currentY == layout.contentTop {
                drawSectionTitle(localized("export.pdf.section.categories", defaultValue: "Categories"), yPosition: currentY, layout: layout, palette: palette)
                currentY += 30
                currentY = drawCategoryTableHeader(yPosition: currentY, layout: layout, palette: palette)
            }
            currentY = drawCategoryRow(row, yPosition: currentY, layout: layout, palette: palette)
        }

        return currentY
    }

    private func drawRecurringTable(
        rows: [PDFRecurringRow],
        yPosition: CGFloat,
        layout: PDFLayout,
        palette: PDFPalette,
        ensureSpace: (CGFloat, CGFloat) -> CGFloat
    ) -> CGFloat {
        var currentY = ensureSpace(yPosition, 72)
        drawSectionTitle(localized("export.pdf.section.recurring", defaultValue: "Recurring transactions"), yPosition: currentY, layout: layout, palette: palette)
        currentY += 30
        currentY = drawRecurringTableHeader(yPosition: currentY, layout: layout, palette: palette)

        for row in rows {
            currentY = ensureSpace(currentY, 38)
            if currentY == layout.contentTop {
                drawSectionTitle(localized("export.pdf.section.recurring", defaultValue: "Recurring transactions"), yPosition: currentY, layout: layout, palette: palette)
                currentY += 30
                currentY = drawRecurringTableHeader(yPosition: currentY, layout: layout, palette: palette)
            }
            currentY = drawRecurringRow(row, yPosition: currentY, layout: layout, palette: palette)
        }

        return currentY
    }

    private func drawEmptyState(yPosition: CGFloat, layout: PDFLayout, palette: PDFPalette) -> CGFloat {
        let rect = CGRect(x: layout.margin, y: yPosition, width: layout.contentWidth, height: 76)
        drawCard(rect, palette: palette)
        drawText(
            localized("export.pdf.empty.title", defaultValue: "No financial data yet"),
            in: CGRect(x: rect.minX + 18, y: rect.minY + 16, width: rect.width - 36, height: 18),
            font: .boldSystemFont(ofSize: 13),
            color: palette.primaryText
        )
        drawText(
            localized("export.pdf.empty.body", defaultValue: "Add income, expenses, or recurring transactions in BudgetMeter to make this report more useful."),
            in: CGRect(x: rect.minX + 18, y: rect.minY + 39, width: rect.width - 36, height: 28),
            font: .systemFont(ofSize: 10),
            color: palette.secondaryText
        )
        return rect.maxY
    }

    private func drawCategoryTableHeader(yPosition: CGFloat, layout: PDFLayout, palette: PDFPalette) -> CGFloat {
        let rect = CGRect(x: layout.margin, y: yPosition, width: layout.contentWidth, height: 26)
        palette.tableHeader.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 7).fill()
        drawText(localized("export.pdf.table.category", defaultValue: "Category"), in: CGRect(x: rect.minX + 12, y: rect.minY + 7, width: 185, height: 12), font: .boldSystemFont(ofSize: 8), color: palette.secondaryText)
        drawText(localized("export.pdf.table.type", defaultValue: "Type"), in: CGRect(x: rect.minX + 210, y: rect.minY + 7, width: 80, height: 12), font: .boldSystemFont(ofSize: 8), color: palette.secondaryText)
        drawText(localized("export.pdf.table.frequency", defaultValue: "Frequency"), in: CGRect(x: rect.minX + 300, y: rect.minY + 7, width: 90, height: 12), font: .boldSystemFont(ofSize: 8), color: palette.secondaryText)
        drawText(localized("export.pdf.table.amount", defaultValue: "Amount"), in: CGRect(x: rect.maxX - 122, y: rect.minY + 7, width: 110, height: 12), font: .boldSystemFont(ofSize: 8), color: palette.secondaryText, alignment: .right)
        return rect.maxY + 4
    }

    private func drawCategoryRow(_ row: PDFCategoryRow, yPosition: CGFloat, layout: PDFLayout, palette: PDFPalette) -> CGFloat {
        let rect = CGRect(x: layout.margin, y: yPosition, width: layout.contentWidth, height: 32)
        palette.cardBackground.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 6).fill()
        drawText(row.name, in: CGRect(x: rect.minX + 12, y: rect.minY + 8, width: 185, height: 16), font: .systemFont(ofSize: 9, weight: .medium), color: palette.primaryText)
        drawText(row.type, in: CGRect(x: rect.minX + 210, y: rect.minY + 8, width: 80, height: 16), font: .systemFont(ofSize: 9), color: palette.secondaryText)
        drawText(row.frequency, in: CGRect(x: rect.minX + 300, y: rect.minY + 8, width: 90, height: 16), font: .systemFont(ofSize: 9), color: palette.secondaryText)
        drawText(formatCurrency(row.amount), in: CGRect(x: rect.maxX - 122, y: rect.minY + 8, width: 110, height: 16), font: .systemFont(ofSize: 9, weight: .semibold), color: row.isIncome ? palette.positive : palette.negative, alignment: .right)
        return rect.maxY + 4
    }

    private func drawRecurringTableHeader(yPosition: CGFloat, layout: PDFLayout, palette: PDFPalette) -> CGFloat {
        let rect = CGRect(x: layout.margin, y: yPosition, width: layout.contentWidth, height: 26)
        palette.tableHeader.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 7).fill()
        drawText(localized("export.pdf.table.item", defaultValue: "Item"), in: CGRect(x: rect.minX + 12, y: rect.minY + 7, width: 180, height: 12), font: .boldSystemFont(ofSize: 8), color: palette.secondaryText)
        drawText(localized("export.pdf.table.category", defaultValue: "Category"), in: CGRect(x: rect.minX + 202, y: rect.minY + 7, width: 120, height: 12), font: .boldSystemFont(ofSize: 8), color: palette.secondaryText)
        drawText(localized("export.pdf.table.frequency", defaultValue: "Frequency"), in: CGRect(x: rect.minX + 330, y: rect.minY + 7, width: 70, height: 12), font: .boldSystemFont(ofSize: 8), color: palette.secondaryText)
        drawText(localized("export.pdf.table.amount", defaultValue: "Amount"), in: CGRect(x: rect.maxX - 112, y: rect.minY + 7, width: 100, height: 12), font: .boldSystemFont(ofSize: 8), color: palette.secondaryText, alignment: .right)
        return rect.maxY + 4
    }

    private func drawRecurringRow(_ row: PDFRecurringRow, yPosition: CGFloat, layout: PDFLayout, palette: PDFPalette) -> CGFloat {
        let rect = CGRect(x: layout.margin, y: yPosition, width: layout.contentWidth, height: 34)
        palette.cardBackground.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 6).fill()
        drawText(row.title, in: CGRect(x: rect.minX + 12, y: rect.minY + 6, width: 180, height: 12), font: .systemFont(ofSize: 9, weight: .medium), color: palette.primaryText)
        drawText(row.isActive ? localized("export.pdf.active", defaultValue: "Active") : localized("export.pdf.inactive", defaultValue: "Inactive"), in: CGRect(x: rect.minX + 12, y: rect.minY + 19, width: 70, height: 10), font: .systemFont(ofSize: 7), color: palette.mutedText)
        drawText(row.category, in: CGRect(x: rect.minX + 202, y: rect.minY + 9, width: 120, height: 14), font: .systemFont(ofSize: 9), color: palette.secondaryText)
        drawText(row.frequency, in: CGRect(x: rect.minX + 330, y: rect.minY + 9, width: 70, height: 14), font: .systemFont(ofSize: 9), color: palette.secondaryText)
        drawText(formatCurrency(row.amount), in: CGRect(x: rect.maxX - 112, y: rect.minY + 9, width: 100, height: 14), font: .systemFont(ofSize: 9, weight: .semibold), color: row.type == localizedCategoryType("income") ? palette.positive : palette.negative, alignment: .right)
        return rect.maxY + 4
    }

    private func drawMetric(_ metric: PDFMetric, in rect: CGRect, palette: PDFPalette) {
        palette.metricBackground.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 10).fill()
        metric.color.setFill()
        UIBezierPath(roundedRect: CGRect(x: rect.minX + 12, y: rect.minY + 12, width: 18, height: 4), cornerRadius: 2).fill()
        drawText(metric.label, in: CGRect(x: rect.minX + 12, y: rect.minY + 25, width: rect.width - 24, height: 13), font: .systemFont(ofSize: 8, weight: .medium), color: palette.secondaryText)
        drawText(metric.value, in: CGRect(x: rect.minX + 12, y: rect.minY + 43, width: rect.width - 24, height: 20), font: .boldSystemFont(ofSize: 13), color: palette.primaryText, minimumScaleFactor: 0.72)
    }

    private func drawLegend(label: String, value: String, color: UIColor, x: CGFloat, y: CGFloat, palette: PDFPalette) {
        color.setFill()
        UIBezierPath(roundedRect: CGRect(x: x, y: y + 3, width: 8, height: 8), cornerRadius: 4).fill()
        drawText(label, in: CGRect(x: x + 14, y: y, width: 118, height: 14), font: .systemFont(ofSize: 9), color: palette.secondaryText)
        drawText(value, in: CGRect(x: x + 136, y: y, width: 72, height: 14), font: .systemFont(ofSize: 9, weight: .semibold), color: palette.primaryText, alignment: .right, minimumScaleFactor: 0.75)
    }

    private func drawSectionTitle(_ title: String, yPosition: CGFloat, layout: PDFLayout, palette: PDFPalette) {
        palette.accent.setFill()
        UIBezierPath(roundedRect: CGRect(x: layout.margin, y: yPosition + 2, width: 4, height: 18), cornerRadius: 2).fill()
        drawText(title, in: CGRect(x: layout.margin + 12, y: yPosition, width: layout.contentWidth - 12, height: 22), font: .boldSystemFont(ofSize: 15), color: palette.primaryText)
    }

    private func drawCard(_ rect: CGRect, palette: PDFPalette) {
        palette.cardShadow.setFill()
        UIBezierPath(roundedRect: rect.offsetBy(dx: 0, dy: 1), cornerRadius: 14).fill()
        palette.cardBackground.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 14).fill()
        palette.cardBorder.setStroke()
        let border = UIBezierPath(roundedRect: rect, cornerRadius: 14)
        border.lineWidth = 0.75
        border.stroke()
    }

    private func drawText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment = .left,
        minimumScaleFactor: CGFloat = 1
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]

        let attributedText = NSAttributedString(string: text, attributes: attributes)
        if minimumScaleFactor < 1 {
            let mutable = NSMutableAttributedString(attributedString: attributedText)
            let fullRange = NSRange(location: 0, length: mutable.length)
            var currentFont = font
            while mutable.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).width > rect.width,
                  currentFont.pointSize > font.pointSize * minimumScaleFactor {
                currentFont = font.withSize(currentFont.pointSize - 0.5)
                mutable.addAttribute(.font, value: currentFont, range: fullRange)
            }
            mutable.draw(in: rect)
            return
        }

        attributedText.draw(in: rect)
    }

    private func localized(_ key: String, defaultValue: String) -> String {
        key.localized(defaultValue: defaultValue, table: "UI")
    }

    private func localizedCategoryType(_ value: String?) -> String {
        switch value {
        case "income":
            return localized("export.pdf.type.income", defaultValue: "Income")
        case "expense":
            return localized("export.pdf.type.expense", defaultValue: "Expense")
        default:
            return localized("export.pdf.type.unknown", defaultValue: "Unknown")
        }
    }

    private func localizedFrequency(_ value: String?) -> String {
        switch value {
        case "daily":
            return localized("export.pdf.frequency.daily", defaultValue: "Daily")
        case "weekly":
            return localized("export.pdf.frequency.weekly", defaultValue: "Weekly")
        case "monthly":
            return localized("export.pdf.frequency.monthly", defaultValue: "Monthly")
        case "yearly":
            return localized("export.pdf.frequency.yearly", defaultValue: "Yearly")
        case "once":
            return localized("export.pdf.frequency.once", defaultValue: "One-time")
        default:
            return localized("export.pdf.frequency.unknown", defaultValue: "Unknown")
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        CurrencyDisplay.format(amount: amount)
    }

    private func formatDateRange(_ dateRange: DateInterval?) -> String {
        guard let dateRange else {
            return localized("export.pdf.period.all_time", defaultValue: "All time")
        }
        let start = DateFormattingHelper.shared.formatMediumNoTime(dateRange.start)
        let end = DateFormattingHelper.shared.formatMediumNoTime(dateRange.end)
        return "\(start) - \(end)"
    }
    
    private func generateCSVContent(_ data: ExportData) -> String {
        var csvContent = "BudgetMeter Export Report\n"
        csvContent += "Exported on: \(formatDate(data.exportDate))\n\n"
        
        // Financial Categories
        csvContent += "Financial Categories\n"
        csvContent += "Type,Amount,Frequency\n"
        for category in data.financialCategories {
            csvContent += "\(category.type ?? ""),\(category.amount),\(category.frequency ?? "")\n"
        }
        csvContent += "\n"
        
        // Recurring Transactions
        csvContent += "Recurring Transactions\n"
        csvContent += "Title,Amount,Category,Type,Frequency,Start Date,End Date,Active\n"
        for transaction in data.recurringTransactions {
            csvContent += "\(transaction.title ?? ""),\(transaction.amount),\(transaction.categoryName ?? ""),\(transaction.categoryType ?? ""),\(transaction.frequency ?? ""),\(formatDate(transaction.startDate ?? Date())),\(transaction.endDate != nil ? formatDate(transaction.endDate!) : ""),\(transaction.isActive)\n"
        }
        
        return csvContent
    }
    
    private func generateJSONData(_ data: ExportData) throws -> Data {
        let financialCategoriesData = data.financialCategories.map { category in
            [
                "id": category.id?.uuidString ?? "",
                "type": category.type ?? "",
                "amount": category.amount,
                "frequency": category.frequency ?? "",
                "uniqueID": category.uniqueID ?? ""
            ]
        }
        
        let recurringTransactionsData = data.recurringTransactions.map { transaction in
            [
                "id": transaction.id?.uuidString ?? "",
                "title": transaction.title ?? "",
                "amount": transaction.amount,
                "categoryName": transaction.categoryName ?? "",
                "categoryType": transaction.categoryType ?? "",
                "frequency": transaction.frequency ?? "",
                "startDate": transaction.startDate != nil ? DateFormattingHelper.shared.formatISO8601(transaction.startDate!) : NSNull(),
                "endDate": transaction.endDate != nil ? DateFormattingHelper.shared.formatISO8601(transaction.endDate!) : NSNull(),
                "nextDueDate": transaction.nextDueDate != nil ? DateFormattingHelper.shared.formatISO8601(transaction.nextDueDate!) : NSNull(),
                "isActive": transaction.isActive,
                "notes": transaction.notes ?? "",
                "createdAt": transaction.createdAt != nil ? DateFormattingHelper.shared.formatISO8601(transaction.createdAt!) : NSNull(),
                "lastProcessedDate": transaction.lastProcessedDate != nil ? DateFormattingHelper.shared.formatISO8601(transaction.lastProcessedDate!) : NSNull()
            ]
        }
        
        
        let dateRangeData: [String: Any]? = data.dateRange != nil ? [
            "start": DateFormattingHelper.shared.formatISO8601(data.dateRange!.start),
            "end": DateFormattingHelper.shared.formatISO8601(data.dateRange!.end)
        ] : nil
        
        let appSettingsData: [String: Any]? = data.appSettings != nil ? [
            "preferredCurrencyCode": data.appSettings!.preferredCurrencyCode ?? "",
            "savingsGoalAmount": data.appSettings!.savingsGoalAmount,
            "isPremiumUser": data.appSettings!.isPremiumUser,
            "premiumPurchaseDate": data.appSettings!.premiumPurchaseDate != nil ? DateFormattingHelper.shared.formatISO8601(data.appSettings!.premiumPurchaseDate!) : NSNull(),
            "isBiometricEnabled": data.appSettings!.isBiometricEnabled,
            "selectedTheme": data.appSettings!.selectedTheme ?? "",
            "customAppIcon": data.appSettings!.customAppIcon ?? "",
            "lastExportDate": data.appSettings!.lastExportDate != nil ? DateFormattingHelper.shared.formatISO8601(data.appSettings!.lastExportDate!) : NSNull()
        ] : nil
        
        let exportObject: [String: Any] = [
            "exportDate": DateFormattingHelper.shared.formatISO8601(data.exportDate),
            "dateRange": dateRangeData ?? NSNull(),
            "financialCategories": financialCategoriesData,
            "recurringTransactions": recurringTransactionsData,
            "appSettings": appSettingsData ?? NSNull()
        ]
        
        return try JSONSerialization.data(withJSONObject: exportObject, options: .prettyPrinted)
    }
    
    private func generateSummaryText(_ data: ExportData) -> String {
        let totalCategories = data.financialCategories.count
        let totalRecurring = data.recurringTransactions.count
        
        let totalIncome = data.financialCategories
            .filter { $0.type == "income" }
            .reduce(0) { $0 + $1.amount }
        
        let totalExpenses = data.financialCategories
            .filter { $0.type == "expense" }
            .reduce(0) { $0 + $1.amount }
        
        return """
        Summary:
        • Total Financial Categories: \(totalCategories)
        • Total Recurring Transactions: \(totalRecurring)
        • Total Income: \(CurrencyHelper.formatAmount(totalIncome))
        • Total Expenses: \(CurrencyHelper.formatAmount(totalExpenses))
        • Net Balance: \(CurrencyHelper.formatAmount(totalIncome - totalExpenses))
        """
    }
    
    private func formatDate(_ date: Date) -> String {
        DateFormattingHelper.shared.formatMediumWithTime(date)
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func cleanupOldExports() {
        let documentsDirectory = getDocumentsDirectory()
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.creationDateKey])
            let exportFiles = files.filter { $0.lastPathComponent.hasPrefix("BudgetMeter_Export_") }
            
            // Keep only the 5 most recent exports
            let sortedFiles = exportFiles.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
            
            if sortedFiles.count > 5 {
                for file in sortedFiles.dropFirst(5) {
                    try fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("Failed to cleanup old exports: \(error)")
        }
    }
}
