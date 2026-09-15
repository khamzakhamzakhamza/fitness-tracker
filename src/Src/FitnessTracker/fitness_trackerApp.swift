import SwiftUI
import SwiftData
import FitnessTrackerPlanner

@main
struct fitness_trackerApp: App {
    @State private var appInitializer = AppInitializer()
    @State private var isInitialized = false

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
                if isInitialized {
                    PlanningRootView()
                } else {
                    ProgressView()
                }
            }
            .task {
                appInitializer.initialize()
                isInitialized = true
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
