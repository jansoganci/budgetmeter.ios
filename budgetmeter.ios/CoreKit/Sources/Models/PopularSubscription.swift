//
//  PopularSubscription.swift
//  BudgetMeter
//
//  Model for popular subscription templates
//

import Foundation

/// Categories for popular subscriptions
enum SubscriptionCategory: String, CaseIterable, Identifiable {
    case streaming = "Streaming"
    case music = "Music"
    case aiTools = "AI Tools"
    case cloudStorage = "Cloud Storage"
    case gaming = "Gaming"
    case productivity = "Productivity"
    case fitness = "Fitness"
    case newsReading = "News & Reading"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .streaming:
            return String(localized: "subscription.category.streaming", defaultValue: "Streaming")
        case .music:
            return String(localized: "subscription.category.music", defaultValue: "Music")
        case .aiTools:
            return String(localized: "subscription.category.ai", defaultValue: "AI Tools")
        case .cloudStorage:
            return String(localized: "subscription.category.cloud", defaultValue: "Cloud Storage")
        case .gaming:
            return String(localized: "subscription.category.gaming", defaultValue: "Gaming")
        case .productivity:
            return String(localized: "subscription.category.productivity", defaultValue: "Productivity")
        case .fitness:
            return String(localized: "subscription.category.fitness", defaultValue: "Fitness")
        case .newsReading:
            return String(localized: "subscription.category.news", defaultValue: "News & Reading")
        }
    }
}

/// Model for a popular subscription template
struct PopularSubscription: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let category: SubscriptionCategory

    var localizedName: String {
        // Most subscription names are brand names, no localization needed
        return name
    }
}

/// Provider for popular subscription templates
enum PopularSubscriptionProvider {

    /// All popular subscriptions grouped by category
    static var allSubscriptions: [SubscriptionCategory: [PopularSubscription]] {
        var grouped: [SubscriptionCategory: [PopularSubscription]] = [:]

        for category in SubscriptionCategory.allCases {
            grouped[category] = subscriptions(for: category)
        }

        return grouped
    }

    /// Get subscriptions for a specific category
    static func subscriptions(for category: SubscriptionCategory) -> [PopularSubscription] {
        switch category {
        case .streaming:
            return [
                PopularSubscription(id: "netflix", name: "Netflix", iconName: "play.tv", category: .streaming),
                PopularSubscription(id: "youtube_premium", name: "YouTube Premium", iconName: "play.rectangle", category: .streaming),
                PopularSubscription(id: "disney_plus", name: "Disney+", iconName: "sparkles.tv", category: .streaming),
                PopularSubscription(id: "hbo_max", name: "HBO Max", iconName: "tv", category: .streaming),
                PopularSubscription(id: "amazon_prime", name: "Amazon Prime", iconName: "shippingbox", category: .streaming),
                PopularSubscription(id: "apple_tv", name: "Apple TV+", iconName: "appletv", category: .streaming),
                PopularSubscription(id: "hulu", name: "Hulu", iconName: "play.tv", category: .streaming),
                PopularSubscription(id: "paramount_plus", name: "Paramount+", iconName: "play.tv", category: .streaming)
            ]

        case .music:
            return [
                PopularSubscription(id: "spotify", name: "Spotify", iconName: "music.note", category: .music),
                PopularSubscription(id: "apple_music", name: "Apple Music", iconName: "music.note.list", category: .music),
                PopularSubscription(id: "youtube_music", name: "YouTube Music", iconName: "music.quarternote.3", category: .music),
                PopularSubscription(id: "tidal", name: "Tidal", iconName: "waveform", category: .music),
                PopularSubscription(id: "amazon_music", name: "Amazon Music", iconName: "music.note", category: .music)
            ]

        case .aiTools:
            return [
                PopularSubscription(id: "chatgpt", name: "ChatGPT Plus", iconName: "brain", category: .aiTools),
                PopularSubscription(id: "claude", name: "Claude Pro", iconName: "brain.head.profile", category: .aiTools),
                PopularSubscription(id: "midjourney", name: "Midjourney", iconName: "paintbrush", category: .aiTools),
                PopularSubscription(id: "copilot", name: "GitHub Copilot", iconName: "chevron.left.forwardslash.chevron.right", category: .aiTools),
                PopularSubscription(id: "perplexity", name: "Perplexity", iconName: "magnifyingglass", category: .aiTools)
            ]

        case .cloudStorage:
            return [
                PopularSubscription(id: "icloud", name: "iCloud+", iconName: "icloud", category: .cloudStorage),
                PopularSubscription(id: "google_one", name: "Google One", iconName: "cloud", category: .cloudStorage),
                PopularSubscription(id: "dropbox", name: "Dropbox", iconName: "externaldrive.badge.icloud", category: .cloudStorage),
                PopularSubscription(id: "onedrive", name: "OneDrive", iconName: "cloud", category: .cloudStorage)
            ]

        case .gaming:
            return [
                PopularSubscription(id: "xbox_gamepass", name: "Xbox Game Pass", iconName: "gamecontroller", category: .gaming),
                PopularSubscription(id: "ps_plus", name: "PlayStation Plus", iconName: "gamecontroller.fill", category: .gaming),
                PopularSubscription(id: "nintendo_online", name: "Nintendo Online", iconName: "gamecontroller", category: .gaming),
                PopularSubscription(id: "apple_arcade", name: "Apple Arcade", iconName: "arcade.stick", category: .gaming),
                PopularSubscription(id: "ea_play", name: "EA Play", iconName: "gamecontroller", category: .gaming)
            ]

        case .productivity:
            return [
                PopularSubscription(id: "microsoft_365", name: "Microsoft 365", iconName: "doc.text", category: .productivity),
                PopularSubscription(id: "adobe_cc", name: "Adobe Creative Cloud", iconName: "paintbrush.pointed", category: .productivity),
                PopularSubscription(id: "notion", name: "Notion", iconName: "doc.richtext", category: .productivity),
                PopularSubscription(id: "canva", name: "Canva Pro", iconName: "paintpalette", category: .productivity),
                PopularSubscription(id: "figma", name: "Figma", iconName: "pencil.and.ruler", category: .productivity),
                PopularSubscription(id: "slack", name: "Slack", iconName: "bubble.left.and.bubble.right", category: .productivity)
            ]

        case .fitness:
            return [
                PopularSubscription(id: "gym", name: "Gym Membership", iconName: "dumbbell", category: .fitness),
                PopularSubscription(id: "peloton", name: "Peloton", iconName: "bicycle", category: .fitness),
                PopularSubscription(id: "apple_fitness", name: "Apple Fitness+", iconName: "figure.run", category: .fitness),
                PopularSubscription(id: "strava", name: "Strava", iconName: "figure.outdoor.cycle", category: .fitness),
                PopularSubscription(id: "headspace", name: "Headspace", iconName: "brain.head.profile", category: .fitness)
            ]

        case .newsReading:
            return [
                PopularSubscription(id: "medium", name: "Medium", iconName: "book", category: .newsReading),
                PopularSubscription(id: "nyt", name: "New York Times", iconName: "newspaper", category: .newsReading),
                PopularSubscription(id: "wsj", name: "Wall Street Journal", iconName: "newspaper.fill", category: .newsReading),
                PopularSubscription(id: "economist", name: "The Economist", iconName: "newspaper", category: .newsReading),
                PopularSubscription(id: "kindle_unlimited", name: "Kindle Unlimited", iconName: "books.vertical", category: .newsReading),
                PopularSubscription(id: "audible", name: "Audible", iconName: "headphones", category: .newsReading)
            ]
        }
    }

    /// Flat list of all subscriptions
    static var flatList: [PopularSubscription] {
        SubscriptionCategory.allCases.flatMap { subscriptions(for: $0) }
    }
}
