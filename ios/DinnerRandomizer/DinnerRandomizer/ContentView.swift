import SwiftUI

struct ContentView: View {
    private static let sage = Color(red: 81 / 255, green: 108 / 255, blue: 86 / 255)
    private static let sageDark = Color(red: 49 / 255, green: 75 / 255, blue: 57 / 255)
    private static let mustard = Color(red: 194 / 255, green: 146 / 255, blue: 50 / 255)
    private static let swipeThreshold: CGFloat = 80
    private static let cardGap: CGFloat = 14

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
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    content
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(Color(.systemGroupedBackground))
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
    private var content: some View {
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
                swipeableDinnerView(dinner)
            } else {
                statusView(
                    systemImage: "tray",
                    title: viewModel.copy.noDinnerIdeasYet,
                    description: viewModel.copy.noIdeasDescription
                )
            }
        }
    }

    private func swipeableDinnerView(_ dinner: LocalizedDinner) -> some View {
        ZStack(alignment: .top) {
            if let previousDinner = viewModel.localizedPreviousDinner {
                dinnerCard(previousDinner)
                    .offset(x: -cardTravelDistance + cardDragOffset)
                    .allowsHitTesting(false)
            }

            if let upcomingDinner = viewModel.localizedUpcomingDinner {
                dinnerCard(upcomingDinner)
                    .offset(x: cardTravelDistance + cardDragOffset)
                    .allowsHitTesting(false)
            }

            dinnerCard(dinner)
                .offset(x: cardDragOffset)
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

    private func dinnerCard(_ dinner: LocalizedDinner) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            DinnerImageView(url: viewModel.image(for: dinner), title: dinner.name)

            VStack(alignment: .leading, spacing: 5) {
                Text(viewModel.poolCountText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(dinner.name)
                    .font(.title2.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(dinner.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ingredientsView(dinner.mainIngredients)

            if !dinner.notes.isEmpty {
                Text(dinner.notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .padding(.leading, 14)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Self.mustard)
                            .frame(width: 4)
                    }
            }
        }
        .padding(10)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func ingredientsView(_ ingredients: [String]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(viewModel.copy.mainIngredients)
                .font(.subheadline.bold())

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12, alignment: .leading),
                    GridItem(.flexible(), spacing: 12, alignment: .leading)
                ],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(ingredients, id: \.self) { ingredient in
                    Text(ingredient)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Self.sageDark)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
                        .background(Self.sage.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
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
