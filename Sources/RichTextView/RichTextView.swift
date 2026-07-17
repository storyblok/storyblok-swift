import SwiftUI
import StoryblokClient

/// Makes any ``StoryblokClient/RichText`` value renderable as a SwiftUI `View`.
///
/// The conformance is available whenever the rich text's `BlockLibrary` is itself a `View`, so
/// that embedded component blocks render alongside the standard rich-text nodes. Place a decoded
/// `RichText` value anywhere a `View` is expected:
///
/// ```swift
/// struct ArticleView: View {
///     let content: RichText<Content>
///
///     var body: some View {
///         ScrollView {
///             content   // rendered as native SwiftUI views
///                 .padding()
///         }
///     }
/// }
/// ```
///
/// Each node type has a built-in default renderer. Override individual node types with a
/// ``RichTextViewDelegate`` applied via ``RichTextView/SwiftUICore/View/richTextViewDelegate(_:)``, and handle
/// taps on internal story links with ``RichTextView/SwiftUICore/View/onStoryLink(_:)``.
extension RichText: View where BlockLibrary: View {
    public var body: some View {
        RichTextView(node: self)
    }
}

// Dispatch to concrete private view types. A separate struct avoids
// embedding the entire switch inside a property that cannot use `@ViewBuilder`
// directly on the conformance extension.
private struct RichTextView<BL: View & Decodable>: View {
    let node: RichText<BL>

    @Environment(\.richTextDelegate) private var delegate

    @ViewBuilder
    var body: some View {
        switch node {
        case .document(let d):
            if let custom = delegate?.viewForDocument(d) { custom }
            else { DocumentView(document: d) }
        case .heading(let h):
            if let custom = delegate?.viewForHeading(h) { custom }
            else { HeadingView(heading: h) }
        case .paragraph(let p):
            if let custom = delegate?.viewForParagraph(p) { custom }
            else { ParagraphView(paragraph: p) }
        case .bulletList(let l):
            if let custom = delegate?.viewForBulletList(l) { custom }
            else { BulletListView(list: l) }
        case .orderedList(let l):
            if let custom = delegate?.viewForOrderedList(l) { custom }
            else { OrderedListView(list: l) }
        case .listItem(let i):
            if let custom = delegate?.viewForListItem(i) { custom }
            else { ListItemContentView(item: i) }
        case .codeBlock(let c):
            if let custom = delegate?.viewForCodeBlock(c) { custom }
            else { CodeBlockView(codeBlock: c) }
        case .blockquote(let b):
            if let custom = delegate?.viewForBlockquote(b) { custom }
            else { BlockquoteView(blockquote: b) }
        case .horizontalRule:
            if let custom = delegate?.viewForHorizontalRule() { custom }
            else { Divider() }
        case .table(let t):
            if let custom = delegate?.viewForTable(t) { custom }
            else { TableView(table: t) }
        case .tableRow(let r):
            if let custom = delegate?.viewForTableRow(r) { custom }
            else { TableRowView(row: r) }
        case .tableHeader(let h):
            if let custom = delegate?.viewForTableHeader(h) { custom }
            else { TableHeaderCellView(header: h) }
        case .tableCell(let c):
            if let custom = delegate?.viewForTableCell(c) { custom }
            else { TableCellView(cell: c) }
        case .block(let b):
            if let custom = delegate?.viewForBlock(b) { custom }
            else { BlockView(block: b) }
        case .image(let i):
            if let custom = delegate?.viewForImage(i) { custom }
            else { ImageView(image: i) }
        case .text(let t):
            if let custom = delegate?.viewForText(t) { custom }
            else { Text(t.attributedString()) }
        case .emoji(let e):
            if let custom = delegate?.viewForEmoji(e) { custom }
            else { Text(verbatim: e.emoji) }
        case .hardBreak(let hb):
            if let custom = delegate?.viewForHardBreak(hb) { custom }
            else { Text(verbatim: "\n") }
        case .mark:
            EmptyView()
        case .unknown:
            EmptyView()
        }
    }
}

// MARK: - Document

struct DocumentView<BL: View & Decodable>: View {
    let document: RichText<BL>.Document

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(document.content.indices, id: \.self) { i in
                document.content[i]
            }
        }
    }
}


// MARK: - Block (embedded components)

struct BlockView<BL: View & Decodable>: View {
    let block: RichText<BL>.Block

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(block.body.indices, id: \.self) { i in
                block.body[i]
            }
        }
    }
}
