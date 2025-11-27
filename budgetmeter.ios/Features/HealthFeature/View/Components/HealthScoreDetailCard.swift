//
//  HealthScoreDetailCard.swift
//  BudgetMeter
//
//  Phase 1D: Financial Health Details - Score Card Component
//  Created by BudgetMeter Team on 17.09.2025.
//

import SwiftUI

/// Large circular health score display card for Health Details view
struct HealthScoreDetailCard: View {

    // MARK: - Properties

    let score: Int
    let scoreText: String
    let color: Color
    let lastUpdated: String

    @State private var animatedScore: Double = 0
    @State private var showContent: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Financial Health Score")
                .font(.headline)
                .foregroundColor(.primary)
                .opacity(showContent ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.1), value: showContent)

            // Circular Progress Score
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 180, height: 180)

                // Progress circle
                Circle()
                    .trim(from: 0, to: animatedScore / 100)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animatedScore)

                // Score text
                VStack(spacing: 4) {
                    Text("\(Int(animatedScore))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(color)

                    Text(scoreText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .opacity(showContent ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.5), value: showContent)
            }

            // Description
            VStack(spacing: 8) {
                Text(descriptionText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.7), value: showContent)

                // Last updated
                Text("Updated \(lastUpdated)")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.8), value: showContent)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .onAppear {
            // Animate score on appear
            withAnimation {
                animatedScore = Double(score)
                showContent = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Financial health score is \(score) out of 100, rated as \(scoreText)")
        .accessibilityHint("Your overall financial health based on budget compliance, savings, spending consistency, and income stability")
    }

    // MARK: - Description Text

    private var descriptionText: String {
        switch score {
        case 90...100:
            return "Excellent work! Your financial health is outstanding. Keep up the great habits!"
        case 75...89:
            return "Great job! Your financial health is strong. A few tweaks can make it even better."
        case 60...74:
            return "Good progress! Your financial health is on the right track. Keep improving!"
        case 40...59:
            return "Fair start. Your financial health needs attention. Check the tips below for guidance."
        case 20...39:
            return "Your financial health needs improvement. Follow the recommendations to get back on track."
        default:
            return "Getting started. Set up your budget to see your financial health improve over time."
        }
    }
}

// MARK: - Preview

#Preview("Excellent Score") {
    HealthScoreDetailCard(
        score: 92,
        scoreText: "Excellent",
        color: .green,
        lastUpdated: "2 min ago"
    )
    .padding()
}

#Preview("Good Score") {
    HealthScoreDetailCard(
        score: 68,
        scoreText: "Good",
        color: .yellow,
        lastUpdated: "5 min ago"
    )
    .padding()
}

#Preview("Needs Improvement") {
    HealthScoreDetailCard(
        score: 35,
        scoreText: "Needs Improvement",
        color: .red,
        lastUpdated: "1 hour ago"
    )
    .padding()
}
