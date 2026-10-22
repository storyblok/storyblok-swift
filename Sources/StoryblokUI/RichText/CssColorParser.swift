import SwiftUI

enum CssColorParser {

    private static let namedColors: [String: Color] = [
        "black":       Color(red: 0,     green: 0,     blue: 0),
        "white":       Color(red: 1,     green: 1,     blue: 1),
        "red":         Color(red: 1,     green: 0,     blue: 0),
        "green":       Color(red: 0,     green: 1,     blue: 0),
        "blue":        Color(red: 0,     green: 0,     blue: 1),
        "gray":        Color(red: 0.502, green: 0.502, blue: 0.502),
        "grey":        Color(red: 0.502, green: 0.502, blue: 0.502),
        "yellow":      Color(red: 1,     green: 1,     blue: 0),
        "cyan":        Color(red: 0,     green: 1,     blue: 1),
        "magenta":     Color(red: 1,     green: 0,     blue: 1),
        "transparent": Color(red: 0,     green: 0,     blue: 0,   opacity: 0),
    ]

    static func parse(_ input: String?) -> Color? {
        guard let input, !input.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        let color = input.trimmingCharacters(in: .whitespaces).lowercased()

        if color.hasPrefix("#") { return parseHex(color) }
        if color.hasPrefix("rgba") { return parseRgba(color) }
        if color.hasPrefix("rgb") { return parseRgb(color) }
        return namedColors[color]
    }

    private static func parseHex(_ hex: String) -> Color? {
        guard hex.wholeMatch(of: /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/) != nil else { return nil }
        let clean = String(hex.dropFirst())
        switch clean.count {
        case 3:
            guard
                let r = UInt8(String(repeating: clean[clean.index(clean.startIndex, offsetBy: 0)], count: 2), radix: 16),
                let g = UInt8(String(repeating: clean[clean.index(clean.startIndex, offsetBy: 1)], count: 2), radix: 16),
                let b = UInt8(String(repeating: clean[clean.index(clean.startIndex, offsetBy: 2)], count: 2), radix: 16)
            else { return nil }
            return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
        case 6:
            guard
                let r = UInt8(clean.prefix(2), radix: 16),
                let g = UInt8(clean.dropFirst(2).prefix(2), radix: 16),
                let b = UInt8(clean.dropFirst(4).prefix(2), radix: 16)
            else { return nil }
            return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
        case 8:
            // Matches Kotlin behavior: 8-digit hex is ARGB (first two digits = alpha)
            guard
                let a = UInt8(clean.prefix(2), radix: 16),
                let r = UInt8(clean.dropFirst(2).prefix(2), radix: 16),
                let g = UInt8(clean.dropFirst(4).prefix(2), radix: 16),
                let b = UInt8(clean.dropFirst(6).prefix(2), radix: 16)
            else { return nil }
            return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
        default:
            return nil
        }
    }

    private static func parseRgb(_ rgb: String) -> Color? {
        guard let match = rgb.wholeMatch(of: /rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)/) else { return nil }
        guard
            let r = UInt8(match.1),
            let g = UInt8(match.2),
            let b = UInt8(match.3)
        else { return nil }
        return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }

    private static func parseRgba(_ rgba: String) -> Color? {
        guard let match = rgba.wholeMatch(of: /rgba\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*([0-9.]+)\s*\)/) else { return nil }
        guard
            let r = UInt8(match.1),
            let g = UInt8(match.2),
            let b = UInt8(match.3),
            let aRaw = Double(match.4)
        else { return nil }
        let alpha = min(aRaw > 1.0 ? aRaw / 255.0 : aRaw, 1.0)
        return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: alpha)
    }
}
