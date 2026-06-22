//
//  OnboardingViewModel.swift
//  BudgetMeter
//
//  Phase 11 — Lightweight onboarding state for new users.
//

import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @Published var currentPage = 0
    private let supabaseAccountDataService = SupabaseAccountDataService.shared

    static let totalPages = 3

    func skip() {
        hasCompletedOnboarding = true
        Task {
            await supabaseAccountDataService.pushOnboardingCompleted(true)
        }
    }

    func complete() {
        hasCompletedOnboarding = true
        Task {
            await supabaseAccountDataService.pushOnboardingCompleted(true)
        }
    }

    func advancePage() {
        guard currentPage < Self.totalPages - 1 else { return }
        currentPage += 1
    }
}
