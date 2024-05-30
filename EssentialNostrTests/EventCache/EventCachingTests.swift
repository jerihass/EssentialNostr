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
        let events = uniqueEvents()
        sut.save(events.model) { _ in }
        XCTAssertEqual(store.receivedMessages, [.deleteCachedEvents])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let events = uniqueEvents()
        let deletionError = NSError(domain: "domain", code: 1)

        sut.save(events.model) { _ in }
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedEvents])
    }

    func test_save_requestsNewCacheInsertionOnSuccessfulDeletion() {
        let (sut, store) = makeSUT()
        let events = uniqueEvents()
        sut.save(events.model) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedEvents, .insert(events.local)])
    }

    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = NSError(domain: "domain", code: 1)

        expect(sut, toCompleteWith: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }

    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyError()

        expect(sut, toCompleteWith: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }

    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .none) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }

    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = EventStoreSpy()
        var sut: LocalEventLoader? = LocalEventLoader(store: store)

        var results = [LocalEventLoader.SaveResult]()
        sut?.save([uniqueEvent()]) { results.append($0) }

        sut = nil

        store.completeDeletion(with: anyError())

        XCTAssertTrue(results.isEmpty)
    }

    func test_save_doesNotDeliverInsertiontErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = EventStoreSpy()
        var sut: LocalEventLoader? = LocalEventLoader(store: store)

        var results = [LocalEventLoader.SaveResult]()
        sut?.save([uniqueEvent()]) { results.append($0) }

        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyError())

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalEventLoader, store: EventStoreSpy) {
        let store = EventStoreSpy()
        let sut = LocalEventLoader(store: store)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }

    private func expect(_ sut: LocalEventLoader, toCompleteWith error: NSError?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for save completion")

        var capturedError: Error?
        sut.save(uniqueEvents().model) { error in
            capturedError = error
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(capturedError as NSError?, error, file: file, line: line)
    }

    private func uniqueEvent() -> Event {
        return Event(id: UUID().uuidString, publicKey: "pubkey", created: .now, kind: 1, tags: [[]], content: "Some content", signature: "signature")
    }

    private func uniqueEvents() -> (model: [Event], local: [LocalEvent]) {
        let events = [uniqueEvent(), uniqueEvent()]
        let localEvents = events.map { LocalEvent(id: $0.id, publicKey: $0.publicKey, created: $0.created, kind: $0.kind, tags: $0.tags, content: $0.content, signature: $0.signature)}
        return (events, localEvents)
    }

    private func anyError() -> NSError {
        NSError(domain: "domain", code: 1)
    }
}
