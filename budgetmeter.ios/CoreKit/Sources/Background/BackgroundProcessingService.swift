import Foundation
import BackgroundTasks
import CoreData

final class BackgroundProcessingService {
    static let shared = BackgroundProcessingService()
    
    private let persistenceService: PersistenceService
    private let backgroundTaskIdentifier = "com.budgetmeter.recurring-transactions"
    
    private init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
        registerBackgroundTask()
    }
    
    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundTask(task as! BGAppRefreshTask)
        }
    }
    
    func scheduleBackgroundProcessing() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task scheduled successfully")
        } catch {
            print("Failed to schedule background task: \(error)")
        }
    }
    
    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        // Schedule the next background task
        scheduleBackgroundProcessing()
        
        // Set expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Process recurring transactions
        Task {
            await processRecurringTransactions()
            task.setTaskCompleted(success: true)
        }
    }
    
    @MainActor
    private func processRecurringTransactions() async {
        let context = persistenceService.viewContext
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let request: NSFetchRequest<RecurringTransaction> = RecurringTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        
        do {
            let recurringTransactions = try context.fetch(request)
            var hasChanges = false
            
            for transaction in recurringTransactions {
                guard let nextDueDate = transaction.nextDueDate else { continue }
                
                // Check if transaction is due today or overdue
                if calendar.isDate(nextDueDate, inSameDayAs: today) || nextDueDate < today {
                    // Check if transaction has an end date and if it's passed
                    if let endDate = transaction.endDate, endDate < today {
                        transaction.isActive = false
                        hasChanges = true
                        continue
                    }
                    
                    // Create the actual transaction
                    await createTransactionFromRecurring(transaction, context: context)
                    hasChanges = true
                    
                    // Update next due date
                    if let frequency = RecurringFrequency(rawValue: transaction.frequency ?? "monthly") {
                        transaction.nextDueDate = calculateNextDueDate(from: nextDueDate, frequency: frequency)
                        transaction.lastProcessedDate = Date()
                    }
                }
            }
            
            if hasChanges {
                persistenceService.save()
                print("Background processing completed: \(recurringTransactions.count) transactions processed")
            }
            
        } catch {
            print("Failed to process recurring transactions in background: \(error)")
        }
    }
    
    private func createTransactionFromRecurring(_ recurringTransaction: RecurringTransaction, context: NSManagedObjectContext) async {
        // Create a new FinancialCategory entry
        let newCategory = FinancialCategory(context: context)
        newCategory.id = UUID()
        newCategory.uniqueID = UUID().uuidString
        newCategory.type = recurringTransaction.categoryType
        newCategory.amount = recurringTransaction.amount
        newCategory.frequency = "recurring"
        
        print("Created transaction from recurring: \(recurringTransaction.title ?? "Unknown") - \(recurringTransaction.amount)")
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
    
    // MARK: - App Lifecycle Integration
    
    func applicationDidEnterBackground() {
        scheduleBackgroundProcessing()
    }
    
    func applicationWillEnterForeground() {
        // Process any pending transactions when app becomes active
        Task {
            await processRecurringTransactions()
        }
    }
}
