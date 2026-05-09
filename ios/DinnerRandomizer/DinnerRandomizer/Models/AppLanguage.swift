import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case en
    case sv
    case no
    case pl

    static let storageKey = "dinnerRandomizerLanguage"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .en:
            return "🇬🇧"
        case .sv:
            return "🇸🇪"
        case .no:
            return "🇳🇴"
        case .pl:
            return "🇵🇱"
        }
    }

    static func initialLanguage(
        userDefaults: UserDefaults = .standard,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> AppLanguage {
        if
            let savedLanguage = userDefaults.string(forKey: storageKey),
            let language = AppLanguage(rawValue: savedLanguage)
        {
            return language
        }

        for language in preferredLanguages {
            let normalizedLanguage = language.lowercased()

            if normalizedLanguage.hasPrefix("sv") {
                return .sv
            }

            if
                normalizedLanguage.hasPrefix("no") ||
                normalizedLanguage.hasPrefix("nb") ||
                normalizedLanguage.hasPrefix("nn")
            {
                return .no
            }

            if normalizedLanguage.hasPrefix("pl") {
                return .pl
            }
        }

        return .en
    }
}
