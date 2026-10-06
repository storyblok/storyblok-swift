---
name: qa-engineer-unit
description: Use when adding or changing unit tests for logic in a target
---

# QA Engineer for Unit Testing

## Responsibilities

- Every behaviour change and bug fix has a test that fails without it.
- Tests stay small, explicit and easy to reason about.
- Direct value assertions win over elaborate mocks.

## Where tests go

| Code under test         | Test target                        | Framework                                      |
| ----------------------- | ---------------------------------- | ---------------------------------------------- |
| `URLSessionExtension`   | `Tests/URLSessionExtensionTests`   | Swift Testing + Mocker                         |
| `StoryblokClient`       | `Tests/StoryblokClientTests`       | Swift Testing + Mocker                         |
| `StoryblokClientMacros` | `Tests/StoryblokClientMacroTests`  | XCTest + `assertMacroExpansion`                |
| `RichTextView`          | `Tests/RichTextViewTests`          | Swift Testing                                  |

`Examples/` is not a test suite. It holds docs snippets that call the live API.

## Patterns

- **Nest every suite that registers mocks inside the target's serialized root suite**
  (`URLSessionExtensionTests` or `StoryblokClientTests`). Mocker's registry is global, and
  `.serialized` only orders the tests and suites *inside* the suite it's on: separate top-level suites
  still run in parallel, so one suite's `Mocker.removeAll()` would clear another's mocks mid-test. From
  another file, nest it through an `extension` of the root suite. Mock-using suites also call
  `Mocker.removeAll()` in `deinit`.
- Name tests with sentences as raw identifiers:
  `` @Test func `adds json content type header on put and post requests`() async throws ``.
- HTTP goes through Mocker: set `configuration.protocolClasses = [MockingURLProtocol.self]`, pass
  the configuration to `URLSession(storyblok:configuration:)`, and `register()` a `Mock` per URL.
  Never hit the network from a unit test.
- Payload fixtures are shaped like what the API (or Visual Editor) really sends, including fields
  the package ignores and `null`s.
- Assert with `#expect` / `try #require`. Measure timing with `ContinuousClock` and an explicit
  tolerance, with a comment explaining it.
- Macro tests assert the full expanded source **and** the diagnostics for invalid input.
- Reuse the fixtures and helpers already in the target's tests before writing new ones.

## Shape

```swift
// Inside the serialized root suite, so it never runs alongside the target's other mock-using suites.
extension URLSessionExtensionTests {

    @Suite(.serialized)
    class Requests {
        let mockConfiguration = URLSessionConfiguration.default

        init() { mockConfiguration.protocolClasses = [MockingURLProtocol.self] }
        deinit { Mocker.removeAll() }

        @Test func `adds json content type header on put and post requests`() async throws {
            let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("mock-api-key")), configuration: mockConfiguration)
            var request = URLRequest(storyblok: storyblok, path: "spaces/123/stories/1234")
            var mock = Mock(url: request.url!, statusCode: 200, data: [.post: Data(), .put: Data()])
            mock.onRequestHandler = OnRequestHandler(requestCallback: { request in
                #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            })
            mock.register()
            request.httpMethod = "PUT"
            _ = try await storyblok.data(for: request)
        }
    }
}
```

## Coverage

For each change: the success case, the failure or missing-data case, and one or two edge cases
(empty, unknown fields, cycles, boundaries). For a bug fix, first confirm the test fails on the
unfixed code.

## Running

One target per process. Two suites bootstrap swift-log, so a combined `swift test` crashes.

```bash
swift test --filter StoryblokClientTests
swift test --filter 'StoryblokClientTests.GetStory'      # one suite
```
