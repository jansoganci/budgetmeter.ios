import SwiftUI

struct RecurringTransactionsView: View {
    @StateObject private var viewModel = RecurringTransactionsViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if !viewModel.getOverdueTransactions().isEmpty {
                    Section(String(localized: "recurring.overdue.title", defaultValue: "Overdue", table: "UI")) {
                        ForEach(viewModel.getOverdueTransactions(), id: \.id) { transaction in
                            RecurringTransactionRow(transaction: transaction) {
                                viewModel.editTransaction(transaction)
                            }
                        }
                        .onDelete { indexSet in
                            let overdueTransactions = viewModel.getOverdueTransactions()
                            for index in indexSet {
                                viewModel.deleteRecurringTransaction(overdueTransactions[index])
                            }
                        }
                    }
                }
                
                if !viewModel.getUpcomingTransactions().isEmpty {
                    Section(String(localized: "recurring.upcoming.title", defaultValue: "Upcoming", table: "UI")) {
                        ForEach(viewModel.getUpcomingTransactions(), id: \.id) { transaction in
                            RecurringTransactionRow(transaction: transaction) {
                                viewModel.editTransaction(transaction)
                            }
                        }
                        .onDelete { indexSet in
                            let upcomingTransactions = viewModel.getUpcomingTransactions()
                            for index in indexSet {
                                viewModel.deleteRecurringTransaction(upcomingTransactions[index])
                            }
                        }
                    }
                }
                
                Section(String(localized: "recurring.all.title", defaultValue: "All Recurring Transactions", table: "UI")) {
                    ForEach(viewModel.recurringTransactions, id: \.id) { transaction in
                        RecurringTransactionRow(transaction: transaction) {
                            viewModel.editTransaction(transaction)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteRecurringTransaction(viewModel.recurringTransactions[index])
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "recurring.nav_title", defaultValue: "Recurring Transactions", table: "UI"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "toolbar.close", defaultValue: "Close", table: "UI")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showAddTransactionSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: "4A90E2"))
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddTransactionSheet) {
                EditRecurringTransactionView(
                    viewModel: viewModel,
                    isPresented: $viewModel.showAddTransactionSheet,
                    transactionToEdit: nil
                )
            }
            .sheet(isPresented: $viewModel.showEditTransactionSheet) {
                EditRecurringTransactionView(
                    viewModel: viewModel,
                    isPresented: $viewModel.showEditTransactionSheet,
                    transactionToEdit: viewModel.selectedTransactionForEdit
                )
            }
            .alert(item: $viewModel.errorMessage) { errorMessage in
                Alert(
                    title: Text(String(localized: "error.title", defaultValue: "Error", table: "UI")),
                    message: Text(errorMessage.message),
                    dismissButton: .default(Text(String(localized: "alert.ok", defaultValue: "OK", table: "UI")))
                )
            }
            .refreshable {
                await viewModel.processDueTransactions()
            }
        }
    }
}

struct RecurringTransactionRow: View {
    let transaction: RecurringTransaction
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title ?? String(localized: "recurring.unknown_transaction", defaultValue: "Unknown Transaction", table: "UI"))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(transaction.categoryName ?? String(localized: "recurring.unknown_category", defaultValue: "Unknown Category", table: "UI"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let nextDueDate = transaction.nextDueDate {
                        Text(formatDate(nextDueDate))
                            .font(.caption)
                            .foregroundColor(isOverdue(nextDueDate) ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyHelper.formatAmount(transaction.amount))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.categoryType == "income" ? .green : .red)
                
                Text(RecurringFrequency(rawValue: transaction.frequency ?? "monthly")?.displayName ?? String(localized: "recurring.frequency.monthly", defaultValue: "Monthly", table: "UI"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(Color(hex: "4A90E2"))
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        DateFormattingHelper.shared.formatShort(date)
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return date < today
    }
}

struct EditRecurringTransactionView: View {
    @ObservedObject var viewModel: RecurringTransactionsViewModel
    @Binding var isPresented: Bool
    var transactionToEdit: RecurringTransaction?
    
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var categoryName: String = ""
    @State private var categoryType: String = "expense"
    @State private var frequency: RecurringFrequency = .monthly
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var hasEndDate: Bool = false
    @State private var notes: String = ""
    
    @State private var showingCategoryPicker = false
    @State private var showingFrequencyPicker = false
    
    var isEditing: Bool { transactionToEdit != nil }
    
    let categories = [
        ("Salary", "income"), ("Freelance", "income"), ("Investment", "income"),
        ("Rent", "expense"), ("Utilities", "expense"), ("Groceries", "expense"),
        ("Transportation", "expense"), ("Entertainment", "expense"), ("Healthcare", "expense")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(String(localized: "edit_recurring.details.title", defaultValue: "Transaction Details", table: "UI")) {
                    TextField(String(localized: "edit_recurring.title_placeholder", defaultValue: "Transaction Title", table: "UI"), text: $title)
                        .autocapitalization(.words)
                    
                    HStack {
                        Text(String(localized: "edit_recurring.amount_label", defaultValue: "Amount", table: "UI"))
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(String(localized: "edit_recurring.category.title", defaultValue: "Category", table: "UI")) {
                    Picker(String(localized: "edit_recurring.category_type_label", defaultValue: "Type", table: "UI"), selection: $categoryType) {
                        Text(String(localized: "edit_recurring.type_income", defaultValue: "Income", table: "UI")).tag("income")
                        Text(String(localized: "edit_recurring.type_expense", defaultValue: "Expense", table: "UI")).tag("expense")
                    }
                    .pickerStyle(.segmented)
                    
                    Button {
                        showingCategoryPicker = true
                    } label: {
                        HStack {
                            Text(String(localized: "edit_recurring.category_name_label", defaultValue: "Category", table: "UI"))
                            Spacer()
                            Text(categoryName.isEmpty
                                 ? String(localized: "edit_recurring.select_category", defaultValue: "Select Category", table: "UI")
                                 : categoryName)
                                .foregroundColor(categoryName.isEmpty ? .secondary : .primary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                Section(String(localized: "edit_recurring.schedule.title", defaultValue: "Schedule", table: "UI")) {
                    Button {
                        showingFrequencyPicker = true
                    } label: {
                        HStack {
                            Text(String(localized: "edit_recurring.frequency_label", defaultValue: "Frequency", table: "UI"))
                            Spacer()
                            Text(frequency.displayName)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    DatePicker(String(localized: "edit_recurring.start_date_label", defaultValue: "Start Date", table: "UI"), selection: $startDate, displayedComponents: .date)
                    
                    Toggle(String(localized: "edit_recurring.has_end_date", defaultValue: "Has End Date", table: "UI"), isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker(String(localized: "edit_recurring.end_date_label", defaultValue: "End Date", table: "UI"), selection: $endDate, displayedComponents: .date)
                    }
                }
                
                Section(String(localized: "edit_recurring.notes.title", defaultValue: "Notes", table: "UI")) {
                    TextField(String(localized: "edit_recurring.notes_placeholder", defaultValue: "Optional notes...", table: "UI"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing
                             ? String(localized: "edit_recurring.edit_title", defaultValue: "Edit Recurring Transaction", table: "UI")
                             : String(localized: "edit_recurring.add_title", defaultValue: "Add Recurring Transaction", table: "UI"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "toolbar.cancel", defaultValue: "Cancel", table: "UI")) {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "toolbar.save", defaultValue: "Save", table: "UI")) {
                        saveTransaction()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                setupInitialValues()
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(
                    categories: categories.filter { $0.1 == categoryType },
                    selectedCategory: $categoryName
                )
            }
            .sheet(isPresented: $showingFrequencyPicker) {
                FrequencyPickerView(selectedFrequency: $frequency)
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !amount.isEmpty &&
        !categoryName.isEmpty &&
        Double(amount) != nil
    }
    
    private func setupInitialValues() {
        if let transaction = transactionToEdit {
            title = transaction.title ?? ""
            amount = String(transaction.amount)
            categoryName = transaction.categoryName ?? ""
            categoryType = transaction.categoryType ?? "expense"
            frequency = RecurringFrequency(rawValue: transaction.frequency ?? "monthly") ?? .monthly
            startDate = transaction.startDate ?? Date()
            endDate = transaction.endDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            hasEndDate = transaction.endDate != nil
            notes = transaction.notes ?? ""
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        if isEditing {
            viewModel.updateRecurringTransaction(
                transactionToEdit!,
                title: title,
                amount: amountValue,
                categoryName: categoryName,
                categoryType: categoryType,
                frequency: frequency,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                notes: notes.isEmpty ? nil : notes
            )
        } else {
            viewModel.addRecurringTransaction(
                title: title,
                amount: amountValue,
                categoryName: categoryName,
                categoryType: categoryType,
                frequency: frequency,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                notes: notes.isEmpty ? nil : notes
            )
        }
        
        isPresented = false
    }
}

struct CategoryPickerView: View {
    let categories: [(String, String)]
    @Binding var selectedCategory: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories, id: \.0) { category in
                    Button {
                        selectedCategory = category.0
                        dismiss()
                    } label: {
                        HStack {
                            Text(category.0)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCategory == category.0 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "4A90E2"))
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "category_picker.nav_title", defaultValue: "Select Category", table: "UI"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "toolbar.cancel", defaultValue: "Cancel", table: "UI")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FrequencyPickerView: View {
    @Binding var selectedFrequency: RecurringFrequency
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(RecurringFrequency.allCases) { frequency in
                    Button {
                        selectedFrequency = frequency
                        dismiss()
                    } label: {
                        HStack {
                            Text(frequency.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedFrequency == frequency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "4A90E2"))
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "frequency_picker.nav_title", defaultValue: "Select Frequency", table: "UI"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "toolbar.cancel", defaultValue: "Cancel", table: "UI")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RecurringTransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        RecurringTransactionsView()
            .environmentObject(PremiumManager.shared)
    }
}
