enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case nutrition
    case exercise

    var id: Self { self }
    var title: String { rawValue.uppercased() }
}
