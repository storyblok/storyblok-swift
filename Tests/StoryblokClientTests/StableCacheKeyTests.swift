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
        // The API appends cv to the end of the Location it redirects a published request to and percent encodes
        // the comma in resolve_relations; the client puts cv first and leaves the comma literal.
        let ours = client(cv: "mock-cv").buildRequest(path: "stories/mock-slug", findByUuid: false, resolveLevel: 1)
        let theirs = URL(string: "https://api.storyblok.com/v2/cdn/stories/mock-slug?token=mock-api-key&version=published&resolve_relations=\(Block.relations.replacingOccurrences(of: ",", with: "%2C"))&cv=mock-cv")!

        #expect(ours.url!.absoluteString == theirs.sortingQueryItems().absoluteString)
    }

    @Test func `the redirect normalizer respells the new request the way later requests ask for it`() async {
        // the API's spelling of a Location: token first, cv appended at the end
        let theirs = URL(string: "https://api.storyblok.com/v2/cdn/stories/mock-slug?token=mock-api-key&version=published&cv=mock-cv")!
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

        #expect(result?.url?.query() == "cv=mock-cv&token=mock-api-key&version=published")
    }
}
