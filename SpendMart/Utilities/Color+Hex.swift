import SwiftUI

public extension Color {
    /// Single, project-wide hex initializer. Example: Color(hex: "#8790A5")
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }

        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// App palette
    static let appBrand        = Color.blue              // iOS-like blue
    static let appSecondaryTxt = Color(hex: "#8790A5")

    /// Soft, iOS-friendly tile colors
    static let tilePaletteHex: [String] = [
        "#4F46E5", "#22C55E", "#EF4444", "#F59E0B",
        "#06B6D4", "#A855F7", "#DB2777", "#0EA5E9"
    ]
}
