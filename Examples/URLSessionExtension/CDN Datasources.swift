import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `CDN: Datasources` {

    /**
     * Retrieve a single datasource by ID using Storyblok's Content Delivery API to access key-value pairs for options and settings.
     * https://www.storyblok.com/docs/api/content-delivery/v2/datasources/retrieve-a-single-datasource
     */
    @Test
    func `Retrieve a Single Datasource`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        let request = URLRequest(storyblok: storyblok, path: "datasources/product-labels")
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Retrieve multiple datasource entries with filtering by datasource and dimension using Storyblok's Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/datasources/retrieve-multiple-datasource-entries
     */
    @Test
    func `Retrieve Multiple Datasource Entries`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "datasource_entries/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "datasource", value: "product-labels"),
            URLQueryItem(name: "dimension", value: "de")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Retrieve all datasources from your Storyblok space with pagination support using the Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/datasources/retrieve-multiple-datasources
     */
    @Test
    func `Retrieve Multiple Datasources`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        let request = URLRequest(storyblok: storyblok, path: "datasources")
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}
