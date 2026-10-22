import Testing
import Foundation
@testable import StoryblokClient

@BlockLibrary
enum QueryLibrary : Decodable, Hashable, Sendable {

    case product(Product)
    case article(Article)

    nonisolated struct Product : Decodable, Hashable, Sendable {
        let headline: String
        let categories: [String]
        let stock: Int
        let rating: Double
        /// A number Storyblok holds in a text field, which is how it serialises number fields.
        let price: String
        let releaseDate: Date

        /// Not a Storyblok field, so the macro leaves it out of `fieldNames`.
        var isDiscounted: Bool { false }

        enum CodingKeys: String, CodingKey {
            case headline, categories, stock, rating, price
            case releaseDate = "release_date"
        }
    }

    nonisolated struct Article : Decodable, Hashable, Sendable {
        let title: String
        #if canImport(Foundation)
        /// Declared under `#if`, which the macro names under the same condition.
        var subtitle: String?
        #endif
    }
}

@Suite("StoriesQuery")
struct StoriesQueryTests {

    private func items(_ configure: (inout StoriesQuery<QueryLibrary.Product>) -> Void) -> [String: String] {
        var query = StoriesQuery<QueryLibrary.Product>()
        configure(&query)
        return Dictionary(uniqueKeysWithValues: query.queryItems.map { ($0.name, $0.value ?? "") })
    }

    @Test
    func `the macro derives the technical name from the enum case`() {
        #expect(QueryLibrary.Product.technicalName == "product")
        #expect(items { _ in }["content_type"] == "product")
    }

    @Test
    func `a field renamed by CodingKeys is addressed by its Storyblok name`() {
        let query = items { $0.filter { $0.releaseDate > Date(timeIntervalSince1970: 0) } }
        #expect(query["filter_query[release_date][gt_date]"] == "1970-01-01T00:00:00Z")
        #expect(query["filter_query[releaseDate][gt_date]"] == nil)
    }

    @Test
    func `a query typed to the whole library asks for every component`() {
        var query = StoriesQuery<QueryLibrary>()
        query.searchTerm = "space"

        #expect(QueryLibrary.technicalName == nil)
        #expect(query.queryItems.map(\.name) == ["search_term"], "no content_type")
    }

    @Test
    func `a field declared under #if is named`() {
        #expect(QueryLibrary.Article.fieldNames[\QueryLibrary.Article.title] == "title")
        #expect(QueryLibrary.Article.fieldNames[\QueryLibrary.Article.subtitle] == "subtitle")
    }

    @Test
    func `a field missing from fieldNames is sent under its Swift name by a sort as by a filter`() {
        let query = items {
            $0.sort(by: \.isDiscounted)
            $0.filter { $0.isDiscounted.is(.isTrue) }
        }
        #expect(query["sort_by"] == "content.isDiscounted:asc")
        #expect(query["filter_query[isDiscounted][is]"] == "true")
    }

    @Test
    func `the field's Swift type picks the comparison's wire operation`() {
        let query = items {
            $0.filter {
                $0.stock > 10
                $0.rating < 4.5
            }
        }
        #expect(query["filter_query[stock][gt_int]"] == "10")
        #expect(query["filter_query[rating][lt_float]"] == "4.5")
    }

    @Test
    func `a number held in a text field is compared numerically only when said so`() {
        let query = items { $0.filter { $0.price.asWholeNumber > 100 } }
        #expect(query["filter_query[price][gt_int]"] == "100")
    }

    @Test
    func `text and array operations produce their documented parameters`() {
        let query = items {
            $0.filter {
                $0.headline.like("*space*")
                $0.headline.in(["Spaceship", "Rocket"])
                $0.headline.notIn(["Paper"])
                $0.categories.contains(anyOf: ["solar-system", "mars"])
                $0.categories.isNotEmpty
            }
        }
        #expect(query["filter_query[headline][like]"] == "*space*")
        #expect(query["filter_query[headline][in]"] == "Spaceship,Rocket")
        #expect(query["filter_query[headline][not_in]"] == "Paper")
        #expect(query["filter_query[categories][any_in_array]"] == "solar-system,mars")
        #expect(query["filter_query[categories][is]"] == "not_empty_array")
    }

    @Test
    func `sorting takes its ordering from the field's type, or from what is stated`() {
        let query = items {
            $0.sort(by: \.headline)
            $0.sort(by: \.stock, .descending)
            $0.sort(by: \.rating)
            $0.sort(by: \.price, .descending, as: .wholeNumber)
            $0.sort(by: .publishedAt, .descending)
        }
        #expect(query["sort_by"] == "content.headline:asc,content.stock:desc:int,content.rating:asc:float,content.price:desc:int,published_at:desc")
    }

    @Test
    func `an added parameter goes out after the generated ones, replacing none of them`() {
        var query = StoriesQuery<QueryLibrary.Product>()
        query.parameter("filter_query[body.0.component][in]", "hero")
        query.parameter("content_type", "page")

        let items = query.queryItems
        #expect(items.suffix(2) == [
            URLQueryItem(name: "filter_query[body.0.component][in]", value: "hero"),
            URLQueryItem(name: "content_type", value: "page"),
        ])
        #expect(items.filter { $0.name == "content_type" }.map(\.value) == ["product", "page"],
                "a name the query already sends goes out twice")
    }
}
