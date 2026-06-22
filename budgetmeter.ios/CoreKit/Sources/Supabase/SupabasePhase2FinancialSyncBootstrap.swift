//
//  SupabasePhase2FinancialSyncBootstrap.swift
//  BudgetMeter
//
//  Phase 2C financial entity sync bootstrap orchestrator.
//

import Foundation

@MainActor
final class SupabasePhase2FinancialSyncBootstrap {
    static let shared = SupabasePhase2FinancialSyncBootstrap()

    private let subscriptionSyncService: FinancialEntitySyncScheduling
    private let billSyncService: FinancialEntitySyncScheduling
    private let billPaymentSyncService: FinancialEntitySyncScheduling
    private let recurringTransactionSyncService: FinancialEntitySyncScheduling

    init(
        subscriptionSyncService: FinancialEntitySyncScheduling = SupabaseSubscriptionSyncService.shared,
        billSyncService: FinancialEntitySyncScheduling = SupabaseBillSyncService.shared,
        billPaymentSyncService: FinancialEntitySyncScheduling = SupabaseBillPaymentSyncService.shared,
        recurringTransactionSyncService: FinancialEntitySyncScheduling = SupabaseRecurringTransactionSyncService.shared
    ) {
        self.subscriptionSyncService = subscriptionSyncService
        self.billSyncService = billSyncService
        self.billPaymentSyncService = billPaymentSyncService
        self.recurringTransactionSyncService = recurringTransactionSyncService
    }

    func bootstrapSignedInAccount() async {
        await runBootstrapStep("subscriptions") {
            await self.subscriptionSyncService.bootstrapSignedInAccount()
        }

        await runBootstrapStep("bills") {
            await self.billSyncService.bootstrapSignedInAccount()
        }

        await runBootstrapStep("bill_payments") {
            await self.billPaymentSyncService.bootstrapSignedInAccount()
        }

        await runBootstrapStep("recurring_transactions") {
            await self.recurringTransactionSyncService.bootstrapSignedInAccount()
        }
    }

    private func runBootstrapStep(_ name: String, step: () async -> Void) async {
        do {
            await step()
        } catch {
            print("☁️ SupabasePhase2FinancialSyncBootstrap: \(name) bootstrap failed (\(error))")
        }
    }
}
