import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import ContentDeliveryClientMacros

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

                static let relations: String = "article.author"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "article":
                        self = .article(author: try container.decode(Story<Content>.self, forKey: .author))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case author
                    case component
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

                static let relations: String = "article.author,popular.articles,promo.feature"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "article":
                        self = .article(author: try container.decode(Story<Feed>.self, forKey: .author))
                    case "popular":
                        self = .popular(articles: try container.decode([Story<Feed>].self, forKey: .articles))
                    case "promo":
                        self = .promo(feature: try container.decodeIfPresent(Story<Feed>.self, forKey: .feature))
                    case "text":
                        self = .text(value: try container.decode(String.self, forKey: .value))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case articles
                    case author
                    case component
                    case feature
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

                static let relations: String = ""

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "author":
                        self = .author(try Author(from: decoder))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
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

                static let relations: String = ""

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
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

                enum CodingKeys: String, CodingKey {
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

                static let relations: String = "alpha.story,zebra.story"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "zebra":
                        self = .zebra(story: try container.decode(Story<Mix>.self, forKey: .story))
                    case "alpha":
                        self = .alpha(story: try container.decode(Story<Mix>.self, forKey: .story))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case component
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

                static let relations: String = "feature.item"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "feature":
                        self = .feature(item: try container.decodeIfPresent(Story<Promo>.self, forKey: .item))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case component
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

                static let relations: String = "list.articles"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "list":
                        self = .list(articles: try container.decode([Story<Popular>].self, forKey: .articles))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case articles
                    case component
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

                static let relations: String = "article.author"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "article":
                        self = .article(
                            author: try container.decode(Story<Content>.self, forKey: .author),
                            headline: try container.decode(String.self, forKey: .headline)
                        )
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case author
                    case component
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

                static let relations: String = "popular_articles.articles"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "popular_articles":
                        self = .popularArticles(articles: try container.decode([Story<Content>].self, forKey: .articles))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
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

                static let relations: String = "article.author,popular_articles.articles"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "article":
                        self = .article(author: try container.decode(Story<Content>.self, forKey: .author))
                    case "popular_articles":
                        self = .popularArticles(articles: try container.decode([Story<Content>].self, forKey: .articles))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
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

                static let relations: String = ""

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
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

                enum CodingKeys: String, CodingKey {
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

                static let relations: String = ""

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "header":
                        let caseContainer = try decoder.container(keyedBy: HeaderCodingKeys.self)
                        self = .header(
                            altTitle: try caseContainer.decode(String.self, forKey: .altTitle),
                            altSubtitle: try caseContainer.decode(String.self, forKey: .altSubtitle)
                        )
                    case "text":
                        self = .text(value: try container.decode(String.self, forKey: .value))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case component
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

                static let relations: String = "header.alt_article"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "header":
                        let caseContainer = try decoder.container(keyedBy: HeaderCodingKeys.self)
                        self = .header(altArticle: try caseContainer.decode(Story<Block>.self, forKey: .altArticle))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
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

                static let relations: String = ""

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "header":
                        let caseContainer = try decoder.container(keyedBy: HeaderCodingKeys.self)
                        self = .header(altTitle: try caseContainer.decodeIfPresent(String.self, forKey: .altTitle))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
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

                static let relations: String = "article.author,popular.items"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "article":
                        self = .article(author: try container.decode(Story<Author>.self, forKey: .author))
                    case "popular":
                        self = .popular(items: try container.decode(Story<Item>.self, forKey: .items))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case author
                    case component
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

                static let relations: String = "article.author,popular.articles"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "author":
                        self = .author(try Author(from: decoder))
                    case "article":
                        self = .article(try Article(from: decoder))
                    case "popular":
                        self = .popular(articles: try container.decode([Story<Article>].self, forKey: .articles))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case articles
                    case component
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

                static let relations: String = ""

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "bar":
                        self = .bar(try Bar(from: decoder))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
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

                static let relations: String = ""

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "baz":
                        self = .baz(value: try container.decode(String.self, forKey: .value))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case component
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

                static let relations: String = "article.author"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "author":
                        self = .author(try Author(from: decoder))
                    case "article":
                        self = .article(
                            headline: try container.decode(String.self, forKey: .headline),
                            author: try container.decode([Story<Author>].self, forKey: .author)
                        )
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case author
                    case component
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

                static let relations: String = "article.author,popular.articles"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "author":
                        self = .author(try Author(from: decoder))
                    case "article":
                        self = .article(try Article(from: decoder))
                    case "popular":
                        self = .popular(articles: try container.decode([Story<Article>].self, forKey: .articles))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case articles
                    case component
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

                static let relations: String = "highlighted.post"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "page":
                        self = .page(try Page(from: decoder))
                    case "highlighted":
                        self = .highlighted(
                            title: try container.decode(String.self, forKey: .title),
                            post: try container.decode(Story<Page>.self, forKey: .post)
                        )
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case component
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

                static let relations: String = ""

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "bar":
                        self = .bar
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
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

                static let relations: String = ""

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "bar":
                        self = .bar(name: try container.decode(String.self, forKey: .name))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case component
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

                static let relations: String = ""

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "bar":
                        self = .bar(try Story<Article>(from: decoder))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
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

                static let relations: String = ""

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "bar":
                        self = .bar(try [Article](from: decoder))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
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

                static let relations: String = "article.author,popular.articles"

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let component = try container.decode(String.self, forKey: .component)
                    switch component {
                    case "article":
                        self = .article(author: try container.decode(Story<Content>.self, forKey: .author))
                    case "popular":
                        self = .popular(articles: try container.decode([Story<Content>].self, forKey: .articles))
                    default:
                        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case articles
                    case author
                    case component
                }
            }
            """,
            diagnostics: [],
            macros: macros
        )
    }
}
