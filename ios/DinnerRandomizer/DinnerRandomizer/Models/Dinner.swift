import Foundation

struct Dinner: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let mainIngredients: [String]?
    let image: String?
    let notes: String?
    let translations: [String: DinnerTranslation]?

    func localized(for language: AppLanguage, fallbackDescription: String) -> LocalizedDinner {
        let translation = translations?[language.rawValue]
        let translatedIngredients = translation?.mainIngredients ?? []
        let ingredients = translatedIngredients.isEmpty ? (mainIngredients ?? []) : translatedIngredients

        return LocalizedDinner(
            id: id,
            name: translation?.name?.nilIfEmpty ?? name,
            description: translation?.description?.nilIfEmpty ?? description?.nilIfEmpty ?? fallbackDescription,
            mainIngredients: ingredients,
            image: image,
            notes: translation?.notes ?? notes ?? ""
        )
    }
}

struct DinnerTranslation: Decodable, Equatable {
    let name: String?
    let description: String?
    let mainIngredients: [String]?
    let notes: String?
}

struct LocalizedDinner: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let mainIngredients: [String]
    let image: String?
    let notes: String
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
