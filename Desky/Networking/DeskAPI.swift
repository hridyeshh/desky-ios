import Foundation

enum DeskAPI {
    static func fetchConfig() async throws -> Config {
        try await APIClient.get("/config")
    }

    static func updateConfig(screen: Int, widget: Widget) async throws -> Config {
        // Build full config payload — we only update one screen at a time,
        // so we read the current values from the server first.
        // The server returns the full updated Config after the PUT.
        struct Payload: Encodable {
            var screen1: String?
            var screen2: String?
            var screen3: String?
        }

        // Fetch current config so we preserve untouched screens
        let current = try await fetchConfig()

        var payload = Payload(
            screen1: current.screen1.isEmpty ? nil : current.screen1,
            screen2: current.screen2.isEmpty ? nil : current.screen2,
            screen3: current.screen3.isEmpty ? nil : current.screen3
        )

        switch screen {
        case 1: payload.screen1 = widget.rawValue
        case 2: payload.screen2 = widget.rawValue
        case 3: payload.screen3 = widget.rawValue
        default: break
        }

        let updated: Config = try await APIClient.put("/config", body: payload)
        return updated
    }

    // No dedicated /refresh endpoint — the Pi polls on its own schedule.
    // Calling fetchConfig() again is sufficient to get the latest state.
    static func forceRefresh() async throws {
        _ = try await fetchConfig()
    }

    // MARK: - Power

    static func setPower(_ state: String) async throws -> Config {
        struct Payload: Encodable { let state: String }
        return try await APIClient.post("/api/power", body: Payload(state: state))
    }

    // MARK: - Timer

    /// Starts a countdown on a screen for the given number of minutes.
    static func startTimer(screen: Int, minutes: Int) async throws -> Config {
        struct Payload: Encodable { let screen: Int; let minutes: Int }
        return try await APIClient.post("/api/timer", body: Payload(screen: screen, minutes: minutes))
    }

    // MARK: - Pet

    struct Pet: Decodable {
        let name: String
        let happiness: Int
        let state: String
        let hoursSinceFed: Int

        enum CodingKeys: String, CodingKey {
            case name, happiness, state
            case hoursSinceFed = "hours_since_fed"
        }
    }

    static func fetchPet() async throws -> Pet {
        try await APIClient.get("/widget/pet")
    }

    /// Feeds the pet: resets its hunger clock and bumps happiness.
    static func feedPet() async throws -> Pet {
        struct Empty: Encodable {}
        return try await APIClient.post("/widget/pet/feed", body: Empty())
    }

    // MARK: - Connectivity

    struct ConnectivityStatus: Decodable { let status: String }

    static func fetchStatus() async throws -> ConnectivityStatus {
        try await APIClient.get("/api/status")
    }

    // MARK: - GIF gallery

    struct UploadResult: Decodable { let url: String }

    /// Uploads GIF bytes to the backend (which forwards to Cloudinary) and
    /// returns the hosted URL.
    static func uploadGif(data: Data, fileName: String = "upload.gif") async throws -> String {
        let result: UploadResult = try await APIClient.uploadMultipart(
            "/api/upload-gif",
            fileData: data,
            fileName: fileName,
            mimeType: "image/gif"
        )
        return result.url
    }

    /// Assigns a GIF URL to a screen: sets the slot to "gif" and stores the URL.
    static func assignGif(url: String, screen: Int) async throws -> Config {
        struct Payload: Encodable {
            var screen1: String?
            var screen2: String?
            var screen3: String?
            var gif_url_1: String?
            var gif_url_2: String?
            var gif_url_3: String?
        }
        var payload = Payload()
        switch screen {
        case 1: payload.screen1 = "gif"; payload.gif_url_1 = url
        case 2: payload.screen2 = "gif"; payload.gif_url_2 = url
        case 3: payload.screen3 = "gif"; payload.gif_url_3 = url
        default: break
        }
        return try await APIClient.put("/config", body: payload)
    }
}
