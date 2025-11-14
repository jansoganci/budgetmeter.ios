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
            .navigationTitle("Financial Health")
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
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {
                    viewModel.clearError()
                }
                Button("Retry", role: .none) {
                    Task {
                        await viewModel.refreshData()
                    }
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unexpected error occurred")
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Health Score Card
                healthScoreSection

                // Breakdown Components
                breakdownSection

                // Health Tips
                healthTipsSection
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }

    // MARK: - Health Score Section

    private var healthScoreSection: some View {
        VStack(spacing: 0) {
            HealthScoreCard(
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
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("HEALTH BREAKDOWN")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            // Breakdown components card
            VStack(spacing: 0) {
                if let breakdown = viewModel.breakdown {
                    // Expense Score
                    HealthBreakdownRow(
                        icon: "chart.pie.fill",
                        title: "Expense Management",
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
                        title: "Savings Score",
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
                        title: "Income Score",
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
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Health breakdown section")
    }

    // MARK: - Health Tips Section

    private var healthTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("PERSONALIZED TIPS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                if !viewModel.isPremium && viewModel.healthTips.count > 3 {
                    Button {
                        hapticFeedback.impactOccurred()
                        viewModel.showPremiumPaywall()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                            Text("Unlock All")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(Color(hex: "FFD700"))
                    }
                }
            }
            .padding(.horizontal, 4)

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
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading your health data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Unable to Load Data")
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
                Text("Try Again")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - No Breakdown View

    private var noBreakdownView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No Breakdown Available")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("Start tracking your budget to see detailed health breakdown")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }

    // MARK: - No Tips View

    private var noTipsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)

            Text("No Tips Yet")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("As you track your finances, we'll provide personalized tips to improve your financial health")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Locked Tips View

    private var lockedTipsView: some View {
        Button {
            hapticFeedback.impactOccurred()
            viewModel.showPremiumPaywall()
        } label: {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "FFD700"))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.healthTips.count - 3) More Premium Tips")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("Unlock advanced insights and recommendations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
            }
            .background(Color(hex: "FFD700").opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "FFD700").opacity(0.3), lineWidth: 1.5)
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
                .foregroundColor(.blue)
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
