import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import StoryblokClientMacros

private let macros: [String: Macro.Type] = ["BlockLibrary": BlockLibraryMacro.self]

final class BlockLibraryMacroTests: XCTestCase {

    // MARK: - relations

    func test_synthesizesRelationsFromEnumCaseLabel() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Content {
                case article(author: Story<Content>)
            }
            """,
            expandedSource: """
            enum Content {
                case article(author: Story<Content>)

                nonisolated static let relations: String = "article.author"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: ContentCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "article":
                        let caseContainer = try decoder.container(keyedBy: ArticleCodingKeys.self)
                        self = .article(author: try caseContainer.decode(Story<Content>.self, forKey: .author))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum ContentCodingKeys: String, CodingKey {
                    case component
                }

                enum ArticleCodingKeys: String, CodingKey {
                    case author
                }
            }
            """,
            macros: macros
        )
    }

    func test_synthesizesRelationsFromMultipleCases() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Feed {
                case article(author: Story<Feed>)
                case popular(articles: [Story<Feed>])
                case promo(feature: Story<Feed>?)
                case text(value: String)
            }
            """,
            expandedSource: """
            enum Feed {
                case article(author: Story<Feed>)
                case popular(articles: [Story<Feed>])
                case promo(feature: Story<Feed>?)
                case text(value: String)

                nonisolated static let relations: String = "article.author,popular.articles,promo.feature"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: FeedCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "article":
                        let caseContainer = try decoder.container(keyedBy: ArticleCodingKeys.self)
                        self = .article(author: try caseContainer.decode(Story<Feed>.self, forKey: .author))
                    case "popular":
                        let caseContainer = try decoder.container(keyedBy: PopularCodingKeys.self)
                        self = .popular(articles: try caseContainer.decode([Story<Feed>].self, forKey: .articles))
                    case "promo":
                        let caseContainer = try decoder.container(keyedBy: PromoCodingKeys.self)
                        self = .promo(feature: try caseContainer.decodeIfPresent(Story<Feed>.self, forKey: .feature))
                    case "text":
                        let caseContainer = try decoder.container(keyedBy: TextCodingKeys.self)
                        self = .text(value: try caseContainer.decode(String.self, forKey: .value))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum FeedCodingKeys: String, CodingKey {
                    case component
                }

                enum ArticleCodingKeys: String, CodingKey {
                    case author
                }

                enum PopularCodingKeys: String, CodingKey {
                    case articles
                }

                enum PromoCodingKeys: String, CodingKey {
                    case feature
                }

                enum TextCodingKeys: String, CodingKey {
                    case value
                }
            }
            """,
            macros: macros
        )
    }

    func test_unlabeledAssociatedValueDecodesWholeContent() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Wrapper {
                case author(Author)

                struct Author: Decodable {
                    let name: String
                }
            }
            """,
            expandedSource: """
            enum Wrapper {
                case author(Author)

                struct Author: Decodable {
                    let name: String
                }

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: WrapperCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "author":
                        self = .author(try Author(from: decoder))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum WrapperCodingKeys: String, CodingKey {
                    case component
                }
            }
            """,
            macros: macros
        )
    }

    func test_enumWithoutStoryValuesHasEmptyRelations() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Status {
                case active
                case inactive
            }
            """,
            expandedSource: """
            enum Status {
                case active
                case inactive

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: StatusCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "active":
                        self = .active
                    case "inactive":
                        self = .inactive
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum StatusCodingKeys: String, CodingKey {
                    case component
                }
            }
            """,
            macros: macros
        )
    }

    func test_relationsAreSortedAlphabetically() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Mix {
                case zebra(story: Story<Mix>)
                case alpha(story: Story<Mix>)
            }
            """,
            expandedSource: """
            enum Mix {
                case zebra(story: Story<Mix>)
                case alpha(story: Story<Mix>)

                nonisolated static let relations: String = "alpha.story,zebra.story"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: MixCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "zebra":
                        let caseContainer = try decoder.container(keyedBy: ZebraCodingKeys.self)
                        self = .zebra(story: try caseContainer.decode(Story<Mix>.self, forKey: .story))
                    case "alpha":
                        let caseContainer = try decoder.container(keyedBy: AlphaCodingKeys.self)
                        self = .alpha(story: try caseContainer.decode(Story<Mix>.self, forKey: .story))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum MixCodingKeys: String, CodingKey {
                    case component
                }

                enum ZebraCodingKeys: String, CodingKey {
                    case story
                }

                enum AlphaCodingKeys: String, CodingKey {
                    case story
                }
            }
            """,
            macros: macros
        )
    }

    func test_optionalStoryTypeIsRecognised() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Promo {
                case feature(item: Story<Promo>?)
            }
            """,
            expandedSource: """
            enum Promo {
                case feature(item: Story<Promo>?)

                nonisolated static let relations: String = "feature.item"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: PromoCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "feature":
                        let caseContainer = try decoder.container(keyedBy: FeatureCodingKeys.self)
                        self = .feature(item: try caseContainer.decodeIfPresent(Story<Promo>.self, forKey: .item))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum PromoCodingKeys: String, CodingKey {
                    case component
                }

                enum FeatureCodingKeys: String, CodingKey {
                    case item
                }
            }
            """,
            macros: macros
        )
    }

    func test_arrayOfStoryTypeIsRecognised() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Popular {
                case list(articles: [Story<Popular>])
            }
            """,
            expandedSource: """
            enum Popular {
                case list(articles: [Story<Popular>])

                nonisolated static let relations: String = "list.articles"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: PopularCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "list":
                        let caseContainer = try decoder.container(keyedBy: ListCodingKeys.self)
                        self = .list(articles: try caseContainer.decode([Story<Popular>].self, forKey: .articles))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum PopularCodingKeys: String, CodingKey {
                    case component
                }

                enum ListCodingKeys: String, CodingKey {
                    case articles
                }
            }
            """,
            macros: macros
        )
    }
    
    // MARK: - Backtick-escaped case names

    /// Storyblok component technical names can collide with Swift keywords (e.g. `default`),
    /// forcing the case to be backtick-escaped. The backticks must be stripped when deriving
    /// the JSON component name and the per-case CodingKeys type, but preserved when emitting
    /// the `.case` reference so the generated code stays valid Swift.
    func test_backtickEscapedCaseName() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Content {
                case `default`(label: String)
            }
            """,
            expandedSource: """
            enum Content {
                case `default`(label: String)

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: ContentCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "default":
                        let caseContainer = try decoder.container(keyedBy: DefaultCodingKeys.self)
                        self = .`default`(label: try caseContainer.decode(String.self, forKey: .label))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum ContentCodingKeys: String, CodingKey {
                    case component
                }

                enum DefaultCodingKeys: String, CodingKey {
                    case label
                }
            }
            """,
            macros: macros
        )
    }

    /// A backtick-escaped case carrying a `Story<T>` relation must report the relation under
    /// the stripped component name (`default.author`, not `` `default`.author ``).
    func test_backtickEscapedCaseNameWithRelation() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Content {
                case `default`(author: Story<Content>)
            }
            """,
            expandedSource: """
            enum Content {
                case `default`(author: Story<Content>)

                nonisolated static let relations: String = "default.author"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: ContentCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "default":
                        let caseContainer = try decoder.container(keyedBy: DefaultCodingKeys.self)
                        self = .`default`(author: try caseContainer.decode(Story<Content>.self, forKey: .author))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum ContentCodingKeys: String, CodingKey {
                    case component
                }

                enum DefaultCodingKeys: String, CodingKey {
                    case author
                }
            }
            """,
            macros: macros
        )
    }

    /// Storyblok component technical names frequently contain hyphens (e.g. `emoji-randomizer`),
    /// which require Swift raw identifiers. The backticks and hyphen must survive into the
    /// `.case` reference while the JSON component name keeps the hyphen but drops the backticks.
    func test_rawIdentifierCaseNameWithHyphen() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Content {
                case `emoji-randomizer`(label: String)
            }
            """,
            expandedSource: """
            enum Content {
                case `emoji-randomizer`(label: String)

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: ContentCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "emoji-randomizer":
                        let caseContainer = try decoder.container(keyedBy: EmojiRandomizerCodingKeys.self)
                        self = .`emoji-randomizer`(label: try caseContainer.decode(String.self, forKey: .label))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum ContentCodingKeys: String, CodingKey {
                    case component
                }

                enum EmojiRandomizerCodingKeys: String, CodingKey {
                    case label
                }
            }
            """,
            macros: macros
        )
    }

    // MARK: - Multiple params

    func test_multipleParamsAreDecodedOnSeparateLines() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Content {
                case article(author: Story<Content>, headline: String)
            }
            """,
            expandedSource: """
            enum Content {
                case article(author: Story<Content>, headline: String)

                nonisolated static let relations: String = "article.author"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: ContentCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "article":
                        let caseContainer = try decoder.container(keyedBy: ArticleCodingKeys.self)
                        self = .article(
                            author: try caseContainer.decode(Story<Content>.self, forKey: .author),
                            headline: try caseContainer.decode(String.self, forKey: .headline)
                        )
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum ContentCodingKeys: String, CodingKey {
                    case component
                }

                enum ArticleCodingKeys: String, CodingKey {
                    case author
                    case headline
                }
            }
            """,
            macros: macros
        )
    }

    // MARK: - User-defined CodingKeys

    func test_userDefinedCodingKeysAreUsedAndNotRegenerated() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Content {
                case popularArticles(articles: [Story<Content>])

                enum CodingKeys: String, CodingKey {
                    case popularArticles = "popular_articles"
                    case articles
                    case component
                }
            }
            """,
            expandedSource: """
            enum Content {
                case popularArticles(articles: [Story<Content>])

                enum CodingKeys: String, CodingKey {
                    case popularArticles = "popular_articles"
                    case articles
                    case component
                }

                nonisolated static let relations: String = "popular_articles.articles"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: ContentCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "popular_articles":
                        let caseContainer = try decoder.container(keyedBy: PopularArticlesCodingKeys.self)
                        self = .popularArticles(articles: try caseContainer.decode([Story<Content>].self, forKey: .articles))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum ContentCodingKeys: String, CodingKey {
                    case component
                }

                enum PopularArticlesCodingKeys: String, CodingKey {
                    case articles
                }
            }
            """,
            macros: macros
        )
    }

    func test_unmappedCasesUseSwiftNameWhenCodingKeysPresent() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Content {
                case article(author: Story<Content>)
                case popularArticles(articles: [Story<Content>])

                enum CodingKeys: String, CodingKey {
                    case article
                    case popularArticles = "popular_articles"
                    case author
                    case articles
                    case component
                }
            }
            """,
            expandedSource: """
            enum Content {
                case article(author: Story<Content>)
                case popularArticles(articles: [Story<Content>])

                enum CodingKeys: String, CodingKey {
                    case article
                    case popularArticles = "popular_articles"
                    case author
                    case articles
                    case component
                }

                nonisolated static let relations: String = "article.author,popular_articles.articles"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: ContentCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "article":
                        let caseContainer = try decoder.container(keyedBy: ArticleCodingKeys.self)
                        self = .article(author: try caseContainer.decode(Story<Content>.self, forKey: .author))
                    case "popular_articles":
                        let caseContainer = try decoder.container(keyedBy: PopularArticlesCodingKeys.self)
                        self = .popularArticles(articles: try caseContainer.decode([Story<Content>].self, forKey: .articles))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum ContentCodingKeys: String, CodingKey {
                    case component
                }

                enum ArticleCodingKeys: String, CodingKey {
                    case author
                }

                enum PopularArticlesCodingKeys: String, CodingKey {
                    case articles
                }
            }
            """,
            macros: macros
        )
    }

    // MARK: - Per-case CodingKeys

    func test_perCaseCodingKeysGeneratesLocalContainer() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Block {
                case header(altTitle: String, altSubtitle: String)
                enum HeaderCodingKeys: String, CodingKey {
                    case altTitle = "alternative_title"
                    case altSubtitle = "alternative_subtitle"
                }
            }
            """,
            expandedSource: """
            enum Block {
                case header(altTitle: String, altSubtitle: String)
                enum HeaderCodingKeys: String, CodingKey {
                    case altTitle = "alternative_title"
                    case altSubtitle = "alternative_subtitle"
                }

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: BlockCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "header":
                        let caseContainer = try decoder.container(keyedBy: HeaderCodingKeys.self)
                        self = .header(
                            altTitle: try caseContainer.decode(String.self, forKey: .altTitle),
                            altSubtitle: try caseContainer.decode(String.self, forKey: .altSubtitle)
                        )
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum BlockCodingKeys: String, CodingKey {
                    case component
                }
            }
            """,
            macros: macros
        )
    }

    func test_perCaseCodingKeysMixedWithStandardCases() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Block {
                case header(altTitle: String, altSubtitle: String)
                case text(value: String)
                enum HeaderCodingKeys: String, CodingKey {
                    case altTitle = "alternative_title"
                    case altSubtitle = "alternative_subtitle"
                }
            }
            """,
            expandedSource: """
            enum Block {
                case header(altTitle: String, altSubtitle: String)
                case text(value: String)
                enum HeaderCodingKeys: String, CodingKey {
                    case altTitle = "alternative_title"
                    case altSubtitle = "alternative_subtitle"
                }

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: BlockCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "header":
                        let caseContainer = try decoder.container(keyedBy: HeaderCodingKeys.self)
                        self = .header(
                            altTitle: try caseContainer.decode(String.self, forKey: .altTitle),
                            altSubtitle: try caseContainer.decode(String.self, forKey: .altSubtitle)
                        )
                    case "text":
                        let caseContainer = try decoder.container(keyedBy: TextCodingKeys.self)
                        self = .text(value: try caseContainer.decode(String.self, forKey: .value))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum BlockCodingKeys: String, CodingKey {
                    case component
                }

                enum TextCodingKeys: String, CodingKey {
                    case value
                }
            }
            """,
            macros: macros
        )
    }

    func test_perCaseCodingKeysRelationsUseJsonKey() {
        assertMacroExpansion(
            """
            @BlockLibrary
            indirect enum Block {
                case header(altArticle: Story<Block>)
                enum HeaderCodingKeys: String, CodingKey {
                    case altArticle = "alt_article"
                }
            }
            """,
            expandedSource: """
            indirect enum Block {
                case header(altArticle: Story<Block>)
                enum HeaderCodingKeys: String, CodingKey {
                    case altArticle = "alt_article"
                }

                nonisolated static let relations: String = "header.alt_article"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: BlockCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "header":
                        let caseContainer = try decoder.container(keyedBy: HeaderCodingKeys.self)
                        self = .header(altArticle: try caseContainer.decode(Story<Block>.self, forKey: .altArticle))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum BlockCodingKeys: String, CodingKey {
                    case component
                }
            }
            """,
            macros: macros
        )
    }

    func test_perCaseCodingKeysOptionalParam() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Block {
                case header(altTitle: String?)
                enum HeaderCodingKeys: String, CodingKey {
                    case altTitle = "alternative_title"
                }
            }
            """,
            expandedSource: """
            enum Block {
                case header(altTitle: String?)
                enum HeaderCodingKeys: String, CodingKey {
                    case altTitle = "alternative_title"
                }

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: BlockCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "header":
                        let caseContainer = try decoder.container(keyedBy: HeaderCodingKeys.self)
                        self = .header(altTitle: try caseContainer.decodeIfPresent(String.self, forKey: .altTitle))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum BlockCodingKeys: String, CodingKey {
                    case component
                }
            }
            """,
            macros: macros
        )
    }

    // MARK: - Diagnostics

    func test_errorWhenStoryRelationTypeIsNotVisibleToMacro() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Content {
                case article(author: Story<Author>)
                case popular(items: Story<Item>)
            }
            """,
            expandedSource: """
            enum Content {
                case article(author: Story<Author>)
                case popular(items: Story<Item>)

                nonisolated static let relations: String = "article.author,popular.items"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: ContentCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "article":
                        let caseContainer = try decoder.container(keyedBy: ArticleCodingKeys.self)
                        self = .article(author: try caseContainer.decode(Story<Author>.self, forKey: .author))
                    case "popular":
                        let caseContainer = try decoder.container(keyedBy: PopularCodingKeys.self)
                        self = .popular(items: try caseContainer.decode(Story<Item>.self, forKey: .items))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum ContentCodingKeys: String, CodingKey {
                    case component
                }

                enum ArticleCodingKeys: String, CodingKey {
                    case author
                }

                enum PopularCodingKeys: String, CodingKey {
                    case items
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Story<T> relation field type 'Author' must be the enclosing enum type or a nested struct declared within the enum; the macro can only discover nested Story fields for types defined in the enum body",
                    line: 3,
                    column: 26
                ),
                DiagnosticSpec(
                    message: "Story<T> relation field type 'Item' must be the enclosing enum type or a nested struct declared within the enum; the macro can only discover nested Story fields for types defined in the enum body",
                    line: 4,
                    column: 25
                ),
            ],
            macros: macros
        )
    }

    // MARK: - Nested struct relations

    func test_synthesizesRelationsFromNestedStructFields() {
        assertMacroExpansion(
            """
            @BlockLibrary
            indirect enum Block {
                case author(Author)
                case article(Article)
                case popular(articles: [Story<Article>])

                struct Author: Decodable {
                    let name: String
                }

                struct Article: Decodable {
                    let headline: String
                    let author: Story<Author>
                }
            }
            """,
            expandedSource: """
            indirect enum Block {
                case author(Author)
                case article(Article)
                case popular(articles: [Story<Article>])

                struct Author: Decodable {
                    let name: String
                }

                struct Article: Decodable {
                    let headline: String
                    let author: Story<Author>
                }

                nonisolated static let relations: String = "article.author,popular.articles"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: BlockCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "author":
                        self = .author(try Author(from: decoder))
                    case "article":
                        self = .article(try Article(from: decoder))
                    case "popular":
                        let caseContainer = try decoder.container(keyedBy: PopularCodingKeys.self)
                        self = .popular(articles: try caseContainer.decode([Story<Article>].self, forKey: .articles))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum BlockCodingKeys: String, CodingKey {
                    case component
                }

                enum PopularCodingKeys: String, CodingKey {
                    case articles
                }
            }
            """,
            macros: macros
        )
    }

    func test_errorWhenUnlabeledTypeIsNotNestedStruct() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Foo {
                case bar(Bar)
            }
            """,
            expandedSource: """
            enum Foo {
                case bar(Bar)

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: FooCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "bar":
                        self = .bar(try Bar(from: decoder))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum FooCodingKeys: String, CodingKey {
                    case component
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'Bar' must be declared as a nested struct within the enum",
                    line: 3,
                    column: 14
                ),
            ],
            macros: macros
        )
    }

    func test_errorWhenNestedStructHasNoCase() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Foo {
                case baz(value: String)
                struct Bar: Decodable {
                    let value: String
                }
            }
            """,
            expandedSource: """
            enum Foo {
                case baz(value: String)
                struct Bar: Decodable {
                    let value: String
                }

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: FooCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "baz":
                        let caseContainer = try decoder.container(keyedBy: BazCodingKeys.self)
                        self = .baz(value: try caseContainer.decode(String.self, forKey: .value))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum FooCodingKeys: String, CodingKey {
                    case component
                }

                enum BazCodingKeys: String, CodingKey {
                    case value
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "nested struct 'Bar' must have a corresponding enum case with it as an unlabeled associated value; the case name must match the block type's technical name",
                    line: 4,
                    column: 12
                ),
            ],
            macros: macros
        )
    }

    func test_relationsAreCorrectlyDecodedWhenDeclaredAsNestedType() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Block {
                case author(Author)
                case article(headline: String, author: [Story<Author>])

                struct Author: Decodable {
                    let name: String
                }
            }
            """,
            expandedSource: """
            enum Block {
                case author(Author)
                case article(headline: String, author: [Story<Author>])

                struct Author: Decodable {
                    let name: String
                }

                nonisolated static let relations: String = "article.author"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: BlockCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "author":
                        self = .author(try Author(from: decoder))
                    case "article":
                        let caseContainer = try decoder.container(keyedBy: ArticleCodingKeys.self)
                        self = .article(
                            headline: try caseContainer.decode(String.self, forKey: .headline),
                            author: try caseContainer.decode([Story<Author>].self, forKey: .author)
                        )
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum BlockCodingKeys: String, CodingKey {
                    case component
                }

                enum ArticleCodingKeys: String, CodingKey {
                    case author
                    case headline
                }
            }
            """,
            macros: macros
        )
    }

    func test_arrayOfRelationsAreCorrectlyDecodedWhenDeclaredAsNestedType() {
        assertMacroExpansion(
            """
            @BlockLibrary
            indirect enum MyBlock {
                case author(Author)
                case article(Article)
                case popular(articles: [Story<Article>])

                struct Author: Decodable {
                    let name: String
                }

                struct Article: Decodable {
                    let headline: String
                    let author: Story<Author>
                }
            }
            """,
            expandedSource: """
            indirect enum MyBlock {
                case author(Author)
                case article(Article)
                case popular(articles: [Story<Article>])

                struct Author: Decodable {
                    let name: String
                }

                struct Article: Decodable {
                    let headline: String
                    let author: Story<Author>
                }

                nonisolated static let relations: String = "article.author,popular.articles"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: MyBlockCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "author":
                        self = .author(try Author(from: decoder))
                    case "article":
                        self = .article(try Article(from: decoder))
                    case "popular":
                        let caseContainer = try decoder.container(keyedBy: PopularCodingKeys.self)
                        self = .popular(articles: try caseContainer.decode([Story<Article>].self, forKey: .articles))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum MyBlockCodingKeys: String, CodingKey {
                    case component
                }

                enum PopularCodingKeys: String, CodingKey {
                    case articles
                }
            }
            """,
            macros: macros
        )
    }

    func test_singleNestedStoryRelationDecodesDirectly() {
        assertMacroExpansion(
            """
            @BlockLibrary
            indirect enum MyBlock {
                case page(Page)
                case highlighted(title: String, post: Story<Page>)

                struct Page {
                    let title: String
                }
            }
            """,
            expandedSource: """
            indirect enum MyBlock {
                case page(Page)
                case highlighted(title: String, post: Story<Page>)

                struct Page {
                    let title: String
                }

                nonisolated static let relations: String = "highlighted.post"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: MyBlockCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "page":
                        self = .page(try Page(from: decoder))
                    case "highlighted":
                        let caseContainer = try decoder.container(keyedBy: HighlightedCodingKeys.self)
                        self = .highlighted(
                            title: try caseContainer.decode(String.self, forKey: .title),
                            post: try caseContainer.decode(Story<Page>.self, forKey: .post)
                        )
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum MyBlockCodingKeys: String, CodingKey {
                    case component
                }

                enum HighlightedCodingKeys: String, CodingKey {
                    case post
                    case title
                }
            }
            """,
            macros: macros
        )
    }

    // MARK: - Associated value label enforcement

    func test_errorWhenMultipleUnlabeledAssociatedValues() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Foo {
                case bar(Int, String)
            }
            """,
            expandedSource: """
            enum Foo {
                case bar(Int, String)

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: FooCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "bar":
                        self = .bar
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum FooCodingKeys: String, CodingKey {
                    case component
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "associated values with multiple parameters must all have labels",
                    line: 3,
                    column: 14
                ),
                DiagnosticSpec(
                    message: "associated values with multiple parameters must all have labels",
                    line: 3,
                    column: 19
                ),
            ],
            macros: macros
        )
    }

    func test_errorWhenMixedLabeledAndUnlabeledAssociatedValues() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Foo {
                case bar(name: String, Int)
            }
            """,
            expandedSource: """
            enum Foo {
                case bar(name: String, Int)

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: FooCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "bar":
                        let caseContainer = try decoder.container(keyedBy: BarCodingKeys.self)
                        self = .bar(name: try caseContainer.decode(String.self, forKey: .name))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum FooCodingKeys: String, CodingKey {
                    case component
                }

                enum BarCodingKeys: String, CodingKey {
                    case name
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "associated values with multiple parameters must all have labels",
                    line: 3,
                    column: 28
                ),
            ],
            macros: macros
        )
    }

    func test_errorWhenSingleUnlabeledAssociatedValueIsGenericType() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Foo {
                case bar(Story<Article>)
            }
            """,
            expandedSource: """
            enum Foo {
                case bar(Story<Article>)

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: FooCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "bar":
                        self = .bar(try Story<Article>(from: decoder))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum FooCodingKeys: String, CodingKey {
                    case component
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "a single unlabeled associated value must be a plain struct type",
                    line: 3,
                    column: 14
                ),
            ],
            macros: macros
        )
    }

    func test_errorWhenSingleUnlabeledAssociatedValueIsArrayType() {
        assertMacroExpansion(
            """
            @BlockLibrary
            enum Foo {
                case bar([Article])
            }
            """,
            expandedSource: """
            enum Foo {
                case bar([Article])

                nonisolated static let relations: String = ""

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: FooCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "bar":
                        self = .bar(try [Article](from: decoder))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum FooCodingKeys: String, CodingKey {
                    case component
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "a single unlabeled associated value must be a plain struct type",
                    line: 3,
                    column: 14
                ),
            ],
            macros: macros
        )
    }

    // MARK: - Enum-only enforcement

    func test_errorWhenAppliedToStruct() {
        assertMacroExpansion(
            """
            @BlockLibrary
            struct Page {
                let title: String
            }
            """,
            expandedSource: """
            struct Page {
                let title: String
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@BlockLibrary can only be applied to an enum",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }

    func test_errorWhenAppliedToClass() {
        assertMacroExpansion(
            """
            @BlockLibrary
            class Page {
                let title: String
            }
            """,
            expandedSource: """
            class Page {
                let title: String
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@BlockLibrary can only be applied to an enum",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }

    // MARK: - Enum-only enforcement

    func test_noErrorWhenAllStoryRelationTypesMatch() {
        assertMacroExpansion(
            """
            @BlockLibrary
            indirect enum Content {
                case article(author: Story<Content>)
                case popular(articles: [Story<Content>])
            }
            """,
            expandedSource: """
            indirect enum Content {
                case article(author: Story<Content>)
                case popular(articles: [Story<Content>])

                nonisolated static let relations: String = "article.author,popular.articles"

                nonisolated init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: ContentCodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "article":
                        let caseContainer = try decoder.container(keyedBy: ArticleCodingKeys.self)
                        self = .article(author: try caseContainer.decode(Story<Content>.self, forKey: .author))
                    case "popular":
                        let caseContainer = try decoder.container(keyedBy: PopularCodingKeys.self)
                        self = .popular(articles: try caseContainer.decode([Story<Content>].self, forKey: .articles))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum ContentCodingKeys: String, CodingKey {
                    case component
                }

                enum ArticleCodingKeys: String, CodingKey {
                    case author
                }

                enum PopularCodingKeys: String, CodingKey {
                    case articles
                }
            }
            """,
            diagnostics: [],
            macros: macros
        )
    }
}
