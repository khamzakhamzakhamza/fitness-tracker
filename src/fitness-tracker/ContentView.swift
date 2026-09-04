import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        VStack(spacing: 0) {
            Color.white

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
                        .foregroundStyle(selectedTab == tab ? Color.accentTeal : Color.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.title.capitalized)
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
            }
            .frame(height: 68)
            .background(Color.white)
        }
        .background(Color.white)
    }
}

private enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case nutrition
    case exercise

    var id: Self { self }
    var title: String { rawValue.uppercased() }

    @ViewBuilder
    var icon: some View {
        switch self {
        case .dashboard:
            Image(systemName: "house")
                .font(.system(size: 22, weight: .regular))
        case .nutrition:
            NutritionIcon()
        case .exercise:
            Image(systemName: "dumbbell")
                .font(.system(size: 22, weight: .regular))
        }
    }
}

private struct NutritionIcon: View {
    var body: some View {
        AppleShape()
            .stroke(
                style: StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .padding(1)
    }
}

private struct AppleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 24
        let scaleY = rect.height / 24

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * scaleX, y: y * scaleY)
        }

        var path = Path()
        path.move(to: point(12, 20.94))
        path.addCurve(
            to: point(16, 22),
            control1: point(13.5, 20.94),
            control2: point(14.75, 22)
        )
        path.addCurve(
            to: point(22, 9.78),
            control1: point(19, 22),
            control2: point(22, 14)
        )
        path.addCurve(
            to: point(17, 5),
            control1: point(22, 7.08),
            control2: point(19.8, 5)
        )
        path.addCurve(
            to: point(12, 7),
            control1: point(14.78, 5),
            control2: point(13, 6.44)
        )
        path.addCurve(
            to: point(7, 5),
            control1: point(11, 6.44),
            control2: point(9.22, 5)
        )
        path.addCurve(
            to: point(2, 9.78),
            control1: point(4.2, 5),
            control2: point(2, 7.08)
        )
        path.addCurve(
            to: point(8, 22),
            control1: point(2, 14),
            control2: point(5, 22)
        )
        path.addCurve(
            to: point(12, 20.94),
            control1: point(9.25, 22),
            control2: point(10.5, 20.94)
        )
        path.closeSubpath()

        path.move(to: point(10, 2))
        path.addCurve(
            to: point(12, 7),
            control1: point(11, 2.5),
            control2: point(12, 4)
        )

        return path
    }
}

private extension Color {
    static let accentTeal = Color(
        red: 14 / 255,
        green: 116 / 255,
        blue: 144 / 255
    )
}

#Preview {
    ContentView()
}
