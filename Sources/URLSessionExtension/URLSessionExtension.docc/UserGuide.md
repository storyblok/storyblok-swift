# Calling Storyblok's APIs with URLSession

How to use the Storyblok [URLSession](https://developer.apple.com/documentation/foundation/urlsession) extension to call the Content Delivery and Management APIs.

## Getting Started

### Add package dependency

Add the *storyblok-swift* repository as a package to your `Package.swift` file and specify `URLSessionExtension` as a dependency of the Target in which you wish to use it:

```swift
dependencies: [
    …
    .package(url: "https://github.com/storyblok/storyblok-swift.git", .upToNextMajor(from: "0.1.0"))
]
targets: [
    .target(
        …
        dependencies: ["URLSessionExtension"]
    )
]
```

### Create a session

To create a session, use the Storyblok `URLSession` convenience initializer:

```swift
let storyblok = URLSession(storyblok: .cdn(accessToken: "YOUR_ACCESS_TOKEN"))
```

API requests must be authenticated by providing an API access token. Learn more in the [Access Tokens concept](https://www.storyblok.com/docs/concepts/access-tokens).

### Make a request

To create a request, use the Storyblok `URLRequest` [convenience initializer](doc:Foundation/URLRequest/init(storyblok:path:cachePolicy:timeoutInterval:)). The initializer adds the base URL so you can just pass the relative path of the endpoint you want to call. You can then [receive data directly into memory by creating a data task](https://developer.apple.com/documentation/foundation/fetching-website-data-into-memory#overview):


```swift
var request = URLRequest(storyblok: storyblok, path: "stories")
request.url!.append(queryItems: [
    URLQueryItem(name: "starts_with", value: "articles"),
    URLQueryItem(name: "search_term", value: "mars"),
])
let (data, response) = try await storyblok.data(for: request)
```

## Detailed Guide
---

## Initialization

You create a `URLSession` for the Storyblok APIs using one of the [convenience initializers](doc:URLSessionExtension) provided by the extension, these take an additional ``Api`` argument which configures the `URLSession` for calling either the [Content Delivery API](https://www.storyblok.com/docs/api/content-delivery/v2) or the [Management API](https://www.storyblok.com/docs/api/management). 

Via the associated values of ``Api/cdn(accessToken:language:fallbackLanguage:version:cv:region:requestsPerSecond:)`` and ``Api/mapi(accessToken:region:requestsPerSecond:)`` you can configure the following:

### Authentication

As API requests must be authenticated, you'll need to provide an access token. The Content Delivery API requires a read-only access token, whilst the Management API requires either an [OAuth](doc:Api/AccessToken/oauth(_:)) or [personal](doc:Api/AccessToken/personal(_:)) access token. You can learn more about authentication in the [Access Tokens concept](https://www.storyblok.com/docs/concepts/access-tokens).

**Content Delivery API**

```swift
let storyblok = URLSession(storyblok: .cdn(accessToken: "YOUR_ACCESS_TOKEN"))
```
**Management API**

```swift
let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_ACCESS_TOKEN")))
//...or...
let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACESSS_TOKEN")))
```

### Specifying a region

By default, the session uses the [EU](doc:Api/Region/eu) region, if your space is located in a [different region](doc:Api/Region) you can set it:

```swift
let storyblok = URLSession(storyblok: .cdn(region: .usa))
```
**Custom region**

You can also specify a [custom region](doc:Api/Region/custom(url:)) by providing a custom base URL:

```swift
let storyblok = URLSession(storyblok: .cdn(region: .custom(url: URL(string: "https://app.storyblokchina.cn/cdn")!)))
```

### Rate limit handling

The Content Delivery and Management APIs have different rate limits depending on the [type of request](https://www.storyblok.com/docs/api/content-delivery/v2/getting-started/rate-limit) and your [pricing plan](https://www.storyblok.com/pricing/technical-limits), these are expressed in requests per second.

The plugin implements *API throttling* to slow down the API requests by introducing intermediate delays. You can specify the maximum number of requests per second allowed:

```swift
let storyblok = URLSession(storyblok: .mapi(requestsPerSecond: 3))
```

> Note: The value of `requestsPerSecond` defaults to `1000` for the Content Delivery API and `6` for the Management API.

 As the rate limit can differ on the type of request, and you can only configure `requestsPerSecond` per `URLSession` instance, you'll need to create a new session when you need to make requests with a different rate limit. 

> Warning: Be careful when using multiple sessions concurrently as the requests sent to the API from their combined usage may still exceed the rate limit.

If you do exceed the rate limit, the API will respond with HTTP status error code 429, see <doc:UserGuide#Retrying-failed-requests> on how to handle this.

### Configuring default parameters for all requests

> Important: Default parameters are only available for the Content Delivery API.

You can optionally set [default parameters](doc:Api/cdn(accessToken:language:fallbackLanguage:version:cv:region:requestsPerSecond:)) that are applied to all requests:

```swift
let storyblok = URLSession(storyblok: .cdn(
    language: "en", // language to retrieve resources
    fallbackLanguage: "de", // language for untranslated fields
    version: .draft, // the version of resources to retrieve
    cv: "1706094649", // cached version Unix timestamp
))
```

**CV parameter handling**

By specifying a default value for the `cv` parameter you can retrieve a specific [cached version](https://www.storyblok.com/docs/api/content-delivery/v2/getting-started/cache-invalidation) of a published resource, otherwise, the `cv` parameter will be automatically set the to the latest version of the space after the first request to the Content Delivery API.

The responses from the Content Delivery API are cached locally by `URLSession`, both in memory and on disk. To serve subsequent requests for the same resource from the cache instead of performing a network request, the Storyblok `URLRequest` [convenience initializer](doc:Foundation/URLRequest/init(storyblok:path:cachePolicy:timeoutInterval:)) will automatically set [`cachePolicy`](https://developer.apple.com/documentation/foundation/urlrequest/cachepolicy-swift.property) to [`returnCacheDataElseLoad`](https://developer.apple.com/documentation/foundation/nsurlrequest/cachepolicy-swift.enum/returncachedataelseload) when requesting published resources.

## Usage

Once you have created a `URLSession` for the Storyblok APIs you can create requests using [`URLRequest.init(storyblok:path:cachePolicy:timeoutInterval:)`](doc:Foundation/URLRequest/init(storyblok:path:cachePolicy:timeoutInterval:)) and perform them via  [`URLSession.data(for:)`](https://developer.apple.com/documentation/foundation/urlsession/data(for:)) as shown above in <doc:UserGuide#Make-a-request>.

### Retrying failed requests

Requests to the Storyblok APIs can fail due to network errors or the API responding with an HTTP status error code. These failures include transient errors which can be recovered by retrying the request. 

You can use Combine to easily [retry transient network errors](https://developer.apple.com/documentation/foundation/processing-url-session-data-task-results-with-combine#Retry-transient-errors-and-catch-and-replace-persistent-errors) and with the help of the ``URLSessionExtension/Combine/Publisher/failOnErrorResponse(_:)`` operator you can also retry recoverable HTTP status error codes returned by the API:

 ```swift
storyblok.dataTaskPublisher(for: URLRequest(storyblok: storyblok, path: "spaces/123/stories/1234"))
    .failOnErrorResponse(.recoverable)
    .retry(5)
    .failOnErrorResponse(.all)
    .catch { error in
        switch(error) {
            case Api.ResponseError.client(let statusCode, let data, let response): switch(statusCode) {
                case 400: fatalError("The wrong format was sent (e.g., XML instead of JSON).")
                case 401: fatalError("No valid API key was provided.")
                case 404: fatalError("The requested resource doesn’t exist (e.g., due to not yet published content entries).")
                case 422: fatalError("The request was unacceptable, often due to missing a required parameter.")
                case 429: fatalError("Too many requests hit the API too quickly.")
                default: print(error.localizedDescription)
            }
            default: print(error.localizedDescription)
        }
        return Empty<(data: Data, response: URLResponse), Never>()
    }
```

The pattern in the example above can be used as a robust way to handle failed requests:
- The initial [`dataTaskPublisher(for:)`](https://developer.apple.com/documentation/foundation/urlsession/datataskpublisher(for:)-61v3e) returns a publisher that will publish a [URLError](https://developer.apple.com/documentation/foundation/urlerror/) on network failure.
- While [`failOnErrorResponse(.recoverable)`](doc:URLSessionExtension/Combine/Publisher/failOnErrorResponse(_:)) will publish a [`ResponseError`](doc:URLSessionExtension/Api/ResponseError) on recieving a tranisent error response from the API.
- [`retry(5)`](https://developer.apple.com/documentation/combine/publisher/retry(_:)) will reattempt the request up to five times on any errors published by `dataTaskPublisher(for:)` and `failOnErrorResponse(.recoverable)`.
- For unrecoverable error responses, [`failOnErrorResponse(.all)`](doc:URLSessionExtension/Combine/Publisher/failOnErrorResponse(_:)) will publish a [`ResponseError`](doc:URLSessionExtension/Api/ResponseError) on recieving any other error response from the API.
- Finally, [`catch`](https://developer.apple.com/documentation/combine/publisher/catch(_:)) will handle any errors published by the preceeding `failOnErrorResponse(.all)`, in addition to errors thrown by the preceeding `retry(5)` in the case the fifth and final retry also resulted in failure.

In the catch closure you would need to decide how to handle the error; the example above handles [common client errors](https://www.storyblok.com/docs/api/content-delivery/v2/getting-started/errors) (`4xx`) which would usually indicate programmer error (with the possible exception of `404`) by stopping execution.

**Introducing delays between retries**

Sessions created with the Storyblok `URLSession` [convenience initializer](doc:URLSessionExtension/Foundation/URLSession/init(storyblok:configuration:)) introduce an exponential delay of up to 60 seconds before resuming requests when one fails due to a tranisent error. 

The delay is automatically applied before retries and all other pending requests made with the same `URLSession` instance.

> Tip: Depending on your scenerio it could also be benefial to enable  [waitsForConnectivity](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/waitsforconnectivity) on the [`URLSessionConfiguration`](https://developer.apple.com/documentation/foundation/urlsessionconfiguration) when [creating](doc:URLSessionExtension/Foundation/URLSession/init(storyblok:configuration:)) your session.

### Working with JSON 

All Storyblok APIs responses, including errors, return JSON which you can convert to objects and values [using Foundation APIs](https://developer.apple.com/documentation/foundation/archives-and-serialization/#overview) or [with Combine operators](https://developer.apple.com/documentation/foundation/processing-url-session-data-task-results-with-combine#Convert-incoming-raw-data-to-your-types-with-Combine-operators). 

Requests bodies should also be sent as JSON, and the content type of requests is automatically set to `application/json` by the Storyblok `URLRequest` [convenience initializer](doc:Foundation/URLRequest/init(storyblok:path:cachePolicy:timeoutInterval:)).

**JSONSerialization example**

```swift
var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories")
request.httpMethod = "POST"
request.httpBody = try JSONSerialization.data(withJSONObject: [
    "publish": 1,
    "story": [
        "content": [
            "body": [ ],
            "component": "page",
        ],
        "name": "Story Name",
        "slug": "story-name",
    ],
])
let (data, _) = try await storyblok.data(for: request)
let body = try JSONSerialization.jsonObject(with: data) as! [String: Any]
let story = body["story"] as! [String: Any]
print("Story \(story["name"]!) created")
```

**Codable example**

```swift
struct Content: Codable {
    var component: String
    var body: [String]
}
struct Story: Codable {
    var name: String
    var slug: String
    var content: Content
}
struct Body: Codable {
    var publish: Int = 0
    var story: Story
}

var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories")
request.httpMethod = "POST"
request.httpBody = try JSONEncoder().encode(Body(
    publish: 1,
    story: Story(
        name: "Story Name",
        slug: "story-name",
        content: Content(
            component: "page",
            body: []
        )
    )
))
let (data, _) = try await storyblok.data(for: request)
let body = try JSONDecoder().decode(Body.self, from: data)
print("Story \(body.story.name) created")
```

## See Also

- ``URLSessionExtension/Foundation/URLSession/init(storyblok:configuration:)``
- ``Api``
- [Article: Fetching website data into memory](https://developer.apple.com/documentation/foundation/fetching-website-data-into-memory)
- [Article: Accessing cached data](https://developer.apple.com/documentation/foundation/accessing-cached-data)
- [Technical Q&A QA1941: Handling “The network connection was lost” Errors](https://developer.apple.com/library/archive/qa/qa1941/_index.html#//apple_ref/doc/uid/DTS40017602)
- [Article: Processing URL session data task results with Combine](https://developer.apple.com/documentation/foundation/processing-url-session-data-task-results-with-combine)
- [API Collection: Archives and Serialization](https://developer.apple.com/documentation/foundation/archives-and-serialization/)
- [Article: Encoding and Decoding Custom Types](https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types)
