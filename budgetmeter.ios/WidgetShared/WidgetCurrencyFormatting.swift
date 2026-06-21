//
//  WidgetCurrencyFormatting.swift
//  BudgetMeter
//
//  Locale-aware currency display for widgets — mirrors CurrencyDisplay contract
//  without Core Data or app-only dependencies.
//

import Foundation

enum WidgetCurrencyFormatting {
    private static let supportedCurrencyCodes: Set<String> = [
        "USD", "EUR", "JPY", "GBP", "AUD",
        "CAD", "CHF", "CNY", "NZD", "SEK",
        "NOK", "SGD", "KRW", "INR", "BRL",
        "MXN", "ZAR", "TRY", "RUB", "HKD", "SAR"
    ]

    private static let currencyLocaleOverrides: [String: String] = [
        "USD": "en_US",
        "EUR": "de_DE",
        "JPY": "ja_JP",
        "GBP": "en_GB",
        "AUD": "en_AU",
        "CAD": "en_CA",
        "CHF": "de_CH",
        "CNY": "zh_CN",
        "NZD": "en_NZ",
        "SEK": "sv_SE",
        "NOK": "nb_NO",
        "SGD": "en_SG",
        "KRW": "ko_KR",
        "INR": "en_IN",
        "BRL": "pt_BR",
        "MXN": "es_MX",
        "ZAR": "en_ZA",
        "TRY": "tr_TR",
        "RUB": "ru_RU",
        "HKD": "zh_HK",
        "SAR": "ar_SA"
    ]

    static func format(
        amount: Double,
        currencyCode: String,
        locale: Locale = .current
    ) -> String {
        let resolvedCode = resolvedCurrencyCode(currencyCode)
        let formatter = displayFormatter(
            for: resolvedCode,
            locale: locale,
            amount: amount
        )

        if let formatted = formatter.string(from: NSNumber(value: amount)) {
            return formatted
        }

        return displayFallback(amount: amount, currencyCode: resolvedCode, locale: locale)
    }

    static func signedDailyPace(
        _ amount: Double,
        currencyCode: String,
        locale: Locale = .current
    ) -> String {
        let sign = amount >= 0 ? "+" : "−"
        let formattedAmount = format(amount: abs(amount), currencyCode: currencyCode, locale: locale)
        let perDay = String(localized: "ui.units.per_day", defaultValue: "/day", table: "UI")
        return "\(sign)\(formattedAmount)\(perDay)"
    }

    static func fractionDigits(for amount: Double) -> Int {
        abs(amount) >= 100 ? 0 : 2
    }

    static func symbol(for currencyCode: String) -> String {
        locale(for: currencyCode).currencySymbol ?? currencyCode
    }

    private static func resolvedCurrencyCode(_ currencyCode: String) -> String {
        guard supportedCurrencyCodes.contains(currencyCode) else {
            if let localeCode = Locale.current.currency?.identifier,
               supportedCurrencyCodes.contains(localeCode) {
                return localeCode
            }
            return "USD"
        }
        return currencyCode
    }

    private static func locale(for code: String) -> Locale {
        if let overrideIdentifier = currencyLocaleOverrides[code] {
            return Locale(identifier: overrideIdentifier)
        }
        let identifier = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code])
        let locale = Locale(identifier: identifier)
        if locale.currency?.identifier == code {
            return locale
        }
        return Locale(identifier: "en_US")
    }

    private static func displayFormatter(
        for currencyCode: String,
        locale: Locale,
        amount: Double
    ) -> NumberFormatter {
        let fractionDigits = fractionDigits(for: amount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = fractionDigits
        return formatter
    }

    private static func displayFallback(
        amount: Double,
        currencyCode: String,
        locale: Locale
    ) -> String {
        let fractionDigits = fractionDigits(for: amount)
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = fractionDigits
        numberFormatter.maximumFractionDigits = fractionDigits
        numberFormatter.locale = locale

        let formattedNumber = numberFormatter.string(from: NSNumber(value: amount))
            ?? String(format: fractionDigits == 0 ? "%.0f" : "%.2f", amount)

        let symbol = symbol(for: currencyCode)
        if localeCurrencySymbolIsSuffix(currencyCode: currencyCode, locale: locale) {
            return "\(formattedNumber)\(symbol)"
        }
        return "\(symbol)\(formattedNumber)"
    }

    private static func localeCurrencySymbolIsSuffix(currencyCode: String, locale: Locale) -> Bool {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        guard let sample = formatter.string(from: 1) else { return false }
        let symbol = symbol(for: currencyCode)
        return sample.hasSuffix(symbol)
    }
}
