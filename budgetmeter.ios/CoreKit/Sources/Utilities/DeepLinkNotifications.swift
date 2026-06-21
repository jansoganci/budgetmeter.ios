//
//  DeepLinkNotifications.swift
//  BudgetMeter
//
//  Shared deep-link navigation notification names.
//

import Foundation

extension Notification.Name {
    static let navigateToHome = Notification.Name("NavigateToHome")
    static let navigateToHomeHero = Notification.Name("NavigateToHomeHero")
    static let navigateToPremiumWidgets = Notification.Name("NavigateToPremiumWidgets")
    static let navigateToExpenses = Notification.Name("NavigateToExpenses")
    static let navigateToIncome = Notification.Name("NavigateToIncome")
    static let focusHomeHero = Notification.Name("FocusHomeHero")
}
