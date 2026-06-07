import Foundation
import Observation

/// Polls GET /api/status every 3 seconds and exposes a live connected flag,
/// driven by the Pi's heartbeat on the backend.
@Observable
@MainActor
final class ConnectivityViewModel {
    var isConnected = false
    var hasChecked = false

    private var pollingTask: Task<Void, Never>?

    /// Starts the 3-second polling loop. Safe to call repeatedly.
    func startPolling() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                if let status = try? await DeskAPI.fetchStatus() {
                    self?.isConnected = status.status == "connected"
                } else {
                    self?.isConnected = false
                }
                self?.hasChecked = true
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
