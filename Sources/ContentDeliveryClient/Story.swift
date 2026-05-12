import Foundation

/// Represents a single story retrieved from the [Storyblok Content Delivery API](https://www.storyblok.com/docs/api/content-delivery/v2).
public struct Story<T : Block>: Sendable {

    /// Story ID.
    public let id: Int64

    /// Story UUID.
    public let uuid: UUID

    /// Story name.
    public let name: String

    /// An object containing the field data associated with the content type's specific structure.
    /// Also includes a `component` property with the content type's technical name.
    public let content: T

    /// Story slug.
    public let slug: String

    /// Story full slug, combining the parent folder(s) and the story slug.
    public let fullSlug: String

    /// Creation timestamp (`ISO 8601` format in UTC).
    public let createdAt: Date

    /// Latest publication timestamp (`ISO 8601` format in UTC).
    public let publishedAt: Date?

    /// First publication timestamp (`ISO 8601` format in UTC).
    public let firstPublishedAt: Date?

    /// Latest update timestamp (`ISO 8601` format in UTC).
    public let updatedAt: Date?

    /// Date defined in the story's entry configuration (Format: `yyyy-MM-dd`).
    public let sortByDate: Date?

    /// Numeric representation of the story's position in the folder.
    public let position: Int

    /// Array of tag names.
    public let tagList: [String]

    /// `true` if the story is defined as folder root.
    public let isStartPage: Bool

    /// Parent folder ID.
    public let parentId: Int64?

    /// Object to store non-editable data that is exclusively maintained with the Management API.
    public let metadata: [String: String]?

    /// Group ID (UUID), shared between stories defined as alternates.
    public let groupId: UUID

    /// Current release ID (if requested via the `from_release` parameter).
    public let releaseId: Int64?

    /// Language code of the current language version (if requested via the `language` parameter).
    public let language: String

    /// Real path defined in the story's entry configuration (see Visual Editor).
    public let path: String?

    /// An array containing objects that provide basic data of the stories defined as alternates
    /// of the current story.
    public let alternates: [Alternate]

    /// Contains the complete slug of the default language (if the Translatable Slugs app is installed).
    public let defaultFullSlug: String?

    /// Array of translated slug objects (if the Translatable Slugs app is installed).
    public let translatedSlugs: [TranslatedSlug]?

    public init<R : Block>(_ story: Story<R>, content: T) {
        self.id = story.id
        self.uuid = story.uuid
        self.name = story.name
        self.content = content
        self.slug = story.slug
        self.fullSlug = story.fullSlug
        self.createdAt = story.createdAt
        self.publishedAt = story.publishedAt
        self.firstPublishedAt = story.firstPublishedAt
        self.updatedAt = story.updatedAt
        self.sortByDate = story.sortByDate
        self.position = story.position
        self.tagList = story.tagList
        self.isStartPage = story.isStartPage
        self.parentId = story.parentId
        self.metadata = story.metadata
        self.groupId = story.groupId
        self.releaseId = story.releaseId
        self.language = story.language
        self.path = story.path
        self.alternates = story.alternates
        self.defaultFullSlug = story.defaultFullSlug
        self.translatedSlugs = story.translatedSlugs
    }
}

/// Translated slug information for localized story variants.
///
/// Available when the [Translatable Slugs](https://www.storyblok.com/docs/apps/translatable-slugs) app is installed.
public struct TranslatedSlug: Decodable, Sendable {

    /// Translated slug.
    public let path: String

    /// Translated name.
    public let name: String?

    /// Language code of the story variant.
    public let language: String

    /// `true` if the story variant is currently published.
    public let published: Bool?

    private enum CodingKeys: String, CodingKey {
        case path
        case name
        case language = "lang"
        case published
    }
}

/// Basic data for a story defined as an alternate of the current story.
///
/// Alternates are different language versions or variants of the same content.
public struct Alternate: Decodable, Sendable {

    /// Story ID.
    public let id: Int64

    /// Story name.
    public let name: String

    /// Story slug.
    public let slug: String

    /// `true` if the story is currently published.
    public let published: Bool

    /// Story full slug, combining the parent folder(s) and the story slug.
    public let fullSlug: String

    /// `true` if the instance constitutes a folder.
    public let isFolder: Bool

    /// ID of the parent folder.
    public let parentId: Int64

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case published
        case fullSlug = "full_slug"
        case isFolder = "is_folder"
        case parentId = "parent_id"
    }
}


extension Story: Sendable where T: Sendable {}

extension Story : Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case name
        case content
        case slug
        case fullSlug = "full_slug"
        case createdAt = "created_at"
        case publishedAt = "published_at"
        case firstPublishedAt = "first_published_at"
        case updatedAt = "updated_at"
        case sortByDate = "sort_by_date"
        case position
        case tagList = "tag_list"
        case isStartPage = "is_startpage"
        case parentId = "parent_id"
        case metadata = "meta_data"
        case groupId = "group_id"
        case releaseId = "release_id"
        case language = "lang"
        case path
        case alternates
        case defaultFullSlug = "default_full_slug"
        case translatedSlugs = "translated_slugs"
    }

    public init(from decoder: any Decoder) throws {
        // When a Story field carries a UUID placeholder string instead of an inline
        // story object, resolve it from the RelationStore in userInfo.
        if let single = try? decoder.singleValueContainer(),
           let uuidString = try? single.decode(String.self),
           UUID(uuidString: uuidString) != nil {
            guard let store = decoder.userInfo[.storyblokRelations] as? RelationStore,
                let resolved = store.stories[uuidString.lowercased()] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unresolved story relation: \(uuidString)"
                    )
                )
            }
            self = resolved as! Story<T>
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        uuid = try container.decode(UUID.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
        content = try container.decode(T.self, forKey: .content)
        slug = try container.decode(String.self, forKey: .slug)
        fullSlug = try container.decode(String.self, forKey: .fullSlug)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        publishedAt = try container.decodeIfPresent(Date.self, forKey: .publishedAt)
        firstPublishedAt = try container.decodeIfPresent(Date.self, forKey: .firstPublishedAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        sortByDate = try container.decodeIfPresent(Date.self, forKey: .sortByDate)
        position = try container.decode(Int.self, forKey: .position)
        tagList = try container.decode([String].self, forKey: .tagList)
        isStartPage = try container.decode(Bool.self, forKey: .isStartPage)
        parentId = try container.decodeIfPresent(Int64.self, forKey: .parentId)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
        groupId = try container.decode(UUID.self, forKey: .groupId)
        releaseId = try container.decodeIfPresent(Int64.self, forKey: .releaseId)
        language = try container.decode(String.self, forKey: .language)
        path = try container.decodeIfPresent(String.self, forKey: .path)
        alternates = try container.decode([Alternate].self, forKey: .alternates)
        defaultFullSlug = try container.decodeIfPresent(String.self, forKey: .defaultFullSlug)
        translatedSlugs = try container.decodeIfPresent([TranslatedSlug].self, forKey: .translatedSlugs)
    }
}
