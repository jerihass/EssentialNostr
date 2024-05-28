//
//  Created by Jericho Hasselbush on 5/26/24.
//

import XCTest
import EssentialNostr

class EventCachingTests: XCTestCase {
    func test_init_doesNoteMessageCacheWhenCreated() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let events = [uniqueEvent(), uniqueEvent()]
        sut.save(events)
        XCTAssertEqual(store.receivedMessages, [.deleteCachedEvents])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let events = [uniqueEvent(), uniqueEvent()]
        let deletionError = NSError(domain: "domain", code: 1)

        sut.save(events)
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedEvents])
    }

    func test_save_requestsNewCacheInsertionOnSuccessfulDeletion() {
        let (sut, store) = makeSUT()
        let events = [uniqueEvent(), uniqueEvent()]

        sut.save(events)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedEvents, .insert(events)])
    }

    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let events = [uniqueEvent(), uniqueEvent()]
        let deletionError = NSError(domain: "domain", code: 1)

        let exp = expectation(description: "Wait for save completion")

        var capturedError: Error?
        sut.save(events) { error in
            capturedError = error
            exp.fulfill()
        }

        store.completeDeletion(with: deletionError)
        waitForExpectations(timeout: 1)

        XCTAssertEqual(capturedError as NSError?, deletionError)
    }

    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let events = [uniqueEvent(), uniqueEvent()]
        let insertionError = NSError(domain: "domain", code: 1)

        let exp = expectation(description: "Wait for save completion")

        var capturedError: Error?
        sut.save(events) { error in
            capturedError = error
            exp.fulfill()
        }
        
        store.completeDeletionSuccessfully()
        store.completeInsertion(with: insertionError)
        waitForExpectations(timeout: 1)

        XCTAssertEqual(capturedError as NSError?, insertionError)
    }

    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        let events = [uniqueEvent(), uniqueEvent()]

        let exp = expectation(description: "Wait for save completion")

        var capturedError: Error?
        sut.save(events) { error in
            capturedError = error
            exp.fulfill()
        }

        store.completeDeletionSuccessfully()
        store.completeInsertionSuccessfully()
        waitForExpectations(timeout: 1)

        XCTAssertNil(capturedError)
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
