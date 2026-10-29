import Foundation
import Testing
@testable import StoryblokClient

@BlockLibrary
enum EventBlock: Decodable {
    case event(Event)
    case reminder(title: String, due: Date?)

    struct Event: Decodable {
        let title: String
        let startsAt: Date
        let endsAt: Date?
    }
}

@Suite struct DateDecodingTests {

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try StoryblokClient<EventBlock>.makeDecoder().decode(type, from: Data(json.utf8))
    }

    @Test
    func `A blank optional date in a content struct decodes as nil`() throws {
        let block = try decode(EventBlock.self, #"{"component": "event", "title": "Launch", "startsAt": "2025-04-02 10:30", "endsAt": ""}"#)
        guard case .event(let event) = block else { Issue.record("Expected .event, got \(block)"); return }
        #expect(event.endsAt == nil)
        #expect(event.startsAt == Date(timeIntervalSince1970: 1_743_589_800))
    }

    @Test
    func `A blank optional date in a case's associated value decodes as nil`() throws {
        let block = try decode(EventBlock.self, #"{"component": "reminder", "title": "Renew", "due": ""}"#)
        guard case .reminder(_, let due) = block else { Issue.record("Expected .reminder, got \(block)"); return }
        #expect(due == nil)
    }

    @Test
    func `A null or missing optional date decodes as nil`() throws {
        let null = try decode(EventBlock.Event.self, #"{"title": "Launch", "startsAt": "2025-04-02 10:30", "endsAt": null}"#)
        let missing = try decode(EventBlock.Event.self, #"{"title": "Launch", "startsAt": "2025-04-02 10:30"}"#)
        #expect(null.endsAt == nil)
        #expect(missing.endsAt == nil)
    }

    @Test
    func `A blank required date still throws`() {
        #expect(throws: DecodingError.self) {
            try decode(EventBlock.Event.self, #"{"title": "Launch", "startsAt": ""}"#)
        }
    }

    @Test
    func `An unparseable optional date still throws`() {
        #expect(throws: DecodingError.self) {
            try decode(EventBlock.Event.self, #"{"title": "Launch", "startsAt": "2025-04-02 10:30", "endsAt": "soon"}"#)
        }
    }

    @Test
    func `A blank sort_by_date decodes as nil`() throws {
        let story = try decode(Story<EventBlock>.self, """
        {
            "id": 1,
            "uuid": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Launch",
            "content": {"component": "reminder", "title": "Renew", "due": null},
            "slug": "launch",
            "full_slug": "launch",
            "created_at": "2025-07-09T14:35:26.851Z",
            "sort_by_date": "",
            "position": 1,
            "tag_list": [],
            "is_startpage": false,
            "group_id": "57350688-5a28-49d1-b5a9-086ae0d4c0d2",
            "lang": "default",
            "alternates": []
        }
        """)
        #expect(story.sortByDate == nil)
    }
}
