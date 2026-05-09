import SwiftUI

struct ContentView: View {
    private static let sage = Color(red: 81 / 255, green: 108 / 255, blue: 86 / 255)
    private static let sageDark = Color(red: 49 / 255, green: 75 / 255, blue: 57 / 255)
    private static let mustard = Color(red: 194 / 255, green: 146 / 255, blue: 50 / 255)
    private static let swipeThreshold: CGFloat = 80
    private static let cardGap: CGFloat = 14
    private static let ingredientChipHeight: CGFloat = 38
    private static let ingredientColumnSpacing: CGFloat = 12
    private static let ingredientRowSpacing: CGFloat = 8

    private struct LayoutMetrics {
        let scrollVerticalPadding: CGFloat
        let cardPadding: CGFloat
        let cardSpacing: CGFloat
        let poolCountBottomPadding: CGFloat
        let titleBottomPadding: CGFloat
        let ingredientsTopPadding: CGFloat
        let ingredientsHeaderSpacing: CGFloat
        let ingredientRowSpacing: CGFloat
        let noteVerticalPadding: CGFloat

        init(availableHeight: CGFloat) {
            let roomyScale = min(max((availableHeight - 560) / 160, 0), 1)

            scrollVerticalPadding = 10 + (8 * roomyScale)
            cardPadding = 10 + (8 * roomyScale)
            cardSpacing = 10 + (8 * roomyScale)
            poolCountBottomPadding = 11 + (9 * roomyScale)
            titleBottomPadding = 5 + (5 * roomyScale)
            ingredientsTopPadding = 7 + (11 * roomyScale)
            ingredientsHeaderSpacing = 7 + (3 * roomyScale)
            ingredientRowSpacing = ContentView.ingredientRowSpacing
            noteVerticalPadding = 4 + (6 * roomyScale)
        }
    }

    @Environment(\.displayScale) private var displayScale
    @StateObject private var viewModel: DinnerRandomizerViewModel
    @State private var cardDragOffset: CGFloat = 0
    @State private var cardTravelDistance: CGFloat = 420

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: DinnerRandomizerViewModel())
    }

    @MainActor
    init(viewModel: DinnerRandomizerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let metrics = LayoutMetrics(availableHeight: geometry.size.height)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        content(metrics: metrics)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, metrics.scrollVerticalPadding)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle(viewModel.copy.pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                if showsControls {
                    controls
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .background(.regularMaterial)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    languageMenu
                }

                if let recipeSearchURL = viewModel.recipeSearchURL {
                    ToolbarItem(placement: .topBarLeading) {
                        Link(destination: recipeSearchURL) {
                            Image(systemName: "magnifyingglass")
                        }
                        .accessibilityLabel(viewModel.copy.recipeSearch)
                    }
                }
            }
        }
    }

    private var languageMenu: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                let languageName = viewModel.copy.languages[language] ?? language.rawValue
                let menuTitle = "\(language.flag) \(languageName)"

                Button {
                    viewModel.language = language
                } label: {
                    if language == viewModel.language {
                        Label(menuTitle, systemImage: "checkmark")
                    } else {
                        Text(menuTitle)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(viewModel.language.flag)
                    .font(.body)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
        }
        .accessibilityLabel(viewModel.copy.languageLabel)
    }

    private var showsControls: Bool {
        if case .ready = viewModel.loadState {
            return viewModel.localizedCurrentDinner != nil
        }

        return false
    }

    @ViewBuilder
    private func content(metrics: LayoutMetrics) -> some View {
        switch viewModel.loadState {
        case .loading:
            statusView(
                systemImage: "hourglass",
                title: viewModel.copy.loadingDinnerName,
                description: viewModel.copy.loadingDescription
            )
        case .empty:
            statusView(
                systemImage: "tray",
                title: viewModel.copy.noDinnerIdeasYet,
                description: viewModel.copy.noIdeasDescription
            )
        case .failed(let message):
            statusView(
                systemImage: "exclamationmark.triangle",
                title: viewModel.copy.loadErrorName,
                description: "\(viewModel.copy.loadErrorDescription)\n\(message)"
            )
        case .ready:
            if let dinner = viewModel.localizedCurrentDinner {
                swipeableDinnerView(dinner, metrics: metrics)
            } else {
                statusView(
                    systemImage: "tray",
                    title: viewModel.copy.noDinnerIdeasYet,
                    description: viewModel.copy.noIdeasDescription
                )
            }
        }
    }

    private func swipeableDinnerView(_ dinner: LocalizedDinner, metrics: LayoutMetrics) -> some View {
        ZStack(alignment: .top) {
            if let previousDinner = viewModel.localizedPreviousDinner {
                dinnerCard(previousDinner, metrics: metrics)
                    .offset(x: cardOffset(-cardTravelDistance + cardDragOffset))
                    .allowsHitTesting(false)
            }

            if let upcomingDinner = viewModel.localizedUpcomingDinner {
                dinnerCard(upcomingDinner, metrics: metrics)
                    .offset(x: cardOffset(cardTravelDistance + cardDragOffset))
                    .allowsHitTesting(false)
            }

            dinnerCard(dinner, metrics: metrics)
                .offset(x: cardOffset(cardDragOffset))
                .zIndex(1)
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        cardTravelDistance = proxy.size.width + Self.cardGap
                    }
                    .onChange(of: proxy.size.width) { _, newWidth in
                        cardTravelDistance = newWidth + Self.cardGap
                    }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(cardSwipeGesture)
        .clipped()
    }

    private func dinnerCard(_ dinner: LocalizedDinner, metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.cardSpacing) {
            DinnerImageView(url: viewModel.image(for: dinner), title: dinner.name)

            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.poolCountText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, metrics.poolCountBottomPadding)

                Text(dinner.name)
                    .font(.title2.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.bottom, metrics.titleBottomPadding)

                Text(dinner.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ingredientsView(dinner.mainIngredients, metrics: metrics)
                .padding(.top, metrics.ingredientsTopPadding)

            if !dinner.notes.isEmpty {
                Text(dinner.notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .padding(.leading, 14)
                    .padding(.vertical, metrics.noteVerticalPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Self.mustard)
                            .frame(width: 4)
                    }
            }
        }
        .padding(metrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .compositingGroup()
        .drawingGroup()
    }

    private func ingredientsView(_ ingredients: [String], metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.ingredientsHeaderSpacing) {
            Text(viewModel.copy.mainIngredients)
                .font(.subheadline.bold())

            VStack(spacing: metrics.ingredientRowSpacing) {
                ForEach(Array(ingredientRows(ingredients).enumerated()), id: \.offset) { _, row in
                    HStack(spacing: Self.ingredientColumnSpacing) {
                        ForEach(row, id: \.self) { ingredient in
                            ingredientChip(ingredient)
                        }

                        if row.count == 1 {
                            Color.clear
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: Self.ingredientChipHeight)
                }
            }
        }
    }

    private func ingredientRows(_ ingredients: [String]) -> [[String]] {
        stride(from: 0, to: ingredients.count, by: 2).map { index in
            Array(ingredients[index..<min(index + 2, ingredients.count)])
        }
    }

    private func ingredientChip(_ ingredient: String) -> some View {
        Text(ingredient)
            .font(.callout.weight(.semibold))
            .foregroundStyle(Self.sageDark)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: Self.ingredientChipHeight, maxHeight: Self.ingredientChipHeight, alignment: .leading)
            .background(Self.sage.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func cardOffset(_ offset: CGFloat) -> CGFloat {
        (offset * displayScale).rounded() / displayScale
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                showPreviousDinner()
            } label: {
                Label(viewModel.copy.back, systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .frame(width: 48)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.canGoBack)
            .accessibilityLabel(viewModel.copy.back)

            Button {
                showNextDinner()
            } label: {
                Label(viewModel.copy.next, systemImage: "shuffle")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .controlSize(.regular)
    }

    private var cardSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else {
                    return
                }

                cardDragOffset = value.translation.width
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        cardDragOffset = 0
                    }
                    return
                }

                handleCardSwipe(value.translation.width)
            }
    }

    private func handleCardSwipe(_ horizontalTranslation: CGFloat) {
        if horizontalTranslation <= -Self.swipeThreshold {
            showNextDinner()
            return
        }

        if horizontalTranslation >= Self.swipeThreshold, viewModel.canGoBack {
            showPreviousDinner()
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            cardDragOffset = 0
        }
    }

    private func showNextDinner() {
        animateCardChange(
            exitOffset: -cardTravelDistance,
            updateDinner: viewModel.pickRandomDinner
        )
    }

    private func showPreviousDinner() {
        guard viewModel.canGoBack else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                cardDragOffset = 0
            }
            return
        }

        animateCardChange(
            exitOffset: cardTravelDistance,
            updateDinner: viewModel.showPreviousDinner
        )
    }

    private func animateCardChange(
        exitOffset: CGFloat,
        updateDinner: @escaping () -> Void
    ) {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
            cardDragOffset = exitOffset
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            var transaction = Transaction()
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                updateDinner()
                cardDragOffset = 0
            }
        }
    }

    private func statusView(systemImage: String, title: String, description: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: .preview)
    }
}
#endif
