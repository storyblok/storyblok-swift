import Foundation

/// Storyblok field types with structured data.
///
/// Represents special field types like ``Link`` and ``Asset``. The value of the `fieldtype`
/// JSON field is used to dispatch to the corresponding case.
public enum Field: Decodable, Hashable {

    /// A Storyblok multi-link field.
    case link(Link)

    /// A Storyblok asset field.
    case asset(Asset)

    /// A field with a type not known to this client.
    case unknown(fieldType: String)

    /// Technical name of the field type (the value of the `fieldtype` JSON field).
    public var fieldType: String {
        switch self {
            case .link(let link): return link.fieldType
            case .asset(let asset): return asset.fieldType
            case .unknown(let type): return type
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fieldType = try container.decodeIfPresent(String.self, forKey: .fieldType) ?? ""
        switch fieldType {
            case "multilink": self = .link(try Link(from: decoder))
            case "asset": self = .asset(try Asset(from: decoder))
            default: self = .unknown(fieldType: fieldType)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case fieldType = "fieldtype"
    }

    /// A Storyblok multi-link field.
    ///
    /// Supports various link types including URLs, stories, emails, and assets.
    public struct Link: Decodable, Hashable {

        /// Optional field identifier.
        public let id: String?

        /// Technical name of the field type. Always `"multilink"`.
        public let fieldType: String

        /// The URL for external links.
        public let url: String?

        /// Link target attribute (e.g., `"_blank"` for new tab).
        public let target: String?

        /// Type of link: `"url"`, `"story"`, `"email"`, or `"asset"`.
        public let linkType: String

        /// Cached URL resolved by Storyblok.
        public let cachedUrl: String?

        /// Email address for email links.
        public let email: String?

        private enum CodingKeys: String, CodingKey {
            case id
            case fieldType = "fieldtype"
            case url
            case target
            case linkType = "linktype"
            case cachedUrl = "cached_url"
            case email
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeIfPresent(String.self, forKey: .id)
            self.fieldType = try container.decodeIfPresent(String.self, forKey: .fieldType) ?? "multilink"
            self.url = try container.decodeIfPresent(String.self, forKey: .url)
            self.target = try container.decodeIfPresent(String.self, forKey: .target)
            self.linkType = try container.decodeIfPresent(String.self, forKey: .linkType) ?? "url"
            self.cachedUrl = try container.decodeIfPresent(String.self, forKey: .cachedUrl)
            self.email = try container.decodeIfPresent(String.self, forKey: .email)
        }
    }

    /// A Storyblok asset field.
    ///
    /// Contains metadata and URLs for images, documents, and other uploaded files.
    public struct Asset: Decodable, Hashable {

        /// Optional field identifier.
        public let id: Int64?

        /// Technical name of the field type. Always `"asset"`.
        public let fieldType: String

        /// Original filename of the asset.
        public let name: String?

        /// Source or origin of the asset.
        public let source: String?

        /// Alternative text for accessibility.
        public let alt: String?

        /// Focal point coordinates for image cropping.
        public let focus: String?

        /// Custom metadata key-value pairs.
        public let metadata: [String: String]?

        /// Asset title.
        public let title: String?

        /// Full URL to the asset file.
        public let filename: String

        /// Copyright information.
        public let copyright: String?

        /// `true` if the asset is hosted externally.
        public let isExternalUrl: Bool

        private enum CodingKeys: String, CodingKey {
            case id
            case fieldType = "fieldtype"
            case name
            case source
            case alt
            case focus
            case metadata = "meta_data"
            case title
            case filename
            case copyright
            case isExternalUrl = "is_external_url"
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeIfPresent(Int64.self, forKey: .id)
            self.fieldType = try container.decodeIfPresent(String.self, forKey: .fieldType) ?? "asset"
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            self.source = try container.decodeIfPresent(String.self, forKey: .source)
            self.alt = try container.decodeIfPresent(String.self, forKey: .alt)
            self.focus = try container.decodeIfPresent(String.self, forKey: .focus)
            self.metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
            self.title = try container.decodeIfPresent(String.self, forKey: .title)
            self.filename = try container.decode(String.self, forKey: .filename)
            self.copyright = try container.decodeIfPresent(String.self, forKey: .copyright)
            self.isExternalUrl = try container.decodeIfPresent(Bool.self, forKey: .isExternalUrl) ?? false
        }
    }
}
