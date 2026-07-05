import SwiftUI

enum Widget: String, CaseIterable, Codable {
    case clock, weather, music, timer, gif, quote, pet

    /// Widgets shown as draggable cards in the library. Timer is excluded
    /// because it needs a duration chosen in its own panel before dropping.
    static var libraryCases: [Widget] { [.clock, .weather, .music, .gif, .quote, .pet] }

    var displayName: String {
        switch self {
        case .clock:   "CLOCK"
        case .weather: "WEATHER"
        case .music:   "MUSIC"
        case .timer:   "TIMER"
        case .gif:     "GIF"
        case .quote:   "QUOTE"
        case .pet:     "PET"
        }
    }

    var tagline: String {
        switch self {
        case .clock:   "Time & date"
        case .weather: "Bangalore live"
        case .music:   "Now playing"
        case .timer:   "Countdown"
        case .gif:     "Animated scene"
        case .quote:   "Daily wisdom"
        case .pet:     "Feed me!"
        }
    }

    var accent: Color {
        switch self {
        case .clock:   Theme.amber
        case .weather: Theme.cool
        case .music:   Theme.pink
        case .timer:   Theme.green
        case .gif:     Theme.purple
        case .quote:   Theme.amber
        case .pet:     Theme.green
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
        case .timer:
            [[1,1,1,1,1,1,1,1],
             [0,1,1,1,1,1,1,0],
             [0,0,1,1,1,1,0,0],
             [0,0,0,1,1,0,0,0],
             [0,0,0,1,1,0,0,0],
             [0,0,1,1,1,1,0,0],
             [0,1,1,1,1,1,1,0],
             [1,1,1,1,1,1,1,1]]
        case .gif:
            [[1,1,0,0,0,0,1,1],
             [1,1,0,0,0,0,1,1],
             [0,0,1,0,0,0,0,0],
             [0,0,1,1,0,0,0,0],
             [0,0,1,1,1,0,0,0],
             [0,0,1,1,0,0,0,0],
             [0,0,1,0,0,0,0,0],
             [1,1,0,0,0,0,1,1]]
        case .quote:
            [[0,1,1,0,1,1,0,0],
             [0,1,1,0,1,1,0,0],
             [0,1,1,0,1,1,0,0],
             [0,0,1,0,0,1,0,0],
             [0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0],
             [0,0,0,0,0,0,0,0]]
        case .pet:
            [[0,1,0,0,0,0,1,0],
             [1,1,0,0,0,0,1,1],
             [0,0,0,0,0,0,0,0],
             [0,0,1,0,0,1,0,0],
             [0,1,1,0,0,1,1,0],
             [0,0,0,0,0,0,0,0],
             [0,0,1,1,1,1,0,0],
             [0,1,1,1,1,1,1,0]]
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
    var timerEnd1: Int = 0
    var timerEnd2: Int = 0
    var timerEnd3: Int = 0
    var prev1: String = ""
    var prev2: String = ""
    var prev3: String = ""

    enum CodingKeys: String, CodingKey {
        case screen1, screen2, screen3
        case powerState = "power_state"
        case gifUrl1 = "gif_url_1"
        case gifUrl2 = "gif_url_2"
        case gifUrl3 = "gif_url_3"
        case timerEnd1 = "timer_end_1"
        case timerEnd2 = "timer_end_2"
        case timerEnd3 = "timer_end_3"
        case prev1 = "prev_1"
        case prev2 = "prev_2"
        case prev3 = "prev_3"
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

    /// Absolute Unix end time (seconds) of the timer on a screen, 0 if none.
    func timerEnd(for screen: Int) -> Int {
        switch screen {
        case 1: timerEnd1
        case 2: timerEnd2
        case 3: timerEnd3
        default: 0
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
