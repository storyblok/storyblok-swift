import Foundation
import Testing

@Suite struct `CDN: Datasources` {

    /**
     * Retrieve a single datasource by ID using Storyblok's Content Delivery API to access key-value pairs for options and settings.
     * https://www.storyblok.com/docs/api/content-delivery/v2/datasources/retrieve-a-single-datasource
     */
    @Test
    func `Retrieve a Single Datasource`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/datasources/product-labels?token=ask9soUkv02QqbZgmZdeDAtt")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Retrieve multiple datasource entries with filtering by datasource and dimension using Storyblok's Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/datasources/retrieve-multiple-datasource-entries
     */
    @Test
    func `Retrieve Multiple Datasource Entries`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/datasource_entries/?datasource=product-labels&dimension=de&token=ask9soUkv02QqbZgmZdeDAtt")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Retrieve all datasources from your Storyblok space with pagination support using the Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/datasources/retrieve-multiple-datasources
     */
    @Test
    func `Retrieve Multiple Datasources`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/datasources?token=ask9soUkv02QqbZgmZdeDAtt")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}