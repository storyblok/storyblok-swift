import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `CDN: FilterQueries` {

    /**
     * Learn how to use filter queries with field-level translation in Storyblok by extending field keys with i18n and language codes for multilingual content filtering.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/field-level-translation
     */
    @Test
    func `Filter Queries with Field-level Translation`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[headline__i18n__es_co][in]", value: "Sinfonía de la Tierra: Navegar por las maravillas y los desafíos de nuestro oasis azul"),
            URLQueryItem(name: "version", value: "published"),
            URLQueryItem(name: "language", value: "es-co")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Use filter queries to target nestable bloks and fields.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/nested-blocks-and-fields
     */
    @Test
    func `Filter Queries with Nestable Blocks and Fields`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[body.0.name][in]", value: "This is a nested blok")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter stories by checking if a field contains all of the values provided in the query.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-all-in-array
     */
    @Test
    func all_in_array() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[topics][all_in_array]", value: "solar-system,space-exploration")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter stories by checking if a field contains any of the values provided in the query.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-any-in-array
     */
    @Test
    func any_in_array() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[topics][any_in_array]", value: "solar-system,space-exploration")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter to return stories with a date field value greater than the provided date.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-gt-date
     */
    @Test
    func gt_date() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[scheduled][gt_date]", value: "2023-12-31 09:00")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter to return stories with a float field value greater than the provided float.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-gt-float
     */
    @Test
    func gt_float() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[price][gt_float]", value: "1199.99")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter to return stories with an integer field value greater than the provided integer.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-gt-int
     */
    @Test
    func gt_int() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[price][gt_int]", value: "1200")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter to return stories with a field value matching any of the provided values.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-in
     */
    @Test
    func `in`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[categories][in]", value: "space-exploration,solar-system")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter to return stories with a field value of a specific type.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-is
     */
    @Test
    func `is`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[author][is]", value: "not_empty_array")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter to return stories with a field value matching a specific pattern.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-like
     */
    @Test
    func like() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[headline][like]", value: "*space*")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter to return stories with a date field value less than the provided date.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-lt-date
     */
    @Test
    func lt_date() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[scheduled][lt_date]", value: "2023-12-31 09:00")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter to return stories with a float field value less than the provided float.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-lt-float
     */
    @Test
    func lt_float() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[price][lt_float]", value: "1199.99")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter to return stories with an integer field value less than the provided integer.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-lt-int
     */
    @Test
    func lt_int() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[price][lt_int]", value: "1200")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter to return stories with a field value not matching any of the provided values.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-not-in
     */
    @Test
    func not_in() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[categories][not_in]", value: "space-exploration,culture")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Filter to return stories with a field value not matching any of the provided patterns.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-not-like
     */
    @Test
    func not_like() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filter_query[headline][not_like]", value: "*Mysteries*")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Example showing how to filter stories by boolean field values using the 'in' operation in Storyblok's filter queries.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/examples/filtering-stories-by-a-boolean-value
     */
    @Test
    func `Filtering Stories by a Boolean Value`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "starts_with", value: "articles/"),
            URLQueryItem(name: "filter_query[highlighted][in]", value: "true")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Learn how to filter stories within a specific value range using gt_float and lt_float for price filtering and similar use cases.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/examples/filtering-stories-by-defining-a-value-range
     */
    @Test
    func `Filtering Stories by Defining a Value Range`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "starts_with", value: "products/"),
            URLQueryItem(name: "filter_query[price][lt_float]", value: "300"),
            URLQueryItem(name: "filter_query[price][gt_float]", value: "100")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}
