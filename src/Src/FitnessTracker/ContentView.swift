import SwiftUI
import FitnessTrackerShared

struct ContentView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            SearchBox(
                text: $searchText,
                placeholder: "Search"
            )
        }
    }
}

#Preview {
    ContentView()
}
