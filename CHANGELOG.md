### Changelog

**main**

- Made `attributedString(baseFont:)` on `RichTextComposite` and `RichText.Text` public, so custom `RichTextViewDelegate` implementations can render inline rich text content themselves.

**0.3.0**

- Renamed `Blok` to `Block` throughout the Rich Text View for consistency. A deprecated `Blok` typealias and `blok(_:)` factory are provided for backward compatibility.
- Removed a redundant `Story` initializer.

**0.2.0**

- Initial release of the Storyblok Client
- Initial release of the Rich Text View
- Added JetNews sample app

**0.1.0**

- Initial release of the URLSession Extension
