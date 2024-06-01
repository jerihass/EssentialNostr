//
//  Created by Jericho Hasselbush on 6/1/24.
//

import XCTest
import EssentialNostr

extension EventStoreSpecs where Self: XCTestCase {
    func assertThatStoreDeliversEmptyOnEmptyCache(_ sut: EventStore) {
        expect(sut, toRetrieve: .success([]))
    }
    func assertThatRetrieveHasNoSideEffects(_ sut: EventStore) {
        expect(sut, toRetrieveTwice: .success([]))
    }
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(_ sut: EventStore) {
        let events = uniqueEvents().local

        insert(events, to: sut)

        expect(sut, toRetrieve: .success(events))
    }
    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(_ sut: EventStore) {
        let events = uniqueEvents().local

        insert(events, to: sut)

        expect(sut, toRetrieveTwice: .success(events))
    }
    func assertThatRetrieveDeliversFailureOnRetrievalError(_ sut: EventStore) {
        expect(sut, toRetrieve: .failure(anyError()))
    }
    func assertThatRetrieveHasNoSideEffectsOnFailure(_ sut: EventStore) {
        expect(sut, toRetrieveTwice: .failure(anyError()))
    }
    func assertThatInsertAppendsCacheValuesToPreviousValues(_ sut: EventStore) {
        let events = uniqueEvents().local
        let events2 = uniqueEvents().local

        let firstError = insert(events, to: sut)
        XCTAssertNil(firstError, "Expected first insertion success")

        let secondError = insert(events2, to: sut)
        XCTAssertNil(secondError, "Expected first insertion success")

        expect(sut, toRetrieve: .success(events + events2))
    }
    func assertThatInsertDeliversErrorOnInsertionError(_ sut: EventStore) {
        let events = uniqueEvents().local

        let insertError = insert(events, to: sut)

        XCTAssertNotNil(insertError)
    }
    func assertThatDeleteHasNoSideEffectsOnEmptyCache(_ sut: EventStore) {
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Exepected cache deletion to succeed")
        expect(sut, toRetrieve: .success([]))
    }
    func assertThatDeleteEmptiesPreviouslyInsertedCache(_ sut: EventStore) {
        let events = uniqueEvents().local
        insert(events, to: sut)

        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Exepected cache deletion to succeed")
        expect(sut, toRetrieve: .success([]))
    }
    func assertThatDeleteDeliversErrorOnDeletionError(_ sut: EventStore) {
        let events = uniqueEvents().local
        insert(events, to: sut)

        let deletionError = deleteCache(from: sut)

        XCTAssertNotNil(deletionError, "Exepected cache deletion to fail")
    }

    @discardableResult
    func insert(_ events: [LocalEvent], to sut: EventStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        let exp = expectation(description: "Wait for store insertion")
        var error: Error?
        sut.insert(events) { insertError in
            error = insertError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        return error
    }

    func deleteCache(from sut: EventStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        let exp = expectation(description: "Wait for store insertion")
        var error: Error?
        sut.deleteCachedEvents { deleteError in
            error = deleteError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        return error
    }

    func expect(_ sut: EventStore, toRetrieveTwice expectedResult: Result<[LocalEvent], Error>, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }

    func expect(_ sut: EventStore, toRetrieve expectedResult:  Result<[LocalEvent], Error>, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { result in
            switch (result, expectedResult) {
            case let (.success(events), .success(expectedEvents)):
                XCTAssertEqual(events, expectedEvents, file: file, line: line)
            case (.failure, .failure):
                break
            default:
                XCTFail("Expected \(expectedResult), got \(result) instead")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }
}
