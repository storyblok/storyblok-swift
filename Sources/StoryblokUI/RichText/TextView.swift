import SwiftUI
import StoryblokClient

private extension RichText.TextAlign {
    var textAlignment: TextAlignment {
        switch self {
        case .left:   .leading
        case .right:  .trailing
        case .center: .center
        }
    }

    var alignment: Alignment {
        switch self {
        case .left:   .leading
        case .right:  .trailing
        case .center: .center
        }
    }
}

// MARK: - Heading

struct HeadingView<BL: View & Decodable>: View {
    let heading: RichText<BL>.Heading

    var body: some View {
        Text(heading.attributedString(baseFont: heading.level.headingFont))
            .font(heading.level.headingFont)
            .frame(maxWidth: .infinity, alignment: heading.textAlign?.alignment ?? .leading)
            .multilineTextAlignment(heading.textAlign?.textAlignment ?? .leading)
    }
}

private extension Int {
    var headingFont: Font {
        switch self {
        case 1:  return .largeTitle
        case 2:  return .title
        case 3:  return .title2
        case 4:  return .title3
        case 5:  return .headline
        default: return .subheadline
        }
    }
}

// MARK: - Paragraph

struct ParagraphView<BL: View & Decodable>: View {
    let paragraph: RichText<BL>.Paragraph

    var body: some View {
        if paragraph.content.count == 1, case .image(let img) = paragraph.content[0] {
            ImageView<BL>(image: img)
        } else {
            Text(paragraph.attributedString())
                .frame(maxWidth: .infinity, alignment: paragraph.textAlign?.alignment ?? .leading)
                .multilineTextAlignment(paragraph.textAlign?.textAlignment ?? .leading)
        }
    }
}

// MARK: - Code Block

struct CodeBlockView<BL: View & Decodable>: View {
    let codeBlock: RichText<BL>.CodeBlock

    var body: some View {
        Text(codeBlock.attributedString())
            .font(.system(.body, design: .monospaced))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Blockquote

struct BlockquoteView<BL: View & Decodable>: View {
    let blockquote: RichText<BL>.Blockquote

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Color.secondary
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            VStack(alignment: .leading, spacing: 8) {
                ForEach(blockquote.content.indices, id: \.self) { i in
                    blockquote.content[i]
                }
            }
            .padding(.leading, 12)
        }
    }
}
