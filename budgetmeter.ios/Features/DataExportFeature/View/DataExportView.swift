import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct DataExportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var selectedDateRange: DateRangeOption = .all
    @State private var customStartDate: Date = Date()
    @State private var customEndDate: Date = Date()
    @State private var isExporting: Bool = false
    @State private var exportProgress: Double = 0.0
    @State private var showingShareSheet: Bool = false
    @State private var exportedFileURL: URL?
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    
    enum DateRangeOption: String, CaseIterable, Identifiable {
        case all = "all"
        case lastMonth = "lastMonth"
        case last3Months = "last3Months"
        case lastYear = "lastYear"
        case custom = "custom"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .all: return String(localized: "export.date_range.all", defaultValue: "All Time", table: "UI")
            case .lastMonth: return String(localized: "export.date_range.last_month", defaultValue: "Last Month", table: "UI")
            case .last3Months: return String(localized: "export.date_range.last_3_months", defaultValue: "Last 3 Months", table: "UI")
            case .lastYear: return String(localized: "export.date_range.last_year", defaultValue: "Last Year", table: "UI")
            case .custom: return String(localized: "export.date_range.custom", defaultValue: "Custom Range", table: "UI")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(String(localized: "export.format.title", defaultValue: "Export Format", table: "UI")) {
                    ForEach(ExportFormat.allCases) { format in
                        HStack {
                            Image(systemName: formatIcon(for: format))
                                .foregroundColor(Color(hex: "4A90E2"))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text(format.displayName)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text(formatDescription(for: format))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedFormat == format {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "4A90E2"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFormat = format
                        }
                    }
                }
                
                Section(String(localized: "export.date_range.title", defaultValue: "Date Range", table: "UI")) {
                    ForEach(DateRangeOption.allCases) { option in
                        HStack {
                            Text(option.displayName)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedDateRange == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "4A90E2"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDateRange = option
                        }
                    }
                    
                    if selectedDateRange == .custom {
                        DatePicker(String(localized: "export.start_date", defaultValue: "Start Date", table: "UI"), selection: $customStartDate, displayedComponents: .date)
                        DatePicker(String(localized: "export.end_date", defaultValue: "End Date", table: "UI"), selection: $customEndDate, displayedComponents: .date)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await exportData()
                        }
                    } label: {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            
                            Text(isExporting
                                 ? String(localized: "export.exporting", defaultValue: "Exporting...", table: "UI")
                                 : String(localized: "export.export_button", defaultValue: "Export Data", table: "UI"))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isExporting ? Color.gray : Color(hex: "4A90E2"))
                        .cornerRadius(12)
                    }
                    .disabled(isExporting)
                    
                    if isExporting {
                        ProgressView(value: exportProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "4A90E2")))
                    }
                }
                
                Section(String(localized: "export.info.title", defaultValue: "Export Information", table: "UI")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "export.info.description", defaultValue: "Your data will be exported in the selected format. The export includes:", table: "UI"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "export.info.item.categories", defaultValue: "• Financial categories and amounts", table: "UI"))
                            Text(String(localized: "export.info.item.recurring", defaultValue: "• Recurring transactions", table: "UI"))
                            Text(String(localized: "export.info.item.custom_categories", defaultValue: "• Custom categories", table: "UI"))
                            Text(String(localized: "export.info.item.settings", defaultValue: "• App settings and preferences", table: "UI"))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(String(localized: "export.nav_title", defaultValue: "Export Data", table: "UI"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "toolbar.close", defaultValue: "Close", table: "UI")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let fileURL = exportedFileURL {
                    ShareSheet(activityItems: [fileURL])
                }
            }
            .alert(String(localized: "error.title", defaultValue: "Error", table: "UI"), isPresented: $showingError) {
                Button(String(localized: "alert.ok", defaultValue: "OK", table: "UI")) { }
            } message: {
                Text(errorMessage ?? String(localized: "export.error.unknown", defaultValue: "An unknown error occurred", table: "UI"))
            }
        }
    }
    
    private func formatIcon(for format: ExportFormat) -> String {
        switch format {
        case .pdf: return "doc.text.fill"
        case .csv: return "tablecells.fill"
        case .json: return "curlybraces"
        }
    }
    
    private func formatDescription(for format: ExportFormat) -> String {
        switch format {
        case .pdf: return String(localized: "export.format.pdf.description", defaultValue: "Formatted report with charts and summaries", table: "UI")
        case .csv: return String(localized: "export.format.csv.description", defaultValue: "Spreadsheet-compatible data format", table: "UI")
        case .json: return String(localized: "export.format.json.description", defaultValue: "Machine-readable data format", table: "UI")
        }
    }
    
    private func exportData() async {
        isExporting = true
        exportProgress = 0.0
        errorMessage = nil
        
        do {
            // Simulate progress
            await updateProgress(0.2)
            
            let dateRange = calculateDateRange()
            await updateProgress(0.5)
            
            let fileURL = try await DataExportService.shared.exportData(format: selectedFormat, dateRange: dateRange)
            await updateProgress(0.8)
            
            // Update last export date in app settings
            await updateLastExportDate()
            await updateProgress(1.0)
            
            exportedFileURL = fileURL
            showingShareSheet = true
            
            // Cleanup old exports
            DataExportService.shared.cleanupOldExports()
            
        } catch {
            errorMessage = String(
                format: String(localized: "export.error.failed", defaultValue: "Export failed: %@", table: "UI"),
                error.localizedDescription
            )
            showingError = true
        }
        
        isExporting = false
        exportProgress = 0.0
    }
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            exportProgress = progress
        }
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func calculateDateRange() -> DateInterval? {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedDateRange {
        case .all:
            return nil
        case .lastMonth:
            let startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return DateInterval(start: startDate, end: now)
        case .last3Months:
            let startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return DateInterval(start: startDate, end: now)
        case .lastYear:
            let startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return DateInterval(start: startDate, end: now)
        case .custom:
            return DateInterval(start: customStartDate, end: customEndDate)
        }
    }
    
    private func updateLastExportDate() async {
        await MainActor.run {
            let context = PersistenceService.shared.viewContext
            let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

            do {
                if let appSettings = try context.fetch(request).first {
                    appSettings.lastExportDate = Date()
                    PersistenceService.shared.save()
                }
            } catch {
                print("Failed to update last export date: \(error)")
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct DataExportView_Previews: PreviewProvider {
    static var previews: some View {
        DataExportView()
            .environmentObject(PremiumManager.shared)
    }
}
