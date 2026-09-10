import Foundation
import SwiftUI

/// Predefined commercial coloring palette with 18+ rich, vibrant colors
public struct ColorPalette {
    public static let colors: [Color] = [
        Color(hex: "E53935"), // Vibrant Red
        Color(hex: "FB8C00"), // Bright Orange
        Color(hex: "FDD835"), // Sunny Yellow
        Color(hex: "7CB342"), // Lime Green
        Color(hex: "43A047"), // Forest Green
        Color(hex: "00ACC1"), // Teal
        Color(hex: "1E88E5"), // Sky Blue
        Color(hex: "3949AB"), // Deep Indigo
        Color(hex: "8E24AA"), // Royal Purple
        Color(hex: "D81B60"), // Hot Pink
        Color(hex: "FF80AB"), // Pastel Pink
        Color(hex: "8D6E63"), // Warm Brown
        Color(hex: "5D4037"), // Dark Chocolate
        Color(hex: "78909C"), // Slate Blue
        Color(hex: "B0BEC5"), // Light Silver
        Color(hex: "455A64"), // Charcoal Gray
        Color(hex: "212121"), // Jet Black
        Color(hex: "FFFFFF")  // Pure White (Eraser)
    ]

    /// Default starting color
    public static let defaultColor: Color = Color(hex: "E53935")
}
