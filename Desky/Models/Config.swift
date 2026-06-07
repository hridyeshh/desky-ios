import SwiftUI

enum Widget: String, CaseIterable, Codable {
    case clock, weather, music, tasks, gif

    var displayName: String {
        switch self {
        case .clock:   "CLOCK"
        case .weather: "WEATHER"
        case .music:   "MUSIC"
        case .tasks:   "TASKS"
        case .gif:     "GIF"
        }
    }

    var tagline: String {
        switch self {
        case .clock:   "Time & date"
        case .weather: "Bangalore live"
        case .music:   "Now playing"
        case .tasks:   "Your to-dos"
        case .gif:     "Animated scene"
        }
    }

    var accent: Color {
        switch self {
        case .clock:   Theme.amber
        case .weather: Theme.cool
        case .music:   Theme.pink
        case .tasks:   Theme.green
        case .gif:     Theme.purple
        }
    }

    // 8×8 pixel bitmap: 1 = accent, 2 = fg (#F2F2F2)
    var bitmap: [[Int]] {
        switch self {
        case .clock:
            [[0,0,1,1,1,1,0,0],
             [0,1,0,0,0,0,1,0],
             [0,1,0,0,1,0,1,0],
             [0,1,0,0,1,1,0,0],
             [0,1,0,0,0,0,1,0],
             [0,1,0,0,0,0,1,0],
             [0,0,1,1,1,1,0,0],
             [0,0,0,0,0,0,0,0]]
        case .weather:
            [[0,0,1,0,0,1,0,0],
             [0,0,0,0,0,0,0,0],
             [1,0,0,1,1,0,0,1],
             [0,0,1,1,1,1,0,0],
             [0,0,1,1,1,1,0,0],
             [1,0,0,1,1,0,0,1],
             [0,0,0,0,0,0,0,0],
             [0,0,1,0,0,1,0,0]]
        case .music:
            [[0,0,1,1,1,1,1,0],
             [0,0,1,0,0,0,1,0],
             [0,0,1,0,0,0,1,0],
             [0,0,1,0,0,0,1,0],
             [0,0,1,0,0,0,1,0],
             [1,1,1,0,0,1,1,0],
             [1,1,0,0,0,1,1,0],
             [0,0,0,0,0,0,0,0]]
        case .tasks:
            [[0,0,0,0,0,0,0,0],
             [1,1,0,2,2,2,2,0],
             [1,1,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0],
             [2,2,0,2,2,2,2,0],
             [2,2,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0]]
        case .gif:
            [[1,1,0,0,0,0,1,1],
             [1,1,0,0,0,0,1,1],
             [0,0,1,0,0,0,0,0],
             [0,0,1,1,0,0,0,0],
             [0,0,1,1,1,0,0,0],
             [0,0,1,1,0,0,0,0],
             [0,0,1,0,0,0,0,0],
             [1,1,0,0,0,0,1,1]]
        }
    }
}

struct Config: Codable {
    var screen1: String
    var screen2: String
    var screen3: String
    var powerState: String = "ON"
    var gifUrl1: String = ""
    var gifUrl2: String = ""
    var gifUrl3: String = ""

    enum CodingKeys: String, CodingKey {
        case screen1, screen2, screen3
        case powerState = "power_state"
        case gifUrl1 = "gif_url_1"
        case gifUrl2 = "gif_url_2"
        case gifUrl3 = "gif_url_3"
    }

    var isPoweredOn: Bool { powerState.uppercased() != "OFF" }

    func widget(for screen: Int) -> Widget? {
        switch screen {
        case 1: Widget(rawValue: screen1)
        case 2: Widget(rawValue: screen2)
        case 3: Widget(rawValue: screen3)
        default: nil
        }
    }

    func gifURL(for screen: Int) -> String {
        switch screen {
        case 1: gifUrl1
        case 2: gifUrl2
        case 3: gifUrl3
        default: ""
        }
    }

    mutating func set(_ widget: Widget, for screen: Int) {
        switch screen {
        case 1: screen1 = widget.rawValue
        case 2: screen2 = widget.rawValue
        case 3: screen3 = widget.rawValue
        default: break
        }
    }
}
