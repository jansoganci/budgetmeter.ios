//
//  OnboardingView.swift
//  BudgetMeter
//
//  Phase 11 — Skippable paging onboarding for new users (v2 glass fintech).
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                skipHeader

                TabView(selection: $viewModel.currentPage) {
                    ForEach(OnboardingPage.allCases) { page in
                        onboardingPage(page)
                            .tag(page.rawValue)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut(duration: 0.25), value: viewModel.currentPage)

                bottomAction
            }
            .padding(.horizontal, LayoutSpacing.screenPadding)
            .padding(.bottom, Spacing.xl)
        }
    }

    private var skipHeader: some View {
        HStack {
            Spacer()
            Button {
                viewModel.skip()
            } label: {
                Text(String(localized: "onboarding.skip", defaultValue: "Skip", table: "UI"))
                    .cardLabelStyle(color: .textSecondary)
                    .frame(minHeight: TouchTarget.minimum)
            }
            .buttonStyle(.plain)
            .accessibilityHint(String(localized: "onboarding.skip", defaultValue: "Skip", table: "UI"))
        }
        .padding(.top, Spacing.md)
    }

    private func onboardingPage(_ page: OnboardingPage) -> some View {
        VStack(spacing: Spacing.xl) {
            Spacer(minLength: Spacing.lg)

            VStack(spacing: Spacing.lg) {
                Image(systemName: page.icon)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Color.accentPrimary)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                VStack(spacing: Spacing.md) {
                    Text(page.title)
                        .sectionTitleStyle()
                        .multilineTextAlignment(.center)

                    Text(page.body)
                        .bodyStyle(color: .textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(LayoutSpacing.cardPadding)
            .frame(maxWidth: .infinity)
            .glassSurface()

            Spacer(minLength: Spacing.lg)
        }
    }

    @ViewBuilder
    private var bottomAction: some View {
        if viewModel.currentPage == OnboardingViewModel.totalPages - 1 {
            Button {
                viewModel.complete()
            } label: {
                Text(String(localized: "onboarding.get_started", defaultValue: "Get Started", table: "UI"))
                    .buttonTextStyle(color: .white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: TouchTarget.recommended)
                    .background(Color.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, Spacing.md)
        } else {
            Color.clear
                .frame(height: TouchTarget.recommended + Spacing.md)
        }
    }
}

private enum OnboardingPage: Int, CaseIterable, Identifiable {
    case pace
    case income
    case summary

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .pace: return "gauge.with.dots.needle.67percent"
        case .income: return "arrow.left.arrow.right.circle.fill"
        case .summary: return "chart.line.uptrend.xyaxis"
        }
    }

    var title: String {
        switch self {
        case .pace:
            return String(localized: "onboarding.page1.title", defaultValue: "Track your money pace", table: "UI")
        case .income:
            return String(localized: "onboarding.page2.title", defaultValue: "Add your income & expenses", table: "UI")
        case .summary:
            return String(localized: "onboarding.page3.title", defaultValue: "Stay on top of your finances", table: "UI")
        }
    }

    var body: String {
        switch self {
        case .pace:
            return String(localized: "onboarding.page1.body", defaultValue: "See how your income and expenses flow in real time — like a live meter for your finances.", table: "UI")
        case .income:
            return String(localized: "onboarding.page2.body", defaultValue: "Enter your recurring income and spending categories to build your personal money pace.", table: "UI")
        case .summary:
            return String(localized: "onboarding.page3.body", defaultValue: "Watch your daily budget, health score, and savings goals — all in one calm dashboard.", table: "UI")
        }
    }
}
