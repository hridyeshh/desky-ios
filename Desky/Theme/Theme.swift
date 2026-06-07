import SwiftUI

enum Theme {
    static let bg = Color(hex: "0A0A0A")
    static let card = Color(hex: "111111")
    static let bg3 = Color(hex: "181818")
    static let fg = Color(hex: "F2F2F2")
    static let muted = Color(hex: "6B6B6B")
    static let dim = Color(hex: "3A3A3A")
    static let line = Color(hex: "222222")
    static let amber = Color(hex: "E8C97A")
    static let cool = Color(hex: "7AC8E8")
    static let pink = Color(hex: "FC3C44")
    static let green = Color(hex: "5BD17A")
    static let purple = Color(hex: "A47AE8")
}

extension Font {
    static func pressStart(_ size: CGFloat) -> Font {
        .custom("Press Start 2P", size: size)
    }

    static func vt323(_ size: CGFloat) -> Font {
        .custom("VT323", size: size)
    }
}

extension Color {
    init(hex: String) {
        var int: UInt64 = 0
        Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
            .scanHexInt64(&int)
        self.init(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255
        )
    }
}
