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
    var insertCallCount = 0
    
    func deleteCachedFeed() {
        deleteCachedEventsCallCount += 1
    }

    func completeDeletion(with error: Error, at index: Int = 0) {

    }
}

class EventCachingTests: XCTestCase {
    func test_init_doesNoteDeleteCacheWhenCreated() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.deleteCachedEventsCallCount, 0)
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let events = [uniqueEvent(), uniqueEvent()]
        sut.save(events)
        XCTAssertEqual(store.deleteCachedEventsCallCount, 1)
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let events = [uniqueEvent(), uniqueEvent()]
        let deletionError = NSError(domain: "domain", code: 1)

        sut.save(events)
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.insertCallCount, 0)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalEventLoader, store: EventStore) {
        let store = EventStore()
        let sut = LocalEventLoader(store: store)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }

    private func uniqueEvent() -> Event {
        return Event(id: UUID().uuidString, pubkey: "pubkey", created_at: .now, kind: 1, tags: [[]], content: "Some content", sig: "signature")
    }
}
