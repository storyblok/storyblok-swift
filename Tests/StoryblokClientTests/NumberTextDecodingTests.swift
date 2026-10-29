import Foundation
import Testing
@testable import StoryblokClient

@BlockLibrary
enum ShopBlock: Decodable {
    case product(Product)
    case discount(percent: Int?, label: String)
    case bundle(Bundle)

    struct Product: Decodable {
        let sku: String
        let stock: Int
        let price: Double
        let weight: Float?
        let tax: Decimal
        let reorderAt: Int64?
        let sizes: [Int]?
        let launchedAt: Date?
    }

    struct Bundle: Decodable {
        let title: String
        let product: Story<Product>?
    }
}

@Suite struct NumberTextDecodingTests {

    private let productUuid = "11111111-1111-1111-1111-111111111111"

    private func storyJSON(id: Int, uuid: String, content: String) -> String {
        """
        {
            "id": \(id), "uuid": "\(uuid)", "name": "S\(id)", "content": \(content),
            "slug": "s\(id)", "full_slug": "s\(id)", "created_at": "2025-07-09T14:35:26.851Z",
            "published_at": null, "first_published_at": null, "updated_at": null, "sort_by_date": null,
            "position": 0, "tag_list": [], "is_startpage": false, "parent_id": null, "meta_data": null,
            "group_id": "33333333-3333-3333-3333-333333333333", "release_id": null, "lang": "default",
            "path": null, "alternates": [], "default_full_slug": null, "translated_slugs": null
        }
        """
    }

    /// Decodes `content` as a story's content, the way ``StoryblokClient`` decodes a response.
    private func decode(_ content: String, rels: [String] = []) throws -> ShopBlock {
        let json = """
        {"story": \(storyJSON(id: 1, uuid: "22222222-2222-2222-2222-222222222222", content: content)), "rels": [\(rels.joined(separator: ","))]}
        """
        let decoder = StoryblokClient<ShopBlock>.decoder(resolveLevel: 1)
        return try decoder.decode(ContentResponse<Story<ShopBlock>>.self, from: Data(json.utf8)).payload.content
    }

    private func product(
        stock: String = #""12""#,
        price: String = #""4.5""#,
        weight: String = #""0.25""#,
        tax: String = #""0.2""#,
        reorderAt: String = #""3""#,
        sizes: String = #"["38", "40"]"#
    ) -> String {
        """
        {"component": "product", "sku": "42", "stock": \(stock), "price": \(price), "weight": \(weight), "tax": \(tax), "reorderAt": \(reorderAt), "sizes": \(sizes), "launchedAt": "2025-04-02 10:30"}
        """
    }

    private func decodeProduct(_ content: String) throws -> ShopBlock.Product {
        guard case .product(let product) = try decode(content) else {
            Issue.record("Expected .product")
            throw CancellationError()
        }
        return product
    }

    @Test
    func `Number fields decode into number types`() throws {
        let product = try decodeProduct(product())
        #expect(product.sku == "42")
        #expect(product.stock == 12)
        #expect(product.price == 4.5)
        #expect(product.weight == 0.25)
        #expect(product.tax == Decimal(string: "0.2"))
        #expect(product.reorderAt == 3)
        #expect(product.sizes == [38, 40])
        #expect(product.launchedAt == Date(timeIntervalSince1970: 1_743_589_800))
    }

    @Test
    func `JSON numbers still decode into number types`() throws {
        let product = try decodeProduct(product(stock: "12", price: "4.5", weight: "0.25", tax: "0.2", reorderAt: "3", sizes: "[38, 40]"))
        #expect(product.stock == 12)
        #expect(product.price == 4.5)
        #expect(product.weight == 0.25)
        #expect(product.tax == Decimal(string: "0.2"))
        #expect(product.reorderAt == 3)
        #expect(product.sizes == [38, 40])
    }

    @Test
    func `A blank, null or missing optional Number field decodes as nil`() throws {
        let blank = try decodeProduct(product(weight: #""""#, reorderAt: #""""#))
        let null = try decodeProduct(product(weight: "null", reorderAt: "null"))
        #expect(blank.weight == nil)
        #expect(blank.reorderAt == nil)
        #expect(null.weight == nil)
        #expect(null.reorderAt == nil)

        guard case .discount(let percent, _) = try decode(#"{"component": "discount", "percent": "", "label": "Sale"}"#),
              case .discount(let missing, _) = try decode(#"{"component": "discount", "label": "Sale"}"#)
        else { Issue.record("Expected .discount"); return }
        #expect(percent == nil)
        #expect(missing == nil)
    }

    @Test
    func `A case's associated value decodes from number text`() throws {
        guard case .discount(let percent, let label) = try decode(#"{"component": "discount", "percent": "15", "label": "Sale"}"#) else {
            Issue.record("Expected .discount"); return
        }
        #expect(percent == 15)
        #expect(label == "Sale")
    }

    @Test(arguments: [
        #""""#,          // blank, but required
        #""twelve""#,
        #""12.5""#,      // not a whole number
        #""12abc""#,
        #"true"#,
    ])
    func `A required whole number that is not one throws`(stock: String) {
        #expect(throws: DecodingError.self) { try decodeProduct(product(stock: stock)) }
    }

    @Test(arguments: [#""4.5abc""#, #""inf""#, #""0x10""#, #""4,5""#])
    func `Text that is not a JSON number throws for a decimal`(tax: String) {
        #expect(throws: DecodingError.self) { try decodeProduct(product(tax: tax)) }
        #expect(throws: DecodingError.self) { try decodeProduct(product(price: tax)) }
    }

    @Test
    func `A related story's Number fields decode into number types`() throws {
        let related = storyJSON(id: 2, uuid: productUuid, content: product(stock: #""7""#))
        let block = try decode(#"{"component": "bundle", "title": "Kit", "product": "\#(productUuid)"}"#, rels: [related])
        guard case .bundle(let bundle) = block else { Issue.record("Expected .bundle"); return }
        #expect(bundle.product?.content.stock == 7)
        #expect(bundle.product?.id == 2)
    }
}
