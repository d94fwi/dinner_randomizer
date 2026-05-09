import Foundation

struct AppCopy {
    let pageTitle: String
    let appTitle: String
    let languageLabel: String
    let languages: [AppLanguage: String]
    let loadingIdeas: String
    let loadingDinnerName: String
    let loadingDescription: String
    let mainIngredients: String
    let back: String
    let next: String
    let recipeSearch: String
    let recipeSearchTerm: String
    let noIdeasLoaded: String
    let noDinnerIdeasYet: String
    let noIdeasDescription: String
    let dataUnavailable: String
    let loadErrorName: String
    let loadErrorDescription: String
    let fallbackDescription: String
    let ideaCount: (Int) -> String

    static func copy(for language: AppLanguage) -> AppCopy {
        switch language {
        case .en:
            return AppCopy(
                pageTitle: "Dinner Randomizer",
                appTitle: "Dinner Randomizer",
                languageLabel: "Language",
                languages: [
                    .en: "English",
                    .sv: "Swedish",
                    .no: "Norwegian",
                    .pl: "Polish"
                ],
                loadingIdeas: "Loading ideas",
                loadingDinnerName: "Loading dinner ideas...",
                loadingDescription: "The app is reading the dinner list.",
                mainIngredients: "Main ingredients",
                back: "Back",
                next: "Next dinner idea",
                recipeSearch: "Search recipe on Google",
                recipeSearchTerm: "recipe",
                noIdeasLoaded: "No ideas loaded",
                noDinnerIdeasYet: "No dinner ideas yet",
                noIdeasDescription: "Add dinners to shared/data/dinners.json to start picking.",
                dataUnavailable: "Data unavailable",
                loadErrorName: "Could not load dinner ideas",
                loadErrorDescription: "The bundled dinner data could not be read.",
                fallbackDescription: "A family dinner idea.",
                ideaCount: { count in "\(count) idea\(count == 1 ? "" : "s")" }
            )
        case .sv:
            return AppCopy(
                pageTitle: "Dagens middag",
                appTitle: "Dagens middag",
                languageLabel: "Språk",
                languages: [
                    .en: "Engelska",
                    .sv: "Svenska",
                    .no: "Norska",
                    .pl: "Polska"
                ],
                loadingIdeas: "Laddar idéer",
                loadingDinnerName: "Laddar middagsidéer...",
                loadingDescription: "Appen läser in middagslistan.",
                mainIngredients: "Huvudingredienser",
                back: "Tillbaka",
                next: "Nästa middagsidé",
                recipeSearch: "Sök recept på Google",
                recipeSearchTerm: "recept",
                noIdeasLoaded: "Inga idéer laddade",
                noDinnerIdeasYet: "Inga middagsidéer ännu",
                noIdeasDescription: "Lägg till middagar i shared/data/dinners.json för att börja lotta.",
                dataUnavailable: "Data saknas",
                loadErrorName: "Kunde inte ladda middagsidéer",
                loadErrorDescription: "Den paketerade middagsdatan kunde inte läsas.",
                fallbackDescription: "En middagsidé för familjen.",
                ideaCount: { count in "\(count) \(count == 1 ? "idé" : "idéer")" }
            )
        case .no:
            return AppCopy(
                pageTitle: "Dagens middag",
                appTitle: "Dagens middag",
                languageLabel: "Språk",
                languages: [
                    .en: "Engelsk",
                    .sv: "Svensk",
                    .no: "Norsk",
                    .pl: "Polsk"
                ],
                loadingIdeas: "Laster ideer",
                loadingDinnerName: "Laster middagsideer...",
                loadingDescription: "Appen leser middagslisten.",
                mainIngredients: "Hovedingredienser",
                back: "Tilbake",
                next: "Neste middagsidé",
                recipeSearch: "Søk etter oppskrift på Google",
                recipeSearchTerm: "oppskrift",
                noIdeasLoaded: "Ingen ideer lastet",
                noDinnerIdeasYet: "Ingen middagsideer ennå",
                noIdeasDescription: "Legg til middager i shared/data/dinners.json for å begynne å trekke.",
                dataUnavailable: "Data mangler",
                loadErrorName: "Kunne ikke laste middagsideer",
                loadErrorDescription: "De pakkede middagsdataene kunne ikke leses.",
                fallbackDescription: "En middagsidé for familien.",
                ideaCount: { count in "\(count) \(count == 1 ? "idé" : "ideer")" }
            )
        case .pl:
            return AppCopy(
                pageTitle: "Dzisiejszy obiad",
                appTitle: "Dzisiejszy obiad",
                languageLabel: "Język",
                languages: [
                    .en: "Angielski",
                    .sv: "Szwedzki",
                    .no: "Norweski",
                    .pl: "Polski"
                ],
                loadingIdeas: "Ładowanie pomysłów",
                loadingDinnerName: "Ładowanie pomysłów na obiad...",
                loadingDescription: "Aplikacja wczytuje listę dań.",
                mainIngredients: "Główne składniki",
                back: "Wstecz",
                next: "Następny pomysł",
                recipeSearch: "Szukaj przepisu w Google",
                recipeSearchTerm: "przepis",
                noIdeasLoaded: "Nie wczytano pomysłów",
                noDinnerIdeasYet: "Nie ma jeszcze pomysłów na obiad",
                noIdeasDescription: "Dodaj dania do shared/data/dinners.json, aby zacząć losowanie.",
                dataUnavailable: "Brak danych",
                loadErrorName: "Nie udało się wczytać pomysłów na obiad",
                loadErrorDescription: "Nie udało się odczytać danych obiadów dołączonych do aplikacji.",
                fallbackDescription: "Pomysł na rodzinny obiad.",
                ideaCount: { count in
                    let mod10 = count % 10
                    let mod100 = count % 100

                    if count == 1 {
                        return "\(count) pomysł"
                    }

                    if mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14) {
                        return "\(count) pomysły"
                    }

                    return "\(count) pomysłów"
                }
            )
        }
    }
}
