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

        var results = [Error?]()
        sut?.save([uniqueEvent()]) { results.append($0) }

        sut = nil

        store.completeDeletion(with: anyError())

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
        sut.save([uniqueEvent()]) { error in
            capturedError = error
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(capturedError as NSError?, error, file: file, line: line)
    }

    private func uniqueEvent() -> Event {
        return Event(id: UUID().uuidString, pubkey: "pubkey", created_at: .now, kind: 1, tags: [[]], content: "Some content", sig: "signature")
    }

    private func anyError() -> NSError {
        NSError(domain: "domain", code: 1)
    }

    public class EventStoreSpy: EventStore {
        public enum ReceivedMessage: Equatable {
            case insert([Event])
            case deleteCachedEvents
        }

        private(set) public var receivedMessages = [ReceivedMessage]()
        public init() {}

        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()

        public func deleteCachedEvents(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCachedEvents)
        }

        public func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }

        public func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }

        public func insert(_ events: [Event], completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(events))
        }

        public func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }

        public func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
}
