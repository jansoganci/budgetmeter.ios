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
            case .all: return "export.date_range.all".localized(defaultValue: "All Time")
            case .lastMonth: return "export.date_range.last_month".localized(defaultValue: "Last Month")
            case .last3Months: return "export.date_range.last_3_months".localized(defaultValue: "Last 3 Months")
            case .lastYear: return "export.date_range.last_year".localized(defaultValue: "Last Year")
            case .custom: return "export.date_range.custom".localized(defaultValue: "Custom Range")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("export.format.title".localized(defaultValue: "Export Format")) {
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
                
                Section("export.date_range.title".localized(defaultValue: "Date Range")) {
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
                        DatePicker("export.start_date".localized(defaultValue: "Start Date"), selection: $customStartDate, displayedComponents: .date)
                        DatePicker("export.end_date".localized(defaultValue: "End Date"), selection: $customEndDate, displayedComponents: .date)
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
                            
                            Text(isExporting ? "export.exporting".localized(defaultValue: "Exporting...") : "export.export_button".localized(defaultValue: "Export Data"))
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
                
                Section("export.info.title".localized(defaultValue: "Export Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("export.info.description".localized(defaultValue: "Your data will be exported in the selected format. The export includes:"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Financial categories and amounts")
                            Text("• Recurring transactions")
                            Text("• Custom categories")
                            Text("• App settings and preferences")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("export.nav_title".localized(defaultValue: "Export Data"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("toolbar.close".localized(defaultValue: "Close")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let fileURL = exportedFileURL {
                    ShareSheet(activityItems: [fileURL])
                }
            }
            .alert("error.title".localized(defaultValue: "Error"), isPresented: $showingError) {
                Button("alert.ok".localized(defaultValue: "OK")) { }
            } message: {
                Text(errorMessage ?? "export.error.unknown".localized(defaultValue: "An unknown error occurred"))
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
        case .pdf: return "export.format.pdf.description".localized(defaultValue: "Formatted report with charts and summaries")
        case .csv: return "export.format.csv.description".localized(defaultValue: "Spreadsheet-compatible data format")
        case .json: return "export.format.json.description".localized(defaultValue: "Machine-readable data format")
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
            errorMessage = "export.error.failed".localized(defaultValue: "Export failed: \(error.localizedDescription)")
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
