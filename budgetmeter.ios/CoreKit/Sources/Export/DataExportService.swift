import Foundation
import CoreData
import PDFKit
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable {
    case pdf = "pdf"
    case csv = "csv"
    case json = "json"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .pdf: return "export.format.pdf".localized(defaultValue: "PDF Report")
        case .csv: return "export.format.csv".localized(defaultValue: "CSV Data")
        case .json: return "export.format.json".localized(defaultValue: "JSON Data")
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

final class DataExportService {
    static let shared = DataExportService()
    
    private let persistenceService: PersistenceService
    
    private init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
    }
    
    func exportData(format: ExportFormat, dateRange: DateInterval? = nil) async throws -> URL {
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
        let pdfMetaData = [
            kCGPDFContextCreator: "BudgetMeter",
            kCGPDFContextAuthor: "BudgetMeter App",
            kCGPDFContextTitle: "BudgetMeter Export Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            
            // Title
            let title = "BudgetMeter Export Report"
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            title.draw(at: CGPoint(x: (pageWidth - titleSize.width) / 2, y: yPosition), withAttributes: titleAttributes)
            yPosition += titleSize.height + 20
            
            // Export date
            let dateString = "Exported on: \(formatDate(data.exportDate))"
            let dateFont = UIFont.systemFont(ofSize: 14)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: dateFont,
                .foregroundColor: UIColor.gray
            ]
            dateString.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: dateAttributes)
            yPosition += 30
            
            // Summary
            let summary = generateSummaryText(data)
            let summaryFont = UIFont.systemFont(ofSize: 12)
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: summaryFont,
                .foregroundColor: UIColor.black
            ]
            
            let summarySize = summary.boundingRect(
                with: CGSize(width: pageWidth - 100, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: summaryAttributes,
                context: nil
            ).size
            
            summary.draw(in: CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: summarySize.height), withAttributes: summaryAttributes)
            yPosition += summarySize.height + 30
            
            // Financial Categories
            if !data.financialCategories.isEmpty {
                yPosition = drawSection("Financial Categories", yPosition: yPosition, pageWidth: pageWidth, context: context)
                yPosition = drawFinancialCategories(data.financialCategories, yPosition: yPosition, pageWidth: pageWidth, context: context)
            }
            
            // Recurring Transactions
            if !data.recurringTransactions.isEmpty {
                yPosition = drawSection("Recurring Transactions", yPosition: yPosition, pageWidth: pageWidth, context: context)
                yPosition = drawRecurringTransactions(data.recurringTransactions, yPosition: yPosition, pageWidth: pageWidth, context: context)
            }
        }
        
        return pdfData
    }
    
    private func drawSection(_ title: String, yPosition: CGFloat, pageWidth: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = yPosition
        
        // Check if we need a new page
        if currentY > 10 * 72.0 {
            context.beginPage()
            currentY = 50
        }
        
        let sectionFont = UIFont.boldSystemFont(ofSize: 16)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: UIColor.black
        ]
        let sectionSize = title.size(withAttributes: sectionAttributes)
        title.draw(at: CGPoint(x: 50, y: currentY), withAttributes: sectionAttributes)
        currentY += sectionSize.height + 10
        
        return currentY
    }
    
    private func drawFinancialCategories(_ categories: [FinancialCategory], yPosition: CGFloat, pageWidth: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = yPosition
        let font = UIFont.systemFont(ofSize: 10)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        for category in categories {
            // Check if we need a new page
            if currentY > 10 * 72.0 {
                context.beginPage()
                currentY = 50
            }
            
            let text = "\(category.type ?? "Unknown"): \(CurrencyHelper.formatAmount(category.amount))"
            let textSize = text.size(withAttributes: attributes)
            text.draw(at: CGPoint(x: 70, y: currentY), withAttributes: attributes)
            currentY += textSize.height + 5
        }
        
        return currentY + 20
    }
    
    private func drawRecurringTransactions(_ transactions: [RecurringTransaction], yPosition: CGFloat, pageWidth: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = yPosition
        let font = UIFont.systemFont(ofSize: 10)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        for transaction in transactions {
            // Check if we need a new page
            if currentY > 10 * 72.0 {
                context.beginPage()
                currentY = 50
            }
            
            let text = "\(transaction.title ?? "Unknown"): \(CurrencyHelper.formatAmount(transaction.amount)) (\(transaction.frequency ?? "monthly"))"
            let textSize = text.size(withAttributes: attributes)
            text.draw(at: CGPoint(x: 70, y: currentY), withAttributes: attributes)
            currentY += textSize.height + 5
        }
        
        return currentY + 20
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
        let dateFormatter = ISO8601DateFormatter()
        
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
                "startDate": transaction.startDate != nil ? dateFormatter.string(from: transaction.startDate!) : NSNull(),
                "endDate": transaction.endDate != nil ? dateFormatter.string(from: transaction.endDate!) : NSNull(),
                "nextDueDate": transaction.nextDueDate != nil ? dateFormatter.string(from: transaction.nextDueDate!) : NSNull(),
                "isActive": transaction.isActive,
                "notes": transaction.notes ?? "",
                "createdAt": transaction.createdAt != nil ? dateFormatter.string(from: transaction.createdAt!) : NSNull(),
                "lastProcessedDate": transaction.lastProcessedDate != nil ? dateFormatter.string(from: transaction.lastProcessedDate!) : NSNull()
            ]
        }
        
        
        let dateRangeData: [String: Any]? = data.dateRange != nil ? [
            "start": dateFormatter.string(from: data.dateRange!.start),
            "end": dateFormatter.string(from: data.dateRange!.end)
        ] : nil
        
        let appSettingsData: [String: Any]? = data.appSettings != nil ? [
            "preferredCurrencyCode": data.appSettings!.preferredCurrencyCode ?? "",
            "savingsGoalAmount": data.appSettings!.savingsGoalAmount,
            "isPremiumUser": data.appSettings!.isPremiumUser,
            "premiumPurchaseDate": data.appSettings!.premiumPurchaseDate != nil ? dateFormatter.string(from: data.appSettings!.premiumPurchaseDate!) : NSNull(),
            "isBiometricEnabled": data.appSettings!.isBiometricEnabled,
            "selectedTheme": data.appSettings!.selectedTheme ?? "",
            "customAppIcon": data.appSettings!.customAppIcon ?? "",
            "lastExportDate": data.appSettings!.lastExportDate != nil ? dateFormatter.string(from: data.appSettings!.lastExportDate!) : NSNull()
        ] : nil
        
        let exportObject: [String: Any] = [
            "exportDate": dateFormatter.string(from: data.exportDate),
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
