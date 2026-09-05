import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        VStack(spacing: 0) {
            switch selectedTab {
            case .nutrition:
                NutritionScreen()
            case .dashboard, .exercise:
                Color("AppBackground")
            }

            Divider()

            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 5) {
                            tab.icon
                                .frame(width: 24, height: 24)

                            Text(tab.title)
                                .font(.system(size: 8, weight: .black))
                                .tracking(0.3)
                        }
                        .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.title.capitalized)
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
            }
            .frame(height: 68)
            .background(Color("AppBackground"))
        }
        .background(Color("AppBackground"))
    }
}

#Preview {
    ContentView()
}
