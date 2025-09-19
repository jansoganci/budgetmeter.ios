//
//  CurrencyHelper.swift
//  BudgetMeter
//
//  Created by BudgetMeter Team on 17.09.2025.
//

import Foundation

struct CurrencyOption: Identifiable, Equatable {
    let id: String
    let code: String
    let symbol: String
    let localizedName: String

    init(code: String, symbol: String, localizedName: String) {
        self.id = code
        self.code = code
        self.symbol = symbol
        self.localizedName = localizedName
    }
}

enum CurrencyHelper {
    static let supportedCurrencyCodes: [String] = [
        "USD", "EUR", "JPY", "GBP", "AUD",
        "CAD", "CHF", "CNY", "NZD", "SEK",
        "NOK", "SGD", "KRW", "INR", "BRL",
        "MXN", "ZAR", "TRY", "RUB", "HKD", "SAR"
    ]

    static let featuredCurrencyCodes: [String] = [
        "USD", "EUR", "GBP", "JPY", "CNY"
    ]
    
    /// Maps app language codes to preferred currency codes
    private static let languageCurrencyMappings: [String: String] = [
        "en": "USD",     // English → US Dollar
        "tr": "TRY",     // Turkish → Turkish Lira
        "de": "EUR",     // German → Euro
        "fr": "EUR",     // French → Euro
        "es": "EUR",     // Spanish → Euro
        "it": "EUR",     // Italian → Euro
        "pt": "EUR",     // Portuguese → Euro
        "ja": "JPY",     // Japanese → Japanese Yen
        "zh-Hans": "CNY", // Chinese → Chinese Yuan
        "ar": "SAR"      // Arabic → Saudi Riyal
    ]
    
    /// Maps app language codes to currency symbols for quick access
    private static let languageSymbolMappings: [String: String] = [
        "en": "$",       // US Dollar
        "tr": "₺",       // Turkish Lira
        "de": "€",       // Euro
        "fr": "€",       // Euro
        "es": "€",       // Euro
        "it": "€",       // Euro
        "pt": "€",       // Euro
        "ja": "¥",       // Japanese Yen
        "zh-Hans": "¥",  // Chinese Yuan
        "ar": "ر.س"      // Saudi Riyal
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

    static func allCurrencyOptions() -> [CurrencyOption] {
        supportedCurrencyCodes.compactMap { code in
            let locale = locale(for: code)
            let symbol = locale.currencySymbol ?? code
            let name = Locale.current.localizedString(forCurrencyCode: code) ?? code
            return CurrencyOption(code: code, symbol: symbol, localizedName: name)
        }
    }

    static func currencyOption(for code: String) -> CurrencyOption? {
        allCurrencyOptions().first { $0.code == code }
    }

    static func groupedCurrencyOptions() -> (featured: [CurrencyOption], others: [CurrencyOption]) {
        let allOptions = allCurrencyOptions()
        let featuredSet = Set(featuredCurrencyCodes)

        let featured = featuredCurrencyCodes.compactMap { code in
            allOptions.first { $0.code == code }
        }

        let others = allOptions
            .filter { !featuredSet.contains($0.code) }
            .sorted { lhs, rhs in
                lhs.localizedName.localizedCaseInsensitiveCompare(rhs.localizedName) == .orderedAscending
            }

        return (featured, others)
    }

    static func defaultCurrencyCode() -> String {
        let locale = Locale.current
        if let localeCode = locale.currency?.identifier,
           supportedCurrencyCodes.contains(localeCode) {
            return localeCode
        }
        if let currencyCode = locale.currency?.identifier,
           supportedCurrencyCodes.contains(currencyCode) {
            return currencyCode
        }
        return "USD"
    }

    static func locale(for code: String) -> Locale {
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

    static func formatter(for code: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale(identifier: "en_US") // Standardized US formatting (1,234.56)
        formatter.currencySymbol = symbol(for: code)
        return formatter
    }

    static func symbol(for code: String) -> String {
        locale(for: code).currencySymbol ?? code
    }
    
    // MARK: - Multi-Language Currency Support
    
    /// Returns the preferred currency code for the current app language
    static func currencyForCurrentLanguage() -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return languageCurrencyMappings[languageCode] ?? "USD"
    }
    
    /// Returns the currency symbol for the current app language
    static func symbolForCurrentLanguage() -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return languageSymbolMappings[languageCode] ?? "$"
    }
    
    /// Returns a localized currency formatter for the current language
    static func localizedFormatter() -> NumberFormatter {
        let currencyCode = currencyForCurrentLanguage()
        return formatter(for: currencyCode)
    }
    
    /// Returns a currency formatter for a specific language
    static func formatterForLanguage(_ languageCode: String) -> NumberFormatter {
        let currencyCode = languageCurrencyMappings[languageCode] ?? "USD"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "en_US") // Standardized US formatting (1,234.56)
        formatter.currencySymbol = languageSymbolMappings[languageCode] ?? "$"
        return formatter
    }
    
    /// Formats an amount using the current language's currency settings
    static func formatAmount(_ amount: Double) -> String {
        let formatter = localizedFormatter()
        return formatter.string(from: NSNumber(value: amount)) ?? "\(symbolForCurrentLanguage())\(amount)"
    }
    
    /// Formats an amount for a specific language
    static func formatAmount(_ amount: Double, for languageCode: String) -> String {
        let formatter = formatterForLanguage(languageCode)
        return formatter.string(from: NSNumber(value: amount)) ?? "\(languageSymbolMappings[languageCode] ?? "$")\(amount)"
    }
}

extension Notification.Name {
    static let currencyDidChange = Notification.Name("CurrencyDidChangeNotification")
}
