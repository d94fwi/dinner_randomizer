import Foundation
import Combine

@MainActor
final class DinnerRandomizerViewModel: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case ready
        case empty
        case failed(String)
    }

    private enum Constants {
        static let recentRepeatBufferSize = 10
    }

    @Published private(set) var dinners: [Dinner] = []
    @Published private(set) var currentDinnerId: Dinner.ID?
    @Published private(set) var previousDinnerIds: [Dinner.ID] = []
    @Published private(set) var loadState: LoadState = .loading
    @Published var language: AppLanguage {
        didSet {
            userDefaults.set(language.rawValue, forKey: AppLanguage.storageKey)
        }
    }

    private let loader: DinnerResourceLoader
    private let userDefaults: UserDefaults
    private var upcomingDinnerIds: [Dinner.ID] = []
    private var recentDinnerIds: [Dinner.ID] = []

    init(
        loader: DinnerResourceLoader? = nil,
        userDefaults: UserDefaults = .standard,
        preferredLanguages: [String] = Locale.preferredLanguages,
        autoLoad: Bool = true
    ) {
        self.loader = loader ?? DinnerResourceLoader()
        self.userDefaults = userDefaults
        self.language = AppLanguage.initialLanguage(
            userDefaults: userDefaults,
            preferredLanguages: preferredLanguages
        )

        #if DEBUG
        if let screenshotLanguage = Self.screenshotLanguageArgument() {
            self.language = screenshotLanguage
        }
        #endif

        if autoLoad {
            loadDinners()
        }
    }

    var copy: AppCopy {
        AppCopy.copy(for: language)
    }

    var canGoBack: Bool {
        !previousDinnerIds.isEmpty
    }

    var poolCountText: String {
        switch loadState {
        case .loading:
            return copy.loadingIdeas
        case .ready:
            return copy.ideaCount(dinners.count)
        case .empty:
            return copy.noIdeasLoaded
        case .failed:
            return copy.dataUnavailable
        }
    }

    var currentDinner: Dinner? {
        guard let currentDinnerId else {
            return nil
        }

        return dinner(with: currentDinnerId)
    }

    var localizedCurrentDinner: LocalizedDinner? {
        currentDinner?.localized(for: language, fallbackDescription: copy.fallbackDescription)
    }

    var localizedPreviousDinner: LocalizedDinner? {
        guard let previousDinnerId = previousDinnerIds.last else {
            return nil
        }

        return dinner(with: previousDinnerId)?.localized(for: language, fallbackDescription: copy.fallbackDescription)
    }

    var localizedUpcomingDinner: LocalizedDinner? {
        upcomingDinnerIds
            .compactMap { dinner(with: $0) }
            .first?
            .localized(for: language, fallbackDescription: copy.fallbackDescription)
    }

    var recipeSearchURL: URL? {
        guard let dinner = localizedCurrentDinner else {
            return nil
        }

        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: "\(dinner.name) \(copy.recipeSearchTerm)")
        ]

        return components?.url
    }

    func loadDinners() {
        loadState = .loading

        do {
            dinners = try loader.loadDinners()
            currentDinnerId = nil
            previousDinnerIds = []
            upcomingDinnerIds = []
            recentDinnerIds = []

            guard !dinners.isEmpty else {
                loadState = .empty
                return
            }

            loadState = .ready

            #if DEBUG
            if let screenshotDinnerId = Self.screenshotDinnerIdArgument(),
               dinner(with: screenshotDinnerId) != nil {
                currentDinnerId = screenshotDinnerId
                upcomingDinnerIds = createShuffledDinnerQueue().filter { $0 != screenshotDinnerId }
                recentDinnerIds = [screenshotDinnerId]
                return
            }
            #endif

            pickRandomDinner()
        } catch {
            dinners = []
            currentDinnerId = nil
            previousDinnerIds = []
            upcomingDinnerIds = []
            recentDinnerIds = []
            loadState = .failed(error.localizedDescription)
        }
    }

    func pickRandomDinner() {
        guard !dinners.isEmpty else {
            currentDinnerId = nil
            loadState = .empty
            return
        }

        if upcomingDinnerIds.isEmpty {
            upcomingDinnerIds = createShuffledDinnerQueue()
        }

        guard let nextDinnerId = popNextValidDinnerId() else {
            upcomingDinnerIds = createShuffledDinnerQueue()

            guard let fallbackDinnerId = popNextValidDinnerId() else {
                currentDinnerId = nil
                loadState = .empty
                return
            }

            showDinner(with: fallbackDinnerId)
            return
        }

        showDinner(with: nextDinnerId)
        refillUpcomingDinnersIfNeeded()
    }

    func showPreviousDinner() {
        guard let previousDinnerId = previousDinnerIds.popLast() else {
            return
        }

        guard dinner(with: previousDinnerId) != nil else {
            return
        }

        currentDinnerId = previousDinnerId
    }

    func image(for dinner: LocalizedDinner?) -> URL? {
        loader.imageURL(for: dinner?.image)
    }

    private func showDinner(with dinnerId: Dinner.ID) {
        if let currentDinnerId {
            previousDinnerIds.append(currentDinnerId)
        }

        currentDinnerId = dinnerId
        rememberRecentDinner(dinnerId)
    }

    private func dinner(with id: Dinner.ID) -> Dinner? {
        dinners.first { $0.id == id }
    }

    private func popNextValidDinnerId() -> Dinner.ID? {
        while !upcomingDinnerIds.isEmpty {
            let dinnerId = upcomingDinnerIds.removeFirst()

            if dinner(with: dinnerId) != nil {
                return dinnerId
            }
        }

        return nil
    }

    private func refillUpcomingDinnersIfNeeded() {
        if upcomingDinnerIds.isEmpty {
            upcomingDinnerIds = createShuffledDinnerQueue()
        }
    }

    private func createShuffledDinnerQueue() -> [Dinner.ID] {
        let recentDinnerIds = Set(self.recentDinnerIds.suffix(Constants.recentRepeatBufferSize))
        let shuffledDinnerIds = dinners.map(\.id).shuffled()

        guard !recentDinnerIds.isEmpty else {
            return shuffledDinnerIds
        }

        let availableDinnerIds = shuffledDinnerIds.filter { !recentDinnerIds.contains($0) }
        let delayedDinnerIds = shuffledDinnerIds.filter { recentDinnerIds.contains($0) }

        return availableDinnerIds + delayedDinnerIds
    }

    private func rememberRecentDinner(_ dinnerId: Dinner.ID) {
        recentDinnerIds.append(dinnerId)

        if recentDinnerIds.count > Constants.recentRepeatBufferSize {
            recentDinnerIds = Array(recentDinnerIds.suffix(Constants.recentRepeatBufferSize))
        }
    }
}

#if DEBUG
extension DinnerRandomizerViewModel {
    private static func screenshotDinnerIdArgument() -> Dinner.ID? {
        screenshotArgumentValue(named: "-screenshotDinner")
    }

    private static func screenshotLanguageArgument() -> AppLanguage? {
        guard let value = screenshotArgumentValue(named: "-screenshotLanguage") else {
            return nil
        }

        return AppLanguage(rawValue: value)
    }

    private static func screenshotArgumentValue(named name: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments

        guard let index = arguments.firstIndex(of: name),
              arguments.indices.contains(index + 1) else {
            return nil
        }

        return arguments[index + 1]
    }

    static var preview: DinnerRandomizerViewModel {
        let viewModel = DinnerRandomizerViewModel(autoLoad: false)
        viewModel.dinners = [
            Dinner(
                id: "taco-bowls",
                name: "Build-Your-Own Taco Bowls",
                description: "Rice bowls with seasoned beef or beans, corn, salsa, avocado, cheese, and crunchy tortilla chips.",
                mainIngredients: ["rice", "ground beef or beans", "corn", "salsa", "avocado"],
                image: "assets/dishes/taco-bowls.jpg",
                notes: "Set toppings out separately so everyone can build their own bowl.",
                translations: nil
            )
        ]
        viewModel.currentDinnerId = "taco-bowls"
        viewModel.loadState = .ready
        return viewModel
    }
}
#endif
