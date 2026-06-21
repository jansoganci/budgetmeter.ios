import Foundation
import CoreData
import Combine

enum RecurringFrequency: String, CaseIterable, Identifiable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return String(localized: "recurring.frequency.daily", defaultValue: "Daily", table: "UI")
        case .weekly: return String(localized: "recurring.frequency.weekly", defaultValue: "Weekly", table: "UI")
        case .monthly: return String(localized: "recurring.frequency.monthly", defaultValue: "Monthly", table: "UI")
        case .quarterly: return String(localized: "recurring.frequency.quarterly", defaultValue: "Quarterly", table: "UI")
        case .yearly: return String(localized: "recurring.frequency.yearly", defaultValue: "Yearly", table: "UI")
        }
    }
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .quarterly: return .month
        case .yearly: return .year
        }
    }
    
    var interval: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 1
        case .monthly: return 1
        case .quarterly: return 3
        case .yearly: return 1
        }
    }
}

struct LocalizedError: Identifiable {
    let id = UUID()
    let message: String
}

@MainActor
final class RecurringTransactionsViewModel: ObservableObject {
    @Published var recurringTransactions: [RecurringTransaction] = []
    @Published var showAddTransactionSheet: Bool = false
    @Published var showEditTransactionSheet: Bool = false
    @Published var selectedTransactionForEdit: RecurringTransaction?
    @Published var errorMessage: LocalizedError?
    @Published var isLoading: Bool = false
    
    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()
    
    init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        setupSubscriptions()
        setupLanguageObserver()
        fetchRecurringTransactions()
    }
    
    private func setupSubscriptions() {
        // Observe Core Data changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: persistenceService.viewContext)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchRecurringTransactions()
            }
            .store(in: &cancellables)
    }

    private func setupLanguageObserver() {
        // Listen for language changes
        NotificationCenter.default.publisher(for: .languageDidChange)
            .sink { [weak self] _ in
                // Trigger UI refresh to re-evaluate localized strings
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchRecurringTransactions() {
        let context = persistenceService.viewContext
        let request: NSFetchRequest<RecurringTransaction> = RecurringTransaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RecurringTransaction.nextDueDate, ascending: true)]
        
        do {
            recurringTransactions = try context.fetch(request)
        } catch {
            errorMessage = LocalizedError(message: String(
                format: String(localized: "recurring.error.fetch_failed", defaultValue: "Failed to fetch recurring transactions: %@", table: "UI"),
                error.localizedDescription
            ))
            print("Failed to fetch recurring transactions: \(error)")
        }
    }
    
    func addRecurringTransaction(
        title: String,
        amount: Double,
        categoryName: String,
        categoryType: String,
        frequency: RecurringFrequency,
        startDate: Date,
        endDate: Date?,
        notes: String?
    ) {
        let context = persistenceService.viewContext
        let newTransaction = RecurringTransaction(context: context)
        
        newTransaction.id = UUID()
        newTransaction.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        newTransaction.amount = amount
        newTransaction.categoryName = categoryName
        newTransaction.categoryType = categoryType
        newTransaction.frequency = frequency.rawValue
        newTransaction.startDate = startDate
        newTransaction.endDate = endDate
        newTransaction.nextDueDate = calculateNextDueDate(from: startDate, frequency: frequency)
        newTransaction.isActive = true
        newTransaction.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        newTransaction.createdAt = Date()
        newTransaction.lastProcessedDate = nil
        
        persistenceService.save()
        fetchRecurringTransactions()
    }
    
    func updateRecurringTransaction(
        _ transaction: RecurringTransaction,
        title: String,
        amount: Double,
        categoryName: String,
        categoryType: String,
        frequency: RecurringFrequency,
        startDate: Date,
        endDate: Date?,
        notes: String?
    ) {
        let context = persistenceService.viewContext
        
        transaction.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.amount = amount
        transaction.categoryName = categoryName
        transaction.categoryType = categoryType
        transaction.frequency = frequency.rawValue
        transaction.startDate = startDate
        transaction.endDate = endDate
        transaction.nextDueDate = calculateNextDueDate(from: startDate, frequency: frequency)
        transaction.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        persistenceService.save()
        fetchRecurringTransactions()
    }
    
    func deleteRecurringTransaction(_ transaction: RecurringTransaction) {
        let context = persistenceService.viewContext
        context.delete(transaction)
        persistenceService.save()
        fetchRecurringTransactions()
    }
    
    func toggleTransactionActive(_ transaction: RecurringTransaction) {
        let context = persistenceService.viewContext
        transaction.isActive.toggle()
        persistenceService.save()
        fetchRecurringTransactions()
    }
    
    func editTransaction(_ transaction: RecurringTransaction) {
        selectedTransactionForEdit = transaction
        showEditTransactionSheet = true
    }
    
    func processDueTransactions() async {
        guard PremiumManager.shared.hasAccess(to: BudgetMeterCapability.recurringAutomation) else {
            print("RecurringTransactionsViewModel: Recurring automation skipped; premium required")
            return
        }

        isLoading = true
        defer { isLoading = false }
        
        let context = persistenceService.viewContext
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for transaction in recurringTransactions {
            guard transaction.isActive,
                  let nextDueDate = transaction.nextDueDate,
                  calendar.isDate(nextDueDate, inSameDayAs: today) || nextDueDate < today else {
                continue
            }
            
            // Check if transaction has an end date and if it's passed
            if let endDate = transaction.endDate, endDate < today {
                transaction.isActive = false
                continue
            }
            
            // Create the actual transaction
            await createTransactionFromRecurring(transaction)
            
            // Update next due date
            transaction.nextDueDate = calculateNextDueDate(from: nextDueDate, frequency: RecurringFrequency(rawValue: transaction.frequency ?? "monthly") ?? .monthly)
            transaction.lastProcessedDate = Date()
        }
        
        persistenceService.save()
        fetchRecurringTransactions()
    }
    
    private func createTransactionFromRecurring(_ recurringTransaction: RecurringTransaction) async {
        let context = persistenceService.viewContext

        let newCategory = FinancialCategory(context: context)
        newCategory.id = UUID()
        newCategory.uniqueID = UUID().uuidString
        newCategory.type = recurringTransaction.categoryType
        newCategory.amount = recurringTransaction.amount
        newCategory.customName = recurringTransaction.title
        newCategory.isCustom = true

        FinancialCategoryWriteSupport.applyMetadata(
            to: newCategory,
            entryKind: .oneTime,
            recurringFrequency: "once",
            occurrenceDate: recurringTransaction.nextDueDate ?? Date(),
            sourceType: "recurringAutomation",
            sourceID: recurringTransaction.id?.uuidString
        )

        persistenceService.save()
    }
    
    private func calculateNextDueDate(from date: Date, frequency: RecurringFrequency) -> Date {
        let calendar = Calendar.current
        
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: frequency.interval, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: frequency.interval, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: frequency.interval, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: frequency.interval, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: frequency.interval, to: date) ?? date
        }
    }
    
    func getUpcomingTransactions(limit: Int = 5) -> [RecurringTransaction] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: today) ?? today
        
        return recurringTransactions
            .filter { transaction in
                guard transaction.isActive,
                      let nextDueDate = transaction.nextDueDate else { return false }
                return nextDueDate >= today && nextDueDate <= nextWeek
            }
            .sorted { ($0.nextDueDate ?? Date.distantFuture) < ($1.nextDueDate ?? Date.distantFuture) }
            .prefix(limit)
            .map { $0 }
    }
    
    func getOverdueTransactions() -> [RecurringTransaction] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return recurringTransactions
            .filter { transaction in
                guard transaction.isActive,
                      let nextDueDate = transaction.nextDueDate else { return false }
                return nextDueDate < today
            }
            .sorted { ($0.nextDueDate ?? Date.distantPast) < ($1.nextDueDate ?? Date.distantPast) }
    }
}
