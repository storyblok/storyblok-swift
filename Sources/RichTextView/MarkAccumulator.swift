import SwiftUI
import StoryblokClient

// MARK: - Composite inline rendering

extension RichTextComposite {
    func attributedString(baseFont: Font = .body) -> AttributedString {
        content.reduce(AttributedString()) { $0 + $1.inlineAttributedString(baseFont: baseFont) }
    }
}

extension RichText {
    func inlineAttributedString(baseFont: Font = .body) -> AttributedString {
        switch self {
        case .text(let t):       return t.attributedString(baseFont: baseFont)
        case .hardBreak:         return AttributedString("\n")
        case .emoji(let e):      return AttributedString(e.emoji)
        case .image(let img):    return AttributedString(img.alt ?? "")
        case .paragraph(let p):  return p.attributedString(baseFont: baseFont)
        default:                 return AttributedString()
        }
    }
}

// MARK: - Text node → AttributedString

extension RichText.Text {
    func attributedString(baseFont: Font = .body) -> AttributedString {
        var acc = MarkAccumulator()
        for mark in marks { acc.apply(mark) }
        return acc.build(text: text, baseFont: baseFont)
    }
}

// MARK: - Mark accumulator

// Accumulates all marks on a text run into a single attribute set,
// then applies them in one pass. This avoids the problem of each mark
// overwriting the previous when setting `font` (bold after italic → loses italic).
private struct MarkAccumulator {
    var isBold = false
    var isItalic = false
    var isCode = false
    var isUnderline = false
    var isStrike = false
    var isSubscript = false
    var isSuperscript = false
    var foregroundColor: Color? = nil
    var backgroundColor: Color? = nil
    var linkURL: URL? = nil

    mutating func apply<BL: Decodable>(_ mark: RichText<BL>.Mark) {
        switch mark {
        case .bold:                    isBold = true
        case .italic:                  isItalic = true
        case .underline:               isUnderline = true
        case .strike:                  isStrike = true
        case .code:                    isCode = true
        case .subscript:               isSubscript = true
        case .superscript:             isSuperscript = true
        case .textStyle(let color):    foregroundColor = CssColorParser.parse(color)
        case .highlight(let color):    backgroundColor = CssColorParser.parse(color)
        case .link(let l):             linkURL = makeURL(l)
        case .unknown:                 break
        }
    }

    private func makeURL<BL: Decodable>(_ link: RichText<BL>.Mark.Link) -> URL? {
        switch link.linkType {
        case "email":
            return URL(string: "mailto:\(link.href)")
        case "story":
            guard let uuid = link.uuid else { return URL(string: link.href) }
            var components = URLComponents()
            components.scheme = "storyblok-story"
            components.host = uuid
            if let anchor = link.anchor, !anchor.isEmpty {
                components.queryItems = [URLQueryItem(name: "anchor", value: anchor)]
            }
            return components.url
        default:
            return URL(string: link.href)
        }
    }

    func font(base: Font = .body) -> Font? {
        guard isBold || isItalic || isCode || isSubscript || isSuperscript else { return nil }
        if isSubscript || isSuperscript { return .caption }
        var f: Font = isCode ? .system(.body, design: .monospaced) : base
        if isBold   { f = f.bold() }
        if isItalic { f = f.italic() }
        return f
    }

    func build(text: String, baseFont: Font = .body) -> AttributedString {
        var str = AttributedString(text)
        let range = str.startIndex..<str.endIndex
        if let f = font(base: baseFont) { str[range].font = f }
        if isUnderline   { str[range].underlineStyle = Text.LineStyle(pattern: .solid) }
        if isStrike      { str[range].strikethroughStyle = Text.LineStyle(pattern: .solid) }
        if isCode        { str[range].backgroundColor = Color.secondary.opacity(0.15) }
        if isSubscript   { str[range].baselineOffset = -4 }
        if isSuperscript { str[range].baselineOffset = 6 }
        if let c = foregroundColor { str[range].foregroundColor = c }
        if let c = backgroundColor, !isCode { str[range].backgroundColor = c }
        if let u = linkURL { str[range].link = u }
        return str
    }
}
