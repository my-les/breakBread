import SwiftUI
import SwiftData

struct RestaurantSearchView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.splitFlowNav) private var nav
    @Environment(\.dismissSplitFlow) private var dismissFlow
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var results: [Restaurant] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var isFallbackMode = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: BBSpacing.lg) {
                flowHeader(title: "where did you eat?", onClose: { dismissFlow() })
                BBSearchField(text: $searchText, placeholder: "search restaurants")
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.bottom, BBSpacing.md)

            if searchText.isEmpty {
                skipOption
            }

            if isFallbackMode {
                Text("using sample restaurants — add GOOGLE_PLACES_API_KEY for live search")
                    .font(BBFont.small)
                    .foregroundStyle(BBColor.secondaryText)
                    .padding(.horizontal, BBSpacing.lg)
                    .padding(.bottom, BBSpacing.sm)
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    if isSearching {
                        ProgressView()
                            .padding(.top, BBSpacing.lg)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(BBFont.caption)
                            .foregroundStyle(BBColor.error)
                            .padding(BBSpacing.lg)
                    } else if results.isEmpty {
                        Text("no restaurants found")
                            .font(BBFont.caption)
                            .foregroundStyle(BBColor.secondaryText)
                            .padding(BBSpacing.lg)
                    } else {
                        ForEach(results) { restaurant in
                            restaurantRow(restaurant)
                        }
                    }
                }
            }
        }
        .background(BBColor.background)
        .navigationBarHidden(true)
        .onChange(of: searchText) { _, query in
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                await search(query: query)
            }
        }
        .onAppear {
            isFallbackMode = !PlacesService.shared.isLiveSearchConfigured
        }
        .task {
            await search(query: "")
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    private func restaurantRow(_ restaurant: Restaurant) -> some View {
        Button {
            HapticManager.selection()
            vm.restaurant = restaurant
            selectRestaurant(restaurant)
        } label: {
            HStack(spacing: BBSpacing.md) {
                RoundedRectangle(cornerRadius: BBRadius.sm)
                    .fill(BBColor.cardSurface)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Text(String(restaurant.name.prefix(1)))
                            .font(BBFont.sectionHeader)
                            .foregroundStyle(BBColor.secondaryText)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(restaurant.name)
                        .font(BBFont.bodyBold)
                        .foregroundStyle(BBColor.primaryText)
                    HStack(spacing: BBSpacing.xs) {
                        Text(restaurant.category)
                        Text("·")
                        Text(restaurant.priceLevelString)
                        if restaurant.rating > 0 {
                            Text("·")
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text(String(format: "%.1f", restaurant.rating))
                        }
                    }
                    .font(BBFont.caption)
                    .foregroundStyle(BBColor.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BBColor.secondaryText)
            }
            .padding(.horizontal, BBSpacing.lg)
            .padding(.vertical, BBSpacing.md)
        }
    }

    private var skipOption: some View {
        Button {
            vm.restaurant = nil
            nav.advance(.party)
        } label: {
            HStack {
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 16))
                Text("skip — enter manually later")
                    .font(BBFont.body)
                Spacer()
            }
            .foregroundStyle(BBColor.secondaryText)
            .padding(.horizontal, BBSpacing.lg)
            .padding(.vertical, BBSpacing.md)
        }
    }

    private func search(query: String) async {
        isSearching = true
        errorMessage = nil
        do {
            results = try await PlacesService.shared.searchRestaurants(query: query)
        } catch {
            results = []
            errorMessage = "Search unavailable. Please try again."
        }
        isSearching = false
    }

    private func selectRestaurant(_ restaurant: Restaurant) {
        let placeId = restaurant.id
        let descriptor = FetchDescriptor<CrowdsourcedMenuItem>(
            predicate: #Predicate { $0.placeId == placeId },
            sortBy: [SortDescriptor(\CrowdsourcedMenuItem.timesOrdered, order: .reverse)]
        )

        let items = (try? modelContext.fetch(descriptor)) ?? []

        if !items.isEmpty {
            let menuItems = items.map { MenuItem(name: $0.itemName, description: "ordered \($0.timesOrdered)x", price: $0.price) }
            let section = MenuSection(name: "previously ordered", items: menuItems)
            vm.loadMenu(sections: [section])
            nav.advance(.menuPicker)
        } else {
            vm.loadMenu(sections: [])
            nav.advance(.party)
        }
    }
}

// MARK: - Shared Flow Header

func flowHeader(title: String, step: String? = nil, onClose: @escaping () -> Void) -> some View {
    HStack {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BBColor.primaryText)
                .frame(width: 32, height: 32)
        }

        Spacer()

        VStack(spacing: 2) {
            Text(title)
                .font(BBFont.bodyBold)
                .foregroundStyle(BBColor.primaryText)
            if let step {
                Text(step)
                    .font(BBFont.small)
                    .foregroundStyle(BBColor.secondaryText)
            }
        }

        Spacer()

        Color.clear.frame(width: 32, height: 32)
    }
    .padding(.top, BBSpacing.sm)
}

#Preview {
    RestaurantSearchView()
        .environment(SplitFlowViewModel())
}
