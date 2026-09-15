import SwiftUI
import SwiftData
import FitnessTrackerPlanner

@main
struct fitness_trackerApp: App {
    @State private var appInitializer = AppInitializer()
    @State private var hasUserData: Bool?

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if let hasUserData {
                    if hasUserData {
                        EmptyView()
                    } else {
                        IntroductionScreen()
                    }
                } else {
                    ProgressView()
                }
            }
            .task {
                hasUserData = appInitializer.initialize()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
