# ``URLSessionExtension``

An [URLSession](https://developer.apple.com/documentation/foundation/urlsession) extension to simplify calling Storyblok's Content Delivery and Management APIs.

With out-of-the-box support for authentication, regions, cache invalidation, error and rate limit handling, and more.

Read <doc:UserGuide> to get started.

## Topics

### Creating a session

- ``URLSessionExtension/Foundation/URLSession/init(storyblok:configuration:)``
- ``URLSessionExtension/Foundation/URLSession/init(storyblok:configuration:delegate:delegateQueue:)``
- ``Api``

### Making a request

- ``URLSessionExtension/Foundation/URLRequest/init(storyblok:path:cachePolicy:timeoutInterval:)``

### Retrying failed requests

- ``URLSessionExtension/Combine/Publisher/failOnErrorResponse(_:)``
- ``URLSessionExtension/Api/ErrorResponseType``
- ``URLSessionExtension/Api/ResponseError``

