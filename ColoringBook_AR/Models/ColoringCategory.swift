import Foundation
import SwiftUI

/// UI presentation model for category cards on HomeScreen
public struct ColoringCategory: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let count: Int
    public let systemIcon: String
    public let gradientColors: [Color]
    public let accentColor: Color

    public init(
        id: String,
        title: String,
        count: Int,
        systemIcon: String,
        gradientColors: [Color],
        accentColor: Color
    ) {
        self.id = id
        self.title = title
        self.count = count
        self.systemIcon = systemIcon
        self.gradientColors = gradientColors
        self.accentColor = accentColor
    }

    /// Standard factory mapping category ID from index.json to styled category
    public static func make(id: String, count: Int) -> ColoringCategory {
        switch id {
        case "magic_fantasy":
            return ColoringCategory(
                id: id,
                title: "Magic & Fantasy",
                count: count,
                systemIcon: "sparkles",
                gradientColors: [Color(hex: "8A2387"), Color(hex: "E94057"), Color(hex: "F27121")],
                accentColor: Color(hex: "E94057")
            )
        case "animals_creatures":
            return ColoringCategory(
                id: id,
                title: "Animals & Creatures",
                count: count,
                systemIcon: "pawprint.fill",
                gradientColors: [Color(hex: "FF9A9E"), Color(hex: "FECFEF")],
                accentColor: Color(hex: "FF6B8B")
            )
        case "fantasy_landscapes":
            return ColoringCategory(
                id: id,
                title: "Fantasy & Landscapes",
                count: count,
                systemIcon: "mountain.2.fill",
                gradientColors: [Color(hex: "84FAB0"), Color(hex: "8FD3F4")],
                accentColor: Color(hex: "48C6EF")
            )
        case "holidays_festivals":
            return ColoringCategory(
                id: id,
                title: "Holidays & Festivals",
                count: count,
                systemIcon: "gift.fill",
                gradientColors: [Color(hex: "FCCB90"), Color(hex: "D57EEB")],
                accentColor: Color(hex: "F77737")
            )
        case "mandala_patterns":
            return ColoringCategory(
                id: id,
                title: "Mandalas & Patterns",
                count: count,
                systemIcon: "circle.hexagongrid.circle.fill",
                gradientColors: [Color(hex: "A18CD1"), Color(hex: "FBC2EB")],
                accentColor: Color(hex: "8E2DE2")
            )
        case "unicorns_horses":
            return ColoringCategory(
                id: id,
                title: "Unicorns & Horses",
                count: count,
                systemIcon: "star.fill",
                gradientColors: [Color(hex: "E0C3FC"), Color(hex: "8EC5FC")],
                accentColor: Color(hex: "9B51E0")
            )
        case "characters_princesses":
            return ColoringCategory(
                id: id,
                title: "Princesses & Heroes",
                count: count,
                systemIcon: "crown.fill",
                gradientColors: [Color(hex: "FFB199"), Color(hex: "FF0844")],
                accentColor: Color(hex: "FF0844")
            )
        case "vehicles":
            return ColoringCategory(
                id: id,
                title: "Vehicles",
                count: count,
                systemIcon: "car.fill",
                gradientColors: [Color(hex: "4FACFE"), Color(hex: "00F2FE")],
                accentColor: Color(hex: "0072FF")
            )
        case "nature_plants":
            return ColoringCategory(
                id: id,
                title: "Nature & Plants",
                count: count,
                systemIcon: "leaf.fill",
                gradientColors: [Color(hex: "43E97B"), Color(hex: "38F9D7")],
                accentColor: Color(hex: "11998E")
            )
        default:
            let formattedTitle = id.replacingOccurrences(of: "_", with: " ").capitalized
            return ColoringCategory(
                id: id,
                title: formattedTitle,
                count: count,
                systemIcon: "paintpalette.fill",
                gradientColors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                accentColor: Color(hex: "667EEA")
            )
        }
    }
}

// Color Hex Extension
public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
