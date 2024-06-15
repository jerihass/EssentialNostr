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

        expect(sut, toLoadWith: .failure(error)) {
            store.completeRetrieval(with: error)
        }
    }

    func test_load_deliversNoEventsOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toLoadWith: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }
    }

    func test_load_deliversEventsOnNonEmptyCache() {
        let (sut, store) = makeSUT()
        let events = uniqueEvents()
        expect(sut, toLoadWith: .success(events.model)) {
            store.completeRetrieval(with: events.local)
        }
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = EventStoreSpy()
        var sut: LocalEventsLoader? = LocalEventsLoader(store: store)

        var results = [FeedLoader.LoadResult]()
        sut?.load { results.append($0) }

        sut = nil

        store.completeRetrievalWithEmptyCache()

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalEventsLoader, store: EventStoreSpy) {
        let store = EventStoreSpy()
        let sut = LocalEventsLoader(store: store)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }

    func expect(_ sut: LocalEventsLoader, toLoadWith expectedResult: FeedLoader.LoadResult, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {

        let exp = expectation(description: "Wait for load completion")

        sut.load { result in
            switch (result, expectedResult) {
            case let (.success(gotEvents), .success(expectedEvents)):
                XCTAssertEqual(gotEvents, expectedEvents, file: file, line: line)
            case let (.failure(gotError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(gotError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1)
    }
}
