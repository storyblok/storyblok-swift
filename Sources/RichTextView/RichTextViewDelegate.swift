import SwiftUI
import StoryblokClient

// MARK: - Public protocol

/// A delegate that provides custom SwiftUI views for individual rich-text node types.
///
/// Conform to this protocol and install your delegate with
/// ``RichTextView/SwiftUICore/View/richTextViewDelegate(_:)`` to override the rendering of specific node types
/// while leaving all others at their built-in defaults.
///
/// Every requirement has a default implementation that matches the corresponding built-in
/// renderer, so you only implement the node types you want to change. Each method returns an
/// opaque `any View` and runs on the main actor. The delegate's `BlockLibrary` associated type
/// must match the ``StoryblokClient/RichText`` you are rendering.
///
/// ```swift
/// struct MyDelegate: RichTextViewDelegate {
///     typealias BlockLibrary = MyBlocks
///
///     @MainActor
///     func view(for heading: RichText<MyBlocks>.Heading) -> any View {
///         MyHeadingView(heading: heading)
///     }
/// }
///
/// ScrollView { richText }
///     .richTextViewDelegate(MyDelegate())
/// ```
///
/// > Note: ``viewForHorizontalRule()`` takes no node value because a horizontal rule carries no
/// > data; every other requirement receives the decoded node to render. Marks and unknown nodes
/// > have no delegate hook — marks are rendered inline as part of their containing text run.
public protocol RichTextViewDelegate<BlockLibrary> {
    associatedtype BlockLibrary: View & Decodable

    @MainActor func view(for document:    RichText<BlockLibrary>.Document)    -> any View
    @MainActor func view(for heading:     RichText<BlockLibrary>.Heading)     -> any View
    @MainActor func view(for paragraph:   RichText<BlockLibrary>.Paragraph)   -> any View
    @MainActor func view(for bulletList:  RichText<BlockLibrary>.BulletList)  -> any View
    @MainActor func view(for orderedList: RichText<BlockLibrary>.OrderedList) -> any View
    @MainActor func view(for listItem:    RichText<BlockLibrary>.ListItem)    -> any View
    @MainActor func view(for codeBlock:   RichText<BlockLibrary>.CodeBlock)   -> any View
    @MainActor func view(for blockquote:  RichText<BlockLibrary>.Blockquote)  -> any View
    @MainActor func view(for image:       RichText<BlockLibrary>.Image)       -> any View
    @MainActor func view(for table:       RichText<BlockLibrary>.Table)       -> any View
    @MainActor func view(for tableRow:    RichText<BlockLibrary>.TableRow)    -> any View
    @MainActor func view(for tableHeader: RichText<BlockLibrary>.TableHeader) -> any View
    @MainActor func view(for tableCell:   RichText<BlockLibrary>.TableCell)   -> any View
    @MainActor func view(for blok:        RichText<BlockLibrary>.Blok)        -> any View
    @MainActor func view(for text:        RichText<BlockLibrary>.Text)        -> any View
    @MainActor func view(for emoji:       RichText<BlockLibrary>.Emoji)       -> any View
    /// Called for `horizontalRule` nodes. Has no associated value; override to replace `Divider`.
    @MainActor func viewForHorizontalRule() -> any View
    @MainActor func view(for hardBreak: RichText<BlockLibrary>.HardBreak) -> any View
}

// MARK: - Default implementations (match built-in renderers exactly)

extension RichTextViewDelegate {
    @MainActor public func view(for document: RichText<BlockLibrary>.Document) -> any View {
        DocumentView(document: document)
    }
    @MainActor public func view(for heading: RichText<BlockLibrary>.Heading) -> any View {
        HeadingView(heading: heading)
    }
    @MainActor public func view(for paragraph: RichText<BlockLibrary>.Paragraph) -> any View {
        ParagraphView(paragraph: paragraph)
    }
    @MainActor public func view(for bulletList: RichText<BlockLibrary>.BulletList) -> any View {
        BulletListView(list: bulletList)
    }
    @MainActor public func view(for orderedList: RichText<BlockLibrary>.OrderedList) -> any View {
        OrderedListView(list: orderedList)
    }
    @MainActor public func view(for listItem: RichText<BlockLibrary>.ListItem) -> any View {
        ListItemContentView(item: listItem)
    }
    @MainActor public func view(for codeBlock: RichText<BlockLibrary>.CodeBlock) -> any View {
        CodeBlockView(codeBlock: codeBlock)
    }
    @MainActor public func view(for blockquote: RichText<BlockLibrary>.Blockquote) -> any View {
        BlockquoteView(blockquote: blockquote)
    }
    @MainActor public func view(for image: RichText<BlockLibrary>.Image) -> any View {
        ImageView(image: image)
    }
    @MainActor public func view(for table: RichText<BlockLibrary>.Table) -> any View {
        TableView(table: table)
    }
    @MainActor public func view(for tableRow: RichText<BlockLibrary>.TableRow) -> any View {
        TableRowView(row: tableRow)
    }
    @MainActor public func view(for tableHeader: RichText<BlockLibrary>.TableHeader) -> any View {
        TableHeaderCellView(header: tableHeader)
    }
    @MainActor public func view(for tableCell: RichText<BlockLibrary>.TableCell) -> any View {
        TableCellView(cell: tableCell)
    }
    @MainActor public func view(for blok: RichText<BlockLibrary>.Blok) -> any View {
        BlokView(blok: blok)
    }
    @MainActor public func view(for text: RichText<BlockLibrary>.Text) -> any View {
        Text(text.attributedString())
    }
    @MainActor public func view(for emoji: RichText<BlockLibrary>.Emoji) -> any View {
        Text(verbatim: emoji.emoji)
    }
    @MainActor public func viewForHorizontalRule() -> any View {
        Divider()
    }
    @MainActor public func view(for hardBreak: RichText<BlockLibrary>.HardBreak) -> any View {
        Text(verbatim: "\n")
    }
}

// MARK: - Existential → AnyView bridge
//
// `AnyView.init<V: View>(_ view: V)` requires a concrete V; it won't accept `any View`.
// Calling `.asAnyView()` through the witness table opens the existential at the call site,
// allowing the concrete method body to supply the right V to AnyView's generic init.
private extension View {
    func asAnyView() -> AnyView { AnyView(self) }
}

// MARK: - Type-erased environment storage
//
// `RichTextViewDelegate` has an associatedtype, so `any RichTextViewDelegate<BL>` cannot be
// stored in `EnvironmentValues` (which requires a concrete, non-generic value type).
// This struct erases `BlockLibrary` by capturing it inside `@MainActor` closures at init time.
// It is entirely internal — users never see or interact with it.
//
// `AnyView` wrapping is the only place `AnyView` appears in this feature; it happens here,
// not in user code.

struct RichTextDelegateStorage: @unchecked Sendable {
    let viewForDocument:    @MainActor (Any) -> AnyView?
    let viewForHeading:     @MainActor (Any) -> AnyView?
    let viewForParagraph:   @MainActor (Any) -> AnyView?
    let viewForBulletList:  @MainActor (Any) -> AnyView?
    let viewForOrderedList: @MainActor (Any) -> AnyView?
    let viewForListItem:    @MainActor (Any) -> AnyView?
    let viewForCodeBlock:   @MainActor (Any) -> AnyView?
    let viewForBlockquote:  @MainActor (Any) -> AnyView?
    let viewForImage:       @MainActor (Any) -> AnyView?
    let viewForTable:       @MainActor (Any) -> AnyView?
    let viewForTableRow:    @MainActor (Any) -> AnyView?
    let viewForTableHeader: @MainActor (Any) -> AnyView?
    let viewForTableCell:   @MainActor (Any) -> AnyView?
    let viewForBlok:        @MainActor (Any) -> AnyView?
    let viewForText:        @MainActor (Any) -> AnyView?
    let viewForEmoji:            @MainActor (Any) -> AnyView?
    let viewForHorizontalRule:   @MainActor () -> AnyView      // no associated value → non-optional
    let viewForHardBreak:        @MainActor (Any) -> AnyView?

    @MainActor init<D: RichTextViewDelegate>(_ d: D) {
        viewForDocument    = { @MainActor in ($0 as? RichText<D.BlockLibrary>.Document)    .map { d.view(for: $0).asAnyView() } }
        viewForHeading     = { @MainActor in ($0 as? RichText<D.BlockLibrary>.Heading)     .map { d.view(for: $0).asAnyView() } }
        viewForParagraph   = { @MainActor in ($0 as? RichText<D.BlockLibrary>.Paragraph)   .map { d.view(for: $0).asAnyView() } }
        viewForBulletList  = { @MainActor in ($0 as? RichText<D.BlockLibrary>.BulletList)  .map { d.view(for: $0).asAnyView() } }
        viewForOrderedList = { @MainActor in ($0 as? RichText<D.BlockLibrary>.OrderedList) .map { d.view(for: $0).asAnyView() } }
        viewForListItem    = { @MainActor in ($0 as? RichText<D.BlockLibrary>.ListItem)    .map { d.view(for: $0).asAnyView() } }
        viewForCodeBlock   = { @MainActor in ($0 as? RichText<D.BlockLibrary>.CodeBlock)   .map { d.view(for: $0).asAnyView() } }
        viewForBlockquote  = { @MainActor in ($0 as? RichText<D.BlockLibrary>.Blockquote)  .map { d.view(for: $0).asAnyView() } }
        viewForImage       = { @MainActor in ($0 as? RichText<D.BlockLibrary>.Image)       .map { d.view(for: $0).asAnyView() } }
        viewForTable       = { @MainActor in ($0 as? RichText<D.BlockLibrary>.Table)       .map { d.view(for: $0).asAnyView() } }
        viewForTableRow    = { @MainActor in ($0 as? RichText<D.BlockLibrary>.TableRow)    .map { d.view(for: $0).asAnyView() } }
        viewForTableHeader = { @MainActor in ($0 as? RichText<D.BlockLibrary>.TableHeader) .map { d.view(for: $0).asAnyView() } }
        viewForTableCell   = { @MainActor in ($0 as? RichText<D.BlockLibrary>.TableCell)   .map { d.view(for: $0).asAnyView() } }
        viewForBlok        = { @MainActor in ($0 as? RichText<D.BlockLibrary>.Blok)        .map { d.view(for: $0).asAnyView() } }
        viewForText        = { @MainActor in ($0 as? RichText<D.BlockLibrary>.Text)        .map { d.view(for: $0).asAnyView() } }
        viewForEmoji             = { @MainActor in ($0 as? RichText<D.BlockLibrary>.Emoji).map { d.view(for: $0).asAnyView() } }
        viewForHorizontalRule    = { @MainActor in d.viewForHorizontalRule().asAnyView() }
        viewForHardBreak         = { @MainActor in ($0 as? RichText<D.BlockLibrary>.HardBreak).map { d.view(for: $0).asAnyView() } }
    }
}

// MARK: - Environment plumbing

private struct RichTextDelegateKey: EnvironmentKey {
    static let defaultValue: RichTextDelegateStorage? = nil
}

extension EnvironmentValues {
    var richTextDelegate: RichTextDelegateStorage? {
        get { self[RichTextDelegateKey.self] }
        set { self[RichTextDelegateKey.self] = newValue }
    }
}

extension View {
    /// Installs a ``RichTextViewDelegate`` that overrides the SwiftUI views used to render
    /// individual rich-text node types within this view hierarchy.
    ///
    /// The delegate applies to every ``StoryblokClient/RichText`` rendered by descendants. Node
    /// types the delegate does not implement keep their built-in default rendering.
    ///
    /// ```swift
    /// ScrollView { article.content }
    ///     .richTextViewDelegate(MyDelegate())
    /// ```
    ///
    /// - Parameter delegate: The delegate supplying custom node views. Its `BlockLibrary` must
    ///   match the rich text being rendered.
    public func richTextViewDelegate<D: RichTextViewDelegate>(_ delegate: D) -> some View {
        environment(\.richTextDelegate, RichTextDelegateStorage(delegate))
    }
}
