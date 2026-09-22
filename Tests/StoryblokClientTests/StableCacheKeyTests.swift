import Foundation
import Testing
import URLSessionExtension
@testable import StoryblokClient

/// `URLCache` keys an entry on the request URL exactly as written, so every request for a resource has to be
/// spelled the same way or the cached value ``StoryblokClient/story(_:resolveLevel:)-(String,_)`` looks for
/// first is stored somewhere it never reads.
@Suite
struct StableCacheKeys {

    private func client(cv: String? = nil) -> StoryblokClient<Block> {
        StoryblokClient(library: Block.self, accessToken: "mock-api-key", cv: cv)
    }

    @Test func `query parameter names are sorted so the same request is always spelled the same way`() {
        let request = client(cv: "mock-cv").buildRequest(path: "stories/mock-slug", findByUuid: true, resolveLevel: 2)
        let names = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!.map(\.name)

        #expect(names == ["cv", "find_by", "resolve_level", "resolve_relations", "token", "version"])
        #expect(names == names.sorted(), "the order items were appended in must not show through")
    }

    @Test func `repeated query items keep the order they were given`() {
        // Only names are ordered. A repeated name's values are a sequence the API answers to, not a set.
        let sorted = URL(string: "https://api.storyblok.com/v2/cdn/stories?token=k&by_uuids_ordered=third&by_uuids_ordered=first&by_uuids_ordered=second")!
            .sortingQueryItems()
        let items = URLComponents(url: sorted, resolvingAgainstBaseURL: false)!.queryItems!

        #expect(items.map(\.name) == ["by_uuids_ordered", "by_uuids_ordered", "by_uuids_ordered", "token"])
        #expect(items.filter { $0.name == "by_uuids_ordered" }.map(\.value) == ["third", "first", "second"])
    }

    @Test func `the cdn's spelling of a request and the library's own spelling agree`() {
        // The Location the API redirects a published request to carries its query items sorted by name, with the
        // comma in resolve_relations percent encoded. The client sorts too, so the encoding is what differs.
        let ours = client(cv: "mock-cv").buildRequest(path: "stories/mock-slug", findByUuid: false, resolveLevel: 1)
        let theirs = URL(string: "https://api.storyblok.com/v2/cdn/stories/mock-slug?cv=mock-cv&resolve_relations=\(Block.relations.replacingOccurrences(of: ",", with: "%2C"))&token=mock-api-key&version=published")!

        #expect(ours.url!.absoluteString == theirs.sortingQueryItems().absoluteString)
    }

    @Test func `a space the API writes as a plus meets the one the client percent encodes`() {
        // The API escapes with Ruby's CGI.escape, which writes a space as `+`; URLComponents writes `%20` and
        // reads `+` back as a literal plus, so without help the two spellings never meet.
        var mine = URLComponents(string: "https://api.storyblok.com/v2/cdn/stories")!
        mine.queryItems = [
            URLQueryItem(name: "search_term", value: "a b~c"),
            URLQueryItem(name: "token", value: "mock-api-key"),
        ]
        let theirs = URL(string: "https://api.storyblok.com/v2/cdn/stories?search_term=a+b~c&token=mock-api-key")!

        #expect(mine.url!.query() == "search_term=a%20b~c&token=mock-api-key", "URLComponents percent encodes it")
        #expect(mine.url!.sortingQueryItems().absoluteString == theirs.sortingQueryItems().absoluteString)
    }

    @Test func `a plus the API meant literally survives`() {
        // CGI.escape writes a literal plus as %2B, so it must neither be read as a space nor written back as a
        // bare plus, which the API would then read as one.
        let url = URL(string: "https://api.storyblok.com/v2/cdn/stories?search_term=1%2B1&token=k")!
        let normalized = url.sortingQueryItems()

        #expect(normalized.query() == "search_term=1%2B1&token=k")
        let value = URLComponents(url: normalized, resolvingAgainstBaseURL: false)!
            .queryItems!.first { $0.name == "search_term" }!.value
        #expect(value == "1+1")
    }

    @Test func `the redirect normalizer respells the new request the way later requests ask for it`() async {
        // The API returns a Location already sorted by name, so in practice it is the percent encoded comma that
        // has to be respelled. Fed an unsorted one as well here, since the normalizer does not rely on that.
        let theirs = URL(string: "https://api.storyblok.com/v2/cdn/stories/mock-slug?token=mock-api-key&resolve_relations=post.author%2Crecent.posts&cv=mock-cv")!
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }

        let result: URLRequest? = await withCheckedContinuation { continuation in
            RedirectNormalizer().urlSession(
                session,
                task: session.dataTask(with: theirs),
                willPerformHTTPRedirection: HTTPURLResponse(url: theirs, statusCode: 301, httpVersion: nil, headerFields: nil)!,
                newRequest: URLRequest(url: theirs)
            ) { continuation.resume(returning: $0) }
        }

        #expect(result?.url?.query() == "cv=mock-cv&resolve_relations=post.author,recent.posts&token=mock-api-key")
    }
}
