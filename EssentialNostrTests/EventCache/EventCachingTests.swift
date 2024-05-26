//
//  Created by Jericho Hasselbush on 5/26/24.
//

import XCTest
import EssentialNostr

class LocalEventLoader {
    private let store: EventStore
    init(store: EventStore) {
        self.store = store
    }

    func save(_ events: [Event]) {
        store.deleteCachedFeed()
    }
}

class EventStore {
    var deleteCachedEventsCallCount = 0
    func deleteCachedFeed() {
        deleteCachedEventsCallCount += 1
    }
}

class EventCachingTests: XCTestCase {
    func test_init_doesNoteDeleteCacheWhenCreated() {
        let store = EventStore()
        _ = LocalEventLoader(store: store)
        XCTAssertEqual(store.deleteCachedEventsCallCount, 0)
    }

    func test_save_requestsCacheDeletion() {
        let store = EventStore()
        let sut = LocalEventLoader(store: store)
        let events = [uniqueEvent(), uniqueEvent()]
        sut.save(events)
        XCTAssertEqual(store.deleteCachedEventsCallCount, 1)
    }

    // MARK: - Helpers

    private func uniqueEvent() -> Event {
        return Event(id: UUID().uuidString, pubkey: "pubkey", created_at: .now, kind: 1, tags: [[]], content: "Some content", sig: "signature")
    }
}
