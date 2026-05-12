import Foundation

/// Storyblok rich text nodes.
///
/// Represents the hierarchical structure of rich text content from the Storyblok editor. The
/// value of the `type` JSON field is used to dispatch to the corresponding case.
public indirect enum RichText: Decodable {

    /// Root document node containing all rich text content.
    case document(Document)

    /// Heading node with configurable level (1-6).
    case heading(Heading)

    /// Unordered (bullet) list node.
    case bulletList(BulletList)

    /// Ordered (numbered) list node.
    case orderedList(OrderedList)

    /// Image node with source and metadata.
    case image(Image)

    /// Code block node with optional language hint.
    case codeBlock(CodeBlock)

    /// Block quote node.
    case blockquote(Blockquote)

    /// Horizontal rule (divider) node.
    case horizontalRule

    /// Table container node.
    case table(Table)

    /// Table row node.
    case tableRow(TableRow)

    /// Table header cell.
    case tableHeader(TableHeader)

    /// Table data cell.
    case tableCell(TableCell)

    /// Paragraph node with optional text alignment.
    case paragraph(Paragraph)

    /// List item node.
    case listItem(ListItem)

    /// Text node containing plain text with optional marks (formatting).
    case text(Text)

    /// A text formatting mark applied inline to text content.
    case mark(Mark)

    /// Embedded component block within rich text.
    case blok(Blok)

    /// Emoji node with fallback image support.
    case emoji(Emoji)

    /// Hard line break node.
    case hardBreak(HardBreak)

    /// A node with a type not known to this client.
    case unknown(type: String)

    /// Technical name of the node type (the value of the `type` JSON field).
    public var type: String {
        switch self {
            case .document: return "doc"
            case .heading: return "heading"
            case .bulletList: return "bullet_list"
            case .orderedList: return "ordered_list"
            case .image: return "image"
            case .codeBlock: return "code_block"
            case .blockquote: return "blockquote"
            case .horizontalRule: return "horizontal_rule"
            case .table: return "table"
            case .tableRow: return "table_row"
            case .tableHeader: return "tableHeader"
            case .tableCell: return "tableCell"
            case .paragraph: return "paragraph"
            case .listItem: return "list_item"
            case .text: return "text"
            case .mark(let mark): return mark.type
            case .blok: return "blok"
            case .emoji: return "emoji"
            case .hardBreak: return "hard_break"
            case .unknown(let type): return type
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        switch type {
            case "doc": self = .document(try Document(from: decoder))
            case "heading": self = .heading(try Heading(from: decoder))
            case "bullet_list": self = .bulletList(try BulletList(from: decoder))
            case "ordered_list": self = .orderedList(try OrderedList(from: decoder))
            case "image": self = .image(try Image(from: decoder))
            case "code_block": self = .codeBlock(try CodeBlock(from: decoder))
            case "blockquote": self = .blockquote(try Blockquote(from: decoder))
            case "horizontal_rule": self = .horizontalRule
            case "table": self = .table(try Table(from: decoder))
            case "table_row": self = .tableRow(try TableRow(from: decoder))
            case "tableHeader": self = .tableHeader(try TableHeader(from: decoder))
            case "tableCell": self = .tableCell(try TableCell(from: decoder))
            case "paragraph": self = .paragraph(try Paragraph(from: decoder))
            case "list_item": self = .listItem(try ListItem(from: decoder))
            case "text": self = .text(try Text(from: decoder))
            case "bold", "italic", "underline", "strike", "code", "subscript", "superscript", "link", "textStyle", "highlight":
                self = .mark(try Mark(from: decoder))
            case "blok": self = .blok(try Blok(from: decoder))
            case "emoji": self = .emoji(try Emoji(from: decoder))
            case "hard_break": self = .hardBreak(try HardBreak(from: decoder))
            default: self = .unknown(type: type)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }

    /// Text alignment options for paragraph and heading nodes.
    public enum TextAlign: String, Decodable {
        /// Left-aligned text.
        case left
        /// Right-aligned text.
        case right
        /// Center-aligned text.
        case center
    }

    /// A rich text node that contains child nodes.
    public protocol Composite {
        /// Child nodes contained within this element.
        var content: [RichText] { get }
    }

    /// Root document node containing all rich text content.
    public struct Document: Decodable, Composite {
        public let content: [RichText]
    }

    /// Heading node with configurable level (1-6).
    public struct Heading: Decodable, Composite {
        /// Heading level (1-6).
        public let level: Int
        /// Optional text alignment.
        public let textAlign: TextAlign?
        /// Child nodes contained within this element.
        public let content: [RichText]

        private struct Attributes: Decodable {
            let level: Int
            let textAlign: TextAlign?
        }

        private enum CodingKeys: String, CodingKey {
            case attrs
            case content
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let attributes = try container.decode(Attributes.self, forKey: .attrs)
            self.level = attributes.level
            self.textAlign = attributes.textAlign
            self.content = try container.decodeIfPresent([RichText].self, forKey: .content) ?? []
        }
    }

    /// Unordered (bullet) list node.
    public struct BulletList: Decodable, Composite {
        public let content: [RichText]
    }

    /// Ordered (numbered) list node.
    public struct OrderedList: Decodable, Composite {
        /// Starting number for the list.
        public let order: Int?
        /// Child nodes contained within this element.
        public let content: [RichText]

        private struct Attributes: Decodable {
            let order: Int?
        }

        private enum CodingKeys: String, CodingKey {
            case attrs
            case content
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.order = try container.decodeIfPresent(Attributes.self, forKey: .attrs)?.order
            self.content = try container.decodeIfPresent([RichText].self, forKey: .content) ?? []
        }
    }

    /// List item node.
    public struct ListItem: Decodable, Composite {
        public let content: [RichText]
    }

    /// Image node with source and metadata.
    public struct Image: Decodable {
        /// Unique identifier for the image.
        public let id: String
        /// Image source URL.
        public let src: String
        /// Alternative text for accessibility.
        public let alt: String?
        /// Image title.
        public let title: String?
        /// Source or origin of the image.
        public let source: String?
        /// Copyright information.
        public let copyright: String?
        /// Custom metadata key-value pairs.
        public let metadata: [String: String]?

        private struct Attributes: Decodable {
            let id: String
            let src: String
            let alt: String?
            let title: String?
            let source: String?
            let copyright: String?
            let metadata: [String: String]?

            private enum CodingKeys: String, CodingKey {
                case id, src, alt, title, source, copyright
                case metadata = "meta_data"
            }
        }

        private enum CodingKeys: String, CodingKey {
            case attrs
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let attributes = try container.decode(Attributes.self, forKey: .attrs)
            self.id = attributes.id
            self.src = attributes.src
            self.alt = attributes.alt
            self.title = attributes.title
            self.source = attributes.source
            self.copyright = attributes.copyright
            self.metadata = attributes.metadata
        }
    }

    /// Code block node with optional language hint.
    public struct CodeBlock: Decodable, Composite {
        /// Programming language for syntax highlighting.
        public let language: String?
        /// CSS class name.
        public let cssClass: String?
        /// Child nodes contained within this element.
        public let content: [RichText]

        private struct Attributes: Decodable {
            let language: String?
            let cssClass: String?

            private enum CodingKeys: String, CodingKey {
                case language
                case cssClass = "class"
            }
        }

        private enum CodingKeys: String, CodingKey {
            case attrs
            case content
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let attributes = try container.decodeIfPresent(Attributes.self, forKey: .attrs)
            self.language = attributes?.language
            self.cssClass = attributes?.cssClass
            self.content = try container.decodeIfPresent([RichText].self, forKey: .content) ?? []
        }
    }

    /// Block quote node.
    public struct Blockquote: Decodable, Composite {
        public let content: [RichText]
    }

    /// Table container node.
    public struct Table: Decodable, Composite {
        public let content: [RichText]
    }

    /// Table row node.
    public struct TableRow: Decodable, Composite {
        public let content: [RichText]
    }

    /// Table header cell.
    public struct TableHeader: Decodable {
        /// Number of columns this cell spans.
        public let columnSpan: Int?
        /// Number of rows this cell spans.
        public let rowSpan: Int?
        /// Column width values in pixels.
        public let columnWidth: [Int]?

        private struct Attributes: Decodable {
            let colspan: Int?
            let rowspan: Int?
            let colwidth: [Int]?
        }

        private enum CodingKeys: String, CodingKey {
            case attrs
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let attributes = try container.decodeIfPresent(Attributes.self, forKey: .attrs)
            self.columnSpan = attributes?.colspan
            self.rowSpan = attributes?.rowspan
            self.columnWidth = attributes?.colwidth
        }
    }

    /// Table data cell.
    public struct TableCell: Decodable {
        /// Number of columns this cell spans.
        public let columnSpan: Int?
        /// Number of rows this cell spans.
        public let rowSpan: Int?
        /// Column width values in pixels.
        public let columnWidth: [Int]?
        /// Background color of the cell.
        public let backgroundColor: String?

        private struct Attributes: Decodable {
            let colspan: Int?
            let rowspan: Int?
            let colwidth: [Int]?
            let backgroundColor: String?
        }

        private enum CodingKeys: String, CodingKey {
            case attrs
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let attributes = try container.decodeIfPresent(Attributes.self, forKey: .attrs)
            self.columnSpan = attributes?.colspan
            self.rowSpan = attributes?.rowspan
            self.columnWidth = attributes?.colwidth
            self.backgroundColor = attributes?.backgroundColor
        }
    }

    /// Paragraph node with optional text alignment.
    public struct Paragraph: Decodable, Composite {
        /// Optional text alignment.
        public let textAlign: TextAlign?
        /// Child nodes contained within this element.
        public let content: [RichText]

        private struct Attributes: Decodable {
            let textAlign: TextAlign?
        }

        private enum CodingKeys: String, CodingKey {
            case attrs
            case content
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.textAlign = try container.decodeIfPresent(Attributes.self, forKey: .attrs)?.textAlign
            self.content = try container.decodeIfPresent([RichText].self, forKey: .content) ?? []
        }
    }

    /// Text node containing plain text with optional marks (formatting).
    public struct Text: Decodable {
        /// The text content.
        public let text: String
        /// Applied formatting marks.
        public let marks: [Mark]

        private enum CodingKeys: String, CodingKey {
            case text
            case marks
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
            self.marks = try container.decodeIfPresent([Mark].self, forKey: .marks) ?? []
        }
    }

    /// A text formatting mark applied inline to text content.
    public enum Mark: Decodable {
        /// Bold text formatting.
        case bold
        /// Italic text formatting.
        case italic
        /// Underlined text formatting.
        case underline
        /// Strikethrough text formatting.
        case strike
        /// Inline code formatting.
        case code
        /// Subscript text formatting.
        case `subscript`
        /// Superscript text formatting.
        case superscript
        /// Hyperlink mark with URL and metadata.
        case link(Link)
        /// Text color styling.
        case textStyle(color: String?)
        /// Text highlight/background color.
        case highlight(color: String?)
        /// A mark with a type not known to this client.
        case unknown(type: String)

        /// Technical name of the mark type (the value of the `type` JSON field).
        public var type: String {
            switch self {
                case .bold: return "bold"
                case .italic: return "italic"
                case .underline: return "underline"
                case .strike: return "strike"
                case .code: return "code"
                case .subscript: return "subscript"
                case .superscript: return "superscript"
                case .link: return "link"
                case .textStyle: return "textStyle"
                case .highlight: return "highlight"
                case .unknown(let type): return type
            }
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
            switch type {
                case "bold": self = .bold
                case "italic": self = .italic
                case "underline": self = .underline
                case "strike": self = .strike
                case "code": self = .code
                case "subscript": self = .subscript
                case "superscript": self = .superscript
                case "link": self = .link(try Link(from: decoder))
                case "textStyle":
                    let color = try container.decodeIfPresent(ColorAttributes.self, forKey: .attrs)?.color
                    self = .textStyle(color: color?.isEmpty == false ? color : nil)
                case "highlight":
                    let color = try container.decodeIfPresent(ColorAttributes.self, forKey: .attrs)?.color
                    self = .highlight(color: color?.isEmpty == false ? color : nil)
                default: self = .unknown(type: type)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case attrs
        }

        private struct ColorAttributes: Decodable {
            let color: String?
        }

        /// Hyperlink mark with URL and metadata.
        public struct Link: Decodable {
            /// Link destination URL.
            public let href: String
            /// UUID of linked story (for internal links).
            public let uuid: String?
            /// Anchor fragment within the target.
            public let anchor: String?
            /// Custom attributes.
            public let custom: [String: String]?
            /// Link target attribute.
            public let target: String?
            /// Type of link.
            public let linkType: String

            private struct Attributes: Decodable {
                let href: String
                let uuid: String?
                let anchor: String?
                let custom: [String: String]?
                let target: String?
                let linktype: String
            }

            private enum CodingKeys: String, CodingKey {
                case attrs
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let attributes = try container.decode(Attributes.self, forKey: .attrs)
                self.href = attributes.href
                self.uuid = attributes.uuid
                self.anchor = attributes.anchor
                self.custom = attributes.custom
                self.target = attributes.target
                self.linkType = attributes.linktype
            }
        }
    }

    /// Embedded component block within rich text.
    public struct Blok: Decodable {
        /// List of embedded components.
        public let body: [Decodable & Sendable]

        private struct Attributes: Decodable {
            let id: String
            let body: [String]
        }

        private enum CodingKeys: String, CodingKey {
            case attrs
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let attributes = try container.decode(Attributes.self, forKey: .attrs)
            self.body = attributes.body
        }
    }

    /// Emoji node with fallback image support.
    public struct Emoji: Decodable {
        /// Emoji name/identifier.
        public let name: String
        /// Unicode emoji character.
        public let emoji: String
        /// Fallback image URL for unsupported emoji.
        public let fallbackImage: String

        private struct Attributes: Decodable {
            let name: String
            let emoji: String
            let fallbackImage: String
        }

        private enum CodingKeys: String, CodingKey {
            case attrs
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let attributes = try container.decode(Attributes.self, forKey: .attrs)
            self.name = attributes.name
            self.emoji = attributes.emoji
            self.fallbackImage = attributes.fallbackImage
        }
    }

    /// Hard line break node.
    public struct HardBreak: Decodable {
        /// Applied formatting marks carried across the break.
        public let marks: [Mark]

        private enum CodingKeys: String, CodingKey {
            case marks
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.marks = try container.decodeIfPresent([Mark].self, forKey: .marks) ?? []
        }
    }
}

public extension RichText.Composite {
    /// Recursively flattens all descendant nodes into a sequence, yielding leaf nodes for
    /// composite nodes and the node itself otherwise.
    func flatten() -> [RichText] {
        content.flatMap { node -> [RichText] in
            switch node {
                case .document(let doc): return doc.flatten()
                case .heading(let h): return h.flatten()
                case .bulletList(let l): return l.flatten()
                case .orderedList(let l): return l.flatten()
                case .codeBlock(let c): return c.flatten()
                case .blockquote(let b): return b.flatten()
                case .table(let t): return t.flatten()
                case .tableRow(let r): return r.flatten()
                case .paragraph(let p): return p.flatten()
                case .listItem(let i): return i.flatten()
                default: return [node]
            }
        }
    }
}
