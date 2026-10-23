import Testing
import Foundation
import URLSessionExtension
@testable import StoryblokClient

/// How `story()` and `stories()` classify a failure into the client's own error.
@Suite
struct ErrorTests {

    struct Library : BlockLibrary {}

    typealias Error = StoryblokClient<Library>.Error

    @Test
    func `a decoding failure stays a decoding failure`() {
        let failure = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "changed"))

        guard case .decoding = Error.from(failure) else {
            Issue.record("expected .decoding")
            return
        }
    }

    @Test
    func `an error response from the API carries its body as the message`() {
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)!
        let failure = Api.ResponseError.client(statusCode: 404, data: Data("not found".utf8), response: response)

        let error = Error.from(failure)

        guard case .api(message: "not found", underlyingError: _) = error else {
            Issue.record("expected .api with the response body, got \(error)")
            return
        }
    }

    @Test
    func `the client's own error passes through unchanged`() {
        let error = Error.from(Error.api(message: "already mapped", underlyingError: nil))

        #expect(error.message == "already mapped")
    }

    @Test
    func `any other failure is a failed request`() {
        guard case .api = Error.from(URLError(.notConnectedToInternet)) else {
            Issue.record("expected .api")
            return
        }
    }
}
