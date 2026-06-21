//
//  AppBackground.swift
//  BudgetMeter
//
//  Handoff wrapper — stable v2 app canvas (background.main).
//

import SwiftUI

/// Root canvas for full-screen views. Wraps `Color.appBackground` with safe-area extension.
struct AppBackground: View {

    private let ignoresSafeArea: Bool

    init(ignoresSafeArea: Bool = true) {
        self.ignoresSafeArea = ignoresSafeArea
    }

    var body: some View {
        Color.appBackground
            .if(ignoresSafeArea) { view in
                view.ignoresSafeArea()
            }
    }
}

// MARK: - Conditional modifier helper

private extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    AppBackground()
}
