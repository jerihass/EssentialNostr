//
//  Created by Jericho Hasselbush on 5/29/24.
//

import XCTest
import EssentialNostr

class LoadEventsFromCacheTests: XCTestCase {
    func test_init_doesNoteMessageCacheWhenCreated() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_load_requestCacheRetrieval() {
        let (sut, store) = makeSUT()

        sut.load() { _ in }

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let error = anyError()
        let exp = expectation(description: "Wait for load completion")

        var receivedError: Error?
        sut.load { result in
            if case let .failure(error) = result {
                receivedError = error
            } else {
                XCTFail("Expected failure, got \(result) instead")
            }
            exp.fulfill()
        }
        store.completeRetrieval(with: error)

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(receivedError as NSError?, error)
    }

    func test_load_deliversNoEventsOnEmptyCache() {
        let (sut, store) = makeSUT()
        let exp = expectation(description: "Wait for load completion")

        var receivedEvents: [Event]?
        sut.load { result in
            if case let .success(events) = result {
                receivedEvents = events
            } else {
                XCTFail("Expected success, got \(result) instead")
            }
            exp.fulfill()
        }
        store.completeRetrievalWithEmptyCache()

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(receivedEvents, [])
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalEventsLoader, store: EventStoreSpy) {
        let store = EventStoreSpy()
        let sut = LocalEventsLoader(store: store)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
}
