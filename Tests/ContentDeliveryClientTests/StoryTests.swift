import Foundation
import Testing
@testable import ContentDeliveryClient

@Suite struct StoryTests {

    struct PageContent: ContentDeliveryClient.Block, Equatable {
        let component: String
        let title: String?
    }

    private func makeDecoder() -> JSONDecoder {
        StoryblokClient(accessToken: "mock").decoder
    }

    @Test
    func `Story deserializes from JSON with example values from OpenAPI spec`() throws {
        let jsonString = """
        {
            "id": 1,
            "uuid": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Home",
            "content": {
                "_uid": "54bac0c7-bf25-46d0-ba66-a0ea51091a8d",
                "component": "page",
                "title": ""
            },
            "slug": "home",
            "full_slug": "home",
            "created_at": "2025-07-09T14:35:26.851Z",
            "published_at": "2025-07-09T14:35:26.851Z",
            "first_published_at": "2025-07-09T14:35:26.851Z",
            "updated_at": "2025-07-09T14:35:26.851Z",
            "sort_by_date": "2025-07-09",
            "position": 1,
            "tag_list": ["home"],
            "is_startpage": true,
            "parent_id": 1,
            "meta_data": null,
            "group_id": "57350688-5a28-49d1-b5a9-086ae0d4c0d2",
            "release_id": 1,
            "lang": "default",
            "path": "/home",
            "alternates": [
                {
                    "id": 12345,
                    "name": "Home ES",
                    "slug": "home-es",
                    "published": true,
                    "full_slug": "home-es",
                    "is_folder": false,
                    "parent_id": 0
                }
            ],
            "default_full_slug": "home/",
            "translated_slugs": [
                {
                    "path": "library/",
                    "name": "library",
                    "lang": "es",
                    "published": true
                }
            ]
        }
        """

        let data = jsonString.data(using: .utf8)!
        let story = try makeDecoder().decode(Story<PageContent>.self, from: data)

        #expect(story.id == 1)
        #expect(story.uuid.uuidString.lowercased() == "123e4567-e89b-12d3-a456-426614174000")
        #expect(story.name == "Home")
        #expect(story.content.component == "page")
        #expect(story.slug == "home")
        #expect(story.fullSlug == "home")

        let expected = ISO8601DateFormatter()
        expected.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedTimestamp = expected.date(from: "2025-07-09T14:35:26.851Z")!
        #expect(story.createdAt == expectedTimestamp)
        #expect(story.publishedAt == expectedTimestamp)
        #expect(story.firstPublishedAt == expectedTimestamp)
        #expect(story.updatedAt == expectedTimestamp)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        #expect(story.sortByDate == dateFormatter.date(from: "2025-07-09"))

        #expect(story.position == 1)
        #expect(story.tagList == ["home"])
        #expect(story.isStartPage == true)
        #expect(story.parentId == 1)
        #expect(story.metadata == nil)
        #expect(story.groupId.uuidString.lowercased() == "57350688-5a28-49d1-b5a9-086ae0d4c0d2")
        #expect(story.releaseId == 1)
        #expect(story.language == "default")
        #expect(story.path == "/home")
        #expect(story.defaultFullSlug == "home/")

        #expect(story.alternates.count == 1)
        let alternate = story.alternates[0]
        #expect(alternate.id == 12345)
        #expect(alternate.name == "Home ES")
        #expect(alternate.slug == "home-es")
        #expect(alternate.published == true)
        #expect(alternate.fullSlug == "home-es")
        #expect(alternate.isFolder == false)
        #expect(alternate.parentId == 0)

        #expect(story.translatedSlugs?.count == 1)
        let translatedSlug = story.translatedSlugs![0]
        #expect(translatedSlug.path == "library/")
        #expect(translatedSlug.name == "library")
        #expect(translatedSlug.language == "es")
        #expect(translatedSlug.published == true)
    }

    @Test
    func `Story deserializes from JSON with null optional fields`() throws {
        let jsonString = """
        {
            "id": 1,
            "uuid": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Home",
            "content": {
                "_uid": "54bac0c7-bf25-46d0-ba66-a0ea51091a8d",
                "component": "page"
            },
            "slug": "home",
            "full_slug": "home",
            "created_at": "2025-07-09T14:35:26.851Z",
            "published_at": null,
            "first_published_at": null,
            "updated_at": null,
            "sort_by_date": null,
            "position": 1,
            "tag_list": [],
            "is_startpage": false,
            "parent_id": null,
            "meta_data": null,
            "group_id": "57350688-5a28-49d1-b5a9-086ae0d4c0d2",
            "release_id": null,
            "lang": "default",
            "path": null,
            "alternates": [],
            "default_full_slug": null,
            "translated_slugs": null
        }
        """

        let data = jsonString.data(using: .utf8)!
        let story = try makeDecoder().decode(Story<PageContent>.self, from: data)

        #expect(story.id == 1)
        #expect(story.name == "Home")
        #expect(story.publishedAt == nil)
        #expect(story.firstPublishedAt == nil)
        #expect(story.updatedAt == nil)
        #expect(story.sortByDate == nil)
        #expect(story.tagList == [])
        #expect(story.isStartPage == false)
        #expect(story.parentId == nil)
        #expect(story.metadata == nil)
        #expect(story.releaseId == nil)
        #expect(story.path == nil)
        #expect(story.alternates.isEmpty)
        #expect(story.defaultFullSlug == nil)
        #expect(story.translatedSlugs == nil)
    }
}
