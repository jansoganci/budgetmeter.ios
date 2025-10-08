import SwiftUI

struct RecurringTransactionsView: View {
    @StateObject private var viewModel = RecurringTransactionsViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if !viewModel.getOverdueTransactions().isEmpty {
                    Section("recurring.overdue.title".localized(defaultValue: "Overdue")) {
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
                    Section("recurring.upcoming.title".localized(defaultValue: "Upcoming")) {
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
                
                Section("recurring.all.title".localized(defaultValue: "All Recurring Transactions")) {
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
            .navigationTitle("recurring.nav_title".localized(defaultValue: "Recurring Transactions"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("toolbar.close".localized(defaultValue: "Close")) {
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
                    title: Text("error.title".localized(defaultValue: "Error")),
                    message: Text(errorMessage.message),
                    dismissButton: .default(Text("alert.ok".localized(defaultValue: "OK")))
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
                Text(transaction.title ?? "Unknown Transaction")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(transaction.categoryName ?? "Unknown Category")
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
                
                Text(RecurringFrequency(rawValue: transaction.frequency ?? "monthly")?.displayName ?? "Monthly")
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
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
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
                Section("edit_recurring.details.title".localized(defaultValue: "Transaction Details")) {
                    TextField("edit_recurring.title_placeholder".localized(defaultValue: "Transaction Title"), text: $title)
                        .autocapitalization(.words)
                    
                    HStack {
                        Text("edit_recurring.amount_label".localized(defaultValue: "Amount"))
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("edit_recurring.category.title".localized(defaultValue: "Category")) {
                    Picker("edit_recurring.category_type_label".localized(defaultValue: "Type"), selection: $categoryType) {
                        Text("edit_recurring.type_income".localized(defaultValue: "Income")).tag("income")
                        Text("edit_recurring.type_expense".localized(defaultValue: "Expense")).tag("expense")
                    }
                    .pickerStyle(.segmented)
                    
                    Button {
                        showingCategoryPicker = true
                    } label: {
                        HStack {
                            Text("edit_recurring.category_name_label".localized(defaultValue: "Category"))
                            Spacer()
                            Text(categoryName.isEmpty ? "edit_recurring.select_category".localized(defaultValue: "Select Category") : categoryName)
                                .foregroundColor(categoryName.isEmpty ? .secondary : .primary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                Section("edit_recurring.schedule.title".localized(defaultValue: "Schedule")) {
                    Button {
                        showingFrequencyPicker = true
                    } label: {
                        HStack {
                            Text("edit_recurring.frequency_label".localized(defaultValue: "Frequency"))
                            Spacer()
                            Text(frequency.displayName)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    DatePicker("edit_recurring.start_date_label".localized(defaultValue: "Start Date"), selection: $startDate, displayedComponents: .date)
                    
                    Toggle("edit_recurring.has_end_date".localized(defaultValue: "Has End Date"), isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("edit_recurring.end_date_label".localized(defaultValue: "End Date"), selection: $endDate, displayedComponents: .date)
                    }
                }
                
                Section("edit_recurring.notes.title".localized(defaultValue: "Notes")) {
                    TextField("edit_recurring.notes_placeholder".localized(defaultValue: "Optional notes..."), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "edit_recurring.edit_title".localized(defaultValue: "Edit Recurring Transaction") : "edit_recurring.add_title".localized(defaultValue: "Add Recurring Transaction"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("toolbar.cancel".localized(defaultValue: "Cancel")) {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("toolbar.save".localized(defaultValue: "Save")) {
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
            .navigationTitle("category_picker.nav_title".localized(defaultValue: "Select Category"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("toolbar.cancel".localized(defaultValue: "Cancel")) {
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
            .navigationTitle("frequency_picker.nav_title".localized(defaultValue: "Select Frequency"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("toolbar.cancel".localized(defaultValue: "Cancel")) {
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
