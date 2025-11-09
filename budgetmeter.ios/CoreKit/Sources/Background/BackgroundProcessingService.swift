import Foundation
import BackgroundTasks
import CoreData

final class BackgroundProcessingService {
    static let shared = BackgroundProcessingService()

    private let persistenceService: PersistenceService
    private let backgroundTaskIdentifier = "com.budgetmeter.recurring-transactions"

    // Services for insights and notifications
    private let historicalDataService: HistoricalDataService
    private let notificationService: NotificationService

    private init(
        persistenceService: PersistenceService = .shared,
        historicalDataService: HistoricalDataService = .shared,
        notificationService: NotificationService = .shared
    ) {
        self.persistenceService = persistenceService
        self.historicalDataService = historicalDataService
        self.notificationService = notificationService
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

        // Process all background tasks
        Task {
            await processRecurringTransactions()
            await processSnapshots()
            await checkNotifications()
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
    
    // MARK: - Snapshot Processing

    @MainActor
    private func processSnapshots() async {
        print("📊 BackgroundProcessingService: Processing snapshots...")

        // Save daily snapshot
        historicalDataService.saveDailySnapshot()

        // Check if it's the first day of the month
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: Date())

        if dayOfMonth == 1 {
            historicalDataService.saveMonthlySnapshot()
            print("📊 BackgroundProcessingService: Saved monthly snapshot")
        }

        // Clean up old snapshots (every 7 days)
        if dayOfMonth % 7 == 0 {
            historicalDataService.cleanupOldSnapshots()
            print("📊 BackgroundProcessingService: Cleaned up old snapshots")
        }
    }

    // MARK: - Notification Processing

    @MainActor
    private func checkNotifications() async {
        print("🔔 BackgroundProcessingService: Checking notifications...")

        // Check for milestones
        notificationService.checkMilestones()

        // Check for spending alerts (on Mondays)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())

        if weekday == 2 { // Monday
            notificationService.checkSpendingAlert()
        }

        print("🔔 BackgroundProcessingService: Notification check complete")
    }

    // MARK: - App Lifecycle Integration

    func applicationDidEnterBackground() {
        scheduleBackgroundProcessing()

        // Save snapshot when app goes to background
        historicalDataService.saveDailySnapshot()
    }

    func applicationWillEnterForeground() {
        // Process any pending transactions when app becomes active
        Task {
            await processRecurringTransactions()
            await processSnapshots()
        }

        // Re-schedule notifications
        notificationService.scheduleWeeklySummary()
        notificationService.scheduleDailyEncouragement()
    }
}
