//
//  HealthDetailsView.swift
//  BudgetMeter
//
//  Phase 1D: Financial Health Details - Main View
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Main Financial Health Details screen
struct HealthDetailsView: View {

    // MARK: - Properties

    @StateObject private var viewModel = HealthDetailsViewModel()
    @Environment(\.dismiss) private var dismiss

    // Haptic feedback
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && !viewModel.hasData {
                    // Initial loading state
                    loadingView
                } else if let errorMessage = viewModel.errorMessage, !viewModel.hasData {
                    // Error state
                    errorView(message: errorMessage)
                } else {
                    // Main content
                    mainContent
                }
            }
            .navigationTitle("health.navigation.title".localized(defaultValue: "Financial Health"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    shareButton
                }
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                PremiumPaywallView(
                    feature: nil,
                    onDismiss: {
                        viewModel.dismissPaywall()
                    },
                    onPurchase: {
                        Task {
                            viewModel.dismissPaywall()
                            await viewModel.refreshData()
                        }
                    },
                    onRestore: {
                        Task {
                            viewModel.dismissPaywall()
                            await viewModel.refreshData()
                        }
                    }
                )
            }
            .alert("alert.error.title".localized(defaultValue: "Error"), isPresented: $viewModel.showErrorAlert) {
                Button("alert.ok".localized(defaultValue: "OK"), role: .cancel) {
                    viewModel.clearError()
                }
                Button("health.error.try_again".localized(defaultValue: "Retry"), role: .none) {
                    Task {
                        await viewModel.refreshData()
                    }
                }
            } message: {
                Text(viewModel.errorMessage ?? "health.error.unexpected".localized(defaultValue: "An unexpected error occurred"))
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Health Score Card
                healthScoreSection

                // Breakdown Components
                breakdownSection

                // Health Tips
                healthTipsSection
            }
            .padding(Spacing.lg)
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }

    // MARK: - Health Score Section

    private var healthScoreSection: some View {
        VStack(spacing: 0) {
            HealthScoreDetailCard(
                score: viewModel.healthScore,
                scoreText: viewModel.healthText,
                color: viewModel.healthScoreColor,
                lastUpdated: viewModel.lastUpdatedText
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Health score card")
    }

    // MARK: - Breakdown Section

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Section header
            Text("health.breakdown.title".localized(defaultValue: "HEALTH BREAKDOWN"))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, Spacing.xs)

            // Breakdown components card
            VStack(spacing: 0) {
                if let breakdown = viewModel.breakdown {
                    // Expense Score
                    HealthBreakdownRow(
                        icon: "chart.pie.fill",
                        title: "health.breakdown.expense_management".localized(defaultValue: "Expense Management"),
                        score: breakdown.expenseScore,
                        description: breakdown.expenseReason,
                        isExpanded: viewModel.isExpanded("expense"),
                        onTap: {
                            hapticFeedback.impactOccurred()
                            viewModel.toggleBreakdown("expense")
                        }
                    )

                    Divider()
                        .padding(.leading, 48)

                    // Savings Score
                    HealthBreakdownRow(
                        icon: "banknote.fill",
                        title: "health.breakdown.savings_score".localized(defaultValue: "Savings Score"),
                        score: breakdown.savingsScore,
                        description: breakdown.savingsReason,
                        isExpanded: viewModel.isExpanded("savings"),
                        onTap: {
                            hapticFeedback.impactOccurred()
                            viewModel.toggleBreakdown("savings")
                        }
                    )

                    Divider()
                        .padding(.leading, 48)

                    // Income Score
                    HealthBreakdownRow(
                        icon: "dollarsign.circle.fill",
                        title: "health.breakdown.income_score".localized(defaultValue: "Income Score"),
                        score: breakdown.incomeScore,
                        description: breakdown.incomeReason,
                        isExpanded: viewModel.isExpanded("income"),
                        onTap: {
                            hapticFeedback.impactOccurred()
                            viewModel.toggleBreakdown("income")
                        }
                    )
                } else {
                    // No breakdown data
                    noBreakdownView
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(CornerRadius.card)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Health breakdown section")
    }

    // MARK: - Health Tips Section

    private var healthTipsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Section header
            HStack {
                Text("health.tips.title".localized(defaultValue: "PERSONALIZED TIPS"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                if !viewModel.isPremium && viewModel.healthTips.count > 3 {
                    Button {
                        hapticFeedback.impactOccurred()
                        viewModel.showPremiumPaywall()
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                            Text("health.tips.unlock_all".localized(defaultValue: "Unlock All"))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.brandProgress)
                    }
                }
            }
            .padding(.horizontal, Spacing.xs)

            // Tips list
            if viewModel.healthTips.isEmpty {
                noTipsView
            } else {
                ForEach(Array(viewModel.availableTips.enumerated()), id: \.element.id) { index, tip in
                    HealthTipCard(
                        tip: tip,
                        isPremium: viewModel.isPremium
                    )
                    .onTapGesture {
                        if !viewModel.isPremium && index >= 3 {
                            hapticFeedback.impactOccurred()
                            viewModel.showPremiumPaywall()
                        }
                    }
                }

                // Show premium locked tips count
                if !viewModel.isPremium && viewModel.healthTips.count > 3 {
                    lockedTipsView
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Personalized tips section")
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)

            Text("health.loading.message".localized(defaultValue: "Loading your health data..."))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("health.error.title".localized(defaultValue: "Unable to Load Data"))
                .font(.headline)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    await viewModel.refreshData()
                }
            } label: {
                Text("health.error.try_again".localized(defaultValue: "Try Again"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.brandProgress)
                    .cornerRadius(CornerRadius.button)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - No Breakdown View

    private var noBreakdownView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("health.empty.breakdown.title".localized(defaultValue: "No Breakdown Available"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("health.empty.breakdown.message".localized(defaultValue: "Start tracking your budget to see detailed health breakdown"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }

    // MARK: - No Tips View

    private var noTipsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)

            Text("health.empty.tips.title".localized(defaultValue: "No Tips Yet"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("health.empty.tips.message".localized(defaultValue: "As you track your finances, we'll provide personalized tips to improve your financial health"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.card)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Locked Tips View

    private var lockedTipsView: some View {
        Button {
            hapticFeedback.impactOccurred()
            viewModel.showPremiumPaywall()
        } label: {
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.brandProgress)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(String(format: "health.locked.tips.count".localized(defaultValue: "%lld More Premium Tips"), viewModel.healthTips.count - 3))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("health.locked.tips.description".localized(defaultValue: "Unlock advanced insights and recommendations"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.lg)
            }
            .background(Color.brandProgress.opacity(0.1))
            .cornerRadius(CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.brandProgress.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Unlock \(viewModel.healthTips.count - 3) more premium tips")
        .accessibilityHint("Double tap to view premium upgrade options")
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            hapticFeedback.impactOccurred()
            shareHealthReport()
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.body)
                .foregroundColor(.brandProgress)
        }
        .disabled(viewModel.isLoading || !viewModel.hasData)
        .accessibilityLabel("Share health report")
        .accessibilityHint("Share your financial health score and breakdown")
    }

    // MARK: - Share Action

    private func shareHealthReport() {
        let shareText = """
        My BudgetMeter Financial Health Score: \(viewModel.healthScore)/100 (\(viewModel.healthText))

        📊 Health Breakdown:
        \(viewModel.breakdown.map { """
        • Income Score: \($0.incomeScore)/30
        • Expense Score: \($0.expenseScore)/30
        • Savings Score: \($0.savingsScore)/40
        """ } ?? "No breakdown available")

        Stay on top of your finances with BudgetMeter! 💚
        """

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        // Present from current window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            activityVC.popoverPresentationController?.permittedArrowDirections = []
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Preview

#Preview("With Data") {
    HealthDetailsView()
}

#Preview("Loading") {
    HealthDetailsView()
}
