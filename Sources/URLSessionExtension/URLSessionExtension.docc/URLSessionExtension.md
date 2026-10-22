# ``URLSessionExtension``

A [URLSession](https://developer.apple.com/documentation/foundation/urlsession) extension to simplify calling Storyblok's Content Delivery and Management APIs.

With out-of-the-box support for authentication, regions, cache invalidation, error and rate limit handling, and more.

Read <doc:UserGuide> to get started.

## Topics

### Essentials

- <doc:UserGuide>

### Creating a session

- ``URLSessionExtension/Foundation/URLSession/init(storyblok:configuration:)``
- ``URLSessionExtension/Foundation/URLSession/init(storyblok:configuration:delegate:delegateQueue:)``
- ``Api``

### Making a request

- ``URLSessionExtension/Foundation/URLRequest/init(storyblok:path:cachePolicy:timeoutInterval:)``

### Showing cached responses while revalidating

- ``URLSessionExtension/Foundation/URLSession/cachedDataTaskPublisher(for:)-(URLRequest)``
- ``URLSessionExtension/Foundation/URLSession/cachedDataTaskPublisher(for:)-(URL)``
- ``URLSessionExtension/Foundation/URLSession/CachedDataTaskPublisher``

### Paging through results

- ``URLSessionExtension/Foundation/URLSession/pagePublisher(for:page:perPage:upstream:elements:)``
- ``URLSessionExtension/Foundation/URLSession/PagePublisher``
- ``Page``

### Retrying failed requests

- ``URLSessionExtension/Combine/Publisher/failOnErrorResponse(_:)``
- ``URLSessionExtension/Api/ErrorResponseType``
- ``URLSessionExtension/Api/ResponseError``

