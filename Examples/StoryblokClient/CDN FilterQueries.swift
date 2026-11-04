import Combine
import Foundation
import Testing
import StoryblokClient

@Suite(.serialized) struct `CDN: FilterQueries` {

    /**
     * Learn how to use filter queries with field-level translation in Storyblok by extending field keys with i18n and language codes for multilingual content filtering.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/field-level-translation
     */
    @Test
    func `Filter Queries with Field-level Translation`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu,
            language: "de"
        )
        
        let stories: Page<Story<Block>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block>) in
                query.parameter("filter_query[description__i18n__de][like]", "Deutsches*")
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Use filter queries to target nestable bloks and fields.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/nested-blocks-and-fields
     */
    @Test
    func `Filter Queries with Nestable Blocks and Fields`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block>) in
                query.parameter("filter_query[body.0.headline][in]", "Hello Earth!")
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter stories by checking if a field contains all of the values provided in the query.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-all-in-array
     */
    @Test
    func all_in_array() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Post>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Post>) in
                query.filter {
                    $0.categories.contains(allOf: ["9aa72a2f-04ae-48df-b71f-25f53044dc97", "84550816-245d-4fe6-8ae8-b633d4a328f4"])
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter stories by checking if a field contains any of the values provided in the query.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-any-in-array
     */
    @Test
    func any_in_array() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Post>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Post>) in
                query.filter {
                    $0.categories.contains(anyOf: ["9aa72a2f-04ae-48df-b71f-25f53044dc97", "84550816-245d-4fe6-8ae8-b633d4a328f4"])
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter to return stories with a date field value greater than the provided date.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-gt-date
     */
    @Test
    func gt_date() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Post>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Post>) in
                query.filter {
                    $0.schedule > ISO8601DateFormatter().date(from: "2026-10-15T09:00:00Z")!
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter to return stories with a float field value greater than the provided float.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-gt-float
     */
    @Test
    func gt_float() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Product>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Product>) in
                query.filter {
                    $0.price.asDecimal > 300.99
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter to return stories with an integer field value greater than the provided integer.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-gt-int
     */
    @Test
    func gt_int() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Product>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Product>) in
                query.filter {
                    $0.price.asWholeNumber > 1200
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter to return stories with a field value matching any of the provided values.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-in
     */
    @Test
    func `in`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Post>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Post>) in
                query.filter {
                    $0.topics.in(["Design", "Finance"])
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter to return stories with a field value of a specific type.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-is
     */
    @Test
    func `is`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Post>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Post>) in
                query.filter {
                    $0.categories.isNotEmpty
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter to return stories with a field value matching a specific pattern.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-like
     */
    @Test
    func like() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block>) in
                query.parameter("filter_query[name][like]", "*Space*")
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter to return stories with a date field value less than the provided date.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-lt-date
     */
    @Test
    func lt_date() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Post>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Post>) in
                query.filter {
                    $0.schedule < ISO8601DateFormatter().date(from: "2026-10-13T12:00:00Z")!
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter to return stories with a float field value less than the provided float.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-lt-float
     */
    @Test
    func lt_float() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Product>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Product>) in
                query.startsWith = "products"
                query.filter {
                    $0.price.asDecimal < 2.24
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter to return stories with an integer field value less than the provided integer.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-lt-int
     */
    @Test
    func lt_int() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Product>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Product>) in
                query.startsWith = "products/"
                query.filter {
                    $0.price.asWholeNumber < 20
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter to return stories with a field value not matching any of the provided values.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-not-in
     */
    @Test
    func not_in() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Post>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Post>) in
                query.filter {
                    $0.topics.notIn(["Design", "Finance"])
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Filter to return stories with a field value not matching any of the provided patterns.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-not-like
     */
    @Test
    func not_like() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Post>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Post>) in
                query.startsWith = "posts"
                query.filter {
                    $0.description.notLike("*second*")
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Example showing how to filter stories by boolean field values using the 'in' operation in Storyblok's filter queries.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/examples/filtering-stories-by-a-boolean-value
     */
    @Test
    func `Filtering Stories by a Boolean Value`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Post>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Post>) in
                query.startsWith = "posts"
                query.parameter("filter_query[highlighted][in]", "true")
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Learn how to filter stories within a specific value range using gt_float and lt_float for price filtering and similar use cases.
     * https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/examples/filtering-stories-by-defining-a-value-range
     */
    @Test
    func `Filtering Stories by Defining a Value Range`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Product>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Product>) in
                query.startsWith = "products"
                query.filter {
                    $0.price.asDecimal < 300
                    $0.price.asDecimal > 200
                }
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

}