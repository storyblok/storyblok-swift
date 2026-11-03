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
        let reorderAt: Int?
        let views: Int64
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
        views: String = #""5000000000""#
    ) -> String {
        """
        {"component": "product", "sku": "42", "stock": \(stock), "price": \(price), "weight": \(weight), "tax": \(tax), "reorderAt": \(reorderAt), "views": \(views), "launchedAt": "2025-04-02 10:30"}
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
        #expect(product.views == 5_000_000_000)
        #expect(product.launchedAt == Date(timeIntervalSince1970: 1_743_589_800))
    }

    @Test
    func `JSON numbers still decode into number types`() throws {
        let product = try decodeProduct(
            product(stock: "12", price: "4.5", weight: "0.25", tax: "0.2", reorderAt: "3", views: "5000000000")
        )
        #expect(product.stock == 12)
        #expect(product.price == 4.5)
        #expect(product.weight == 0.25)
        #expect(product.tax == Decimal(string: "0.2"))
        #expect(product.reorderAt == 3)
        #expect(product.views == 5_000_000_000)
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

    @Test(arguments: [
        #""four""#,
        #""12abc""#,     // a number followed by text
        #""1,5""#,       // a decimal comma
        #""-""#,
        #"" ""#,
        #""nan""#,
        #""inf""#,
        #""0x10""#,
        #""1e3""#,       // an exponent, which the Visual Editor never writes
    ])
    func `Text that is not a plain decimal throws for a decimal`(text: String) {
        #expect(throws: DecodingError.self) { try decodeProduct(product(tax: text)) }
        #expect(throws: DecodingError.self) { try decodeProduct(product(price: text)) }
        #expect(throws: DecodingError.self) { try decodeProduct(product(weight: text)) }
    }

    @Test
    func `A number too large for a Float throws rather than decoding as infinity`() {
        let text = #""1\#(String(repeating: "0", count: 39))""#
        #expect(throws: DecodingError.self) { try decodeProduct(product(weight: text)) }
    }

    @Test
    func `Negative and whole number text decodes into a decimal`() throws {
        let product = try decodeProduct(product(price: #""-4""#, tax: #""-0.25""#))
        #expect(product.price == -4)
        #expect(product.tax == Decimal(string: "-0.25"))
    }

    @Test
    func `A blank required Number field says to make it optional`() {
        do {
            _ = try decodeProduct(product(tax: #""""#))
            Issue.record("Expected an error")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.debugDescription.contains("Cannot decode Decimal from an empty string"))
            #expect(context.debugDescription.contains("optional property"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func `A value that is neither a number nor text keeps the number's type mismatch`() {
        do {
            _ = try decodeProduct(product(stock: "true"))
            Issue.record("Expected an error")
        } catch DecodingError.typeMismatch(let type, _) {
            #expect(ObjectIdentifier(type) == ObjectIdentifier(Int.self))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func `A mismatch that is not text does not ask the decoder for a super decoder`() {
        struct Plain: Decodable { let stock: Int }

        #expect(throws: DecodingError.self) { try Plain(from: BoolsDecoder()) }
    }

    @Test
    func `A model in a file that does not import StoryblokClient reads text only as a Decimal`() throws {
        let decoder = StoryblokClient<ShopBlock>.decoder(resolveLevel: 1)

        let model = try decoder.decode(ForeignProduct.self, from: Data(#"{"stock": 12, "tax": "0.2"}"#.utf8))
        #expect(model.tax == Decimal(string: "0.2"))
        // The standard library's `Int` overload wins in that file, as the UserGuide says.
        #expect(throws: DecodingError.self) {
            try decoder.decode(ForeignProduct.self, from: Data(#"{"stock": "12", "tax": 1}"#.utf8))
        }
    }

    @Test
    func `A related story's Number fields decode into number types`() throws {
        let related = storyJSON(id: 2, uuid: productUuid, content: product(stock: #""7""#))
        let block = try decode(#"{"component": "bundle", "title": "Kit", "product": "\#(productUuid)"}"#, rels: [related])
        guard case .bundle(let bundle) = block else { Issue.record("Expected .bundle"); return }
        #expect(bundle.product?.content.stock == 7)
        #expect(bundle.product?.id == 2)
    }

    @Test
    func `A decoder other than the client's is unaffected`() {
        struct Plain: Decodable { let stock: Int }

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Plain.self, from: Data(#"{"stock": "12"}"#.utf8))
        }
    }
}

/// A decoder whose every value is `true`, and whose `superDecoder(forKey:)` must not be reached, since a custom
/// decoder's may trap.
private struct BoolsDecoder: Decoder {
    struct Unsupported: Error {}

    var codingPath: [any CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key> {
        KeyedDecodingContainer(Container())
    }
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer { throw Unsupported() }
    func singleValueContainer() throws -> any SingleValueDecodingContainer { throw Unsupported() }

    struct Container<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var codingPath: [any CodingKey] { [] }
        var allKeys: [Key] { [] }

        func contains(_ key: Key) -> Bool { true }
        func decodeNil(forKey key: Key) -> Bool { false }
        func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
            guard let value = true as? T else {
                throw DecodingError.typeMismatch(T.self, .init(codingPath: [key], debugDescription: "Only true"))
            }
            return value
        }
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy type: NestedKey.Type,
            forKey key: Key
        ) throws -> KeyedDecodingContainer<NestedKey> { throw Unsupported() }
        func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer { throw Unsupported() }
        func superDecoder() throws -> any Decoder { throw Unsupported() }
        func superDecoder(forKey key: Key) throws -> any Decoder {
            Issue.record("superDecoder(forKey:) reached for a value that is not text")
            throw Unsupported()
        }
    }
}
