import Foundation
import UIKit
import Observation

enum LoadState {
    case idle
    case loading
    case loaded(Config)
    case error(String)
}

@Observable
@MainActor
class DeskViewModel {

    var loadState: LoadState = .idle
    var isConnected: Bool = false
    var lastSyncText: String = "--"

    // Power state ("ON" | "OFF"), mirrored from the loaded config.
    var powerState: String = "ON"
    var isPoweredOn: Bool { powerState.uppercased() != "OFF" }
    private var isTogglingPower = false

    // Uploaded GIF URLs (Cloudinary-hosted), newest first.
    var uploadedGifs: [String] = []
    var isUploading = false

    var isLoading: Bool {
        switch loadState {
        case .idle, .loading: return true
        case .loaded, .error: return false
        }
    }

    // Success toast
    var successScreen: Int? = nil

    private var syncTimer: Timer?

    // MARK: - Load

    func load() async {
        loadState = .loading
        do {
            let config = try await DeskAPI.fetchConfig()
            loadState = .loaded(config)
            powerState = config.powerState
            isConnected = true
            updateSyncLabel()
            startSyncTimer()
        } catch {
            loadState = .error(error.localizedDescription)
            isConnected = false
        }
    }

    // MARK: - Refresh

    func refresh() async {
        do {
            try await DeskAPI.forceRefresh()
            await load()
        } catch {
            // If force-refresh fails, still try to reload
            await load()
        }
    }

    // MARK: - Drop (drag-and-drop)

    func drop(widget: Widget, onto screen: Int) async {
        do {
            let updated = try await DeskAPI.updateConfig(screen: screen, widget: widget)
            loadState = .loaded(updated)
            isConnected = true
            updateSyncLabel()

            // Show success badge/toast for 2 seconds
            successScreen = screen
            try? await Task.sleep(for: .seconds(2))
            successScreen = nil
        } catch {
            // Surface error without wiping the current state
            isConnected = false
        }
    }

    // MARK: - Power

    /// Toggles the global display power state with optimistic UI update.
    func togglePower() async {
        guard !isTogglingPower else { return }
        isTogglingPower = true
        defer { isTogglingPower = false }

        let next = isPoweredOn ? "OFF" : "ON"
        let previous = powerState
        powerState = next // optimistic
        do {
            let updated = try await DeskAPI.setPower(next)
            powerState = updated.powerState
            loadState = .loaded(updated)
        } catch {
            powerState = previous // revert on failure
        }
    }

    // MARK: - Quote shuffle

    /// True while a shuffle network call is in-flight (disables the button).
    var isShufflingQuote = false

    /// Busts the server-side quote cache so the Pi display immediately shows a
    /// brand-new random quote instead of waiting up to 24 hours. Provides a
    /// subtle haptic kick on success.
    func shuffleCurrentQuote() async {
        guard !isShufflingQuote else { return }
        isShufflingQuote = true
        defer { isShufflingQuote = false }

        do {
            _ = try await DeskAPI.shuffleQuote()
            // Light haptic: confirms the shuffle went through without being
            // intrusive (the screen update itself is the real confirmation).
            await MainActor.run {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } catch {
            // Notify the user something went wrong.
            await MainActor.run {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    // MARK: - GIF gallery

    /// Uploads GIF bytes and appends the hosted URL to the gallery.
    func uploadGif(data: Data) async {
        isUploading = true
        defer { isUploading = false }
        do {
            let url = try await DeskAPI.uploadGif(data: data)
            if !uploadedGifs.contains(url) {
                uploadedGifs.insert(url, at: 0)
            }
        } catch {
            // Upload failed; leave gallery unchanged.
        }
    }

    /// Removes a GIF from the gallery list (local only; does not unassign it
    /// from any screen already using it).
    func removeGif(url: String) {
        uploadedGifs.removeAll { $0 == url }
    }

    /// Assigns an uploaded GIF to a screen slot.
    func assignGif(url: String, screen: Int) async {
        do {
            let updated = try await DeskAPI.assignGif(url: url, screen: screen)
            loadState = .loaded(updated)
            isConnected = true
            updateSyncLabel()

            successScreen = screen
            try? await Task.sleep(for: .seconds(2))
            successScreen = nil
        } catch {
            isConnected = false
        }
    }

    // MARK: - Timer

    /// Starts a countdown on a screen slot for the given minutes.
    func startTimer(screen: Int, minutes: Int) async {
        do {
            let updated = try await DeskAPI.startTimer(screen: screen, minutes: minutes)
            loadState = .loaded(updated)
            isConnected = true
            updateSyncLabel()

            successScreen = screen
            try? await Task.sleep(for: .seconds(2))
            successScreen = nil
        } catch {
            isConnected = false
        }
    }

    // MARK: - Sync label helpers

    private func updateSyncLabel() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        lastSyncText = formatter.string(from: Date())
    }

    func tickSyncLabel() {
        updateSyncLabel()
    }

    private func startSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickSyncLabel()
            }
        }
    }
}
