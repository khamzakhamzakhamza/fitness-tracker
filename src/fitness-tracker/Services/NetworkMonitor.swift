import Combine
import Network

final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "FitnessTracker.NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied

            DispatchQueue.main.async {
                self?.isConnected = isConnected
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
