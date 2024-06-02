//
//  Created by Jericho Hasselbush on 6/1/24.
//

import XCTest
import EssentialNostr

extension EventStoreSpecs where Self: XCTestCase {
    func assertThatStoreDeliversEmptyOnEmptyCache(_ sut: EventStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .success([]), file: file, line: line)
    }
    func assertThatRetrieveHasNoSideEffects(_ sut: EventStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieveTwice: .success([]), file: file, line: line)
    }
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(_ sut: EventStore,file: StaticString = #file, line: UInt = #line) {
        let events = uniqueEvents().local

        insert(events, to: sut)

        expect(sut, toRetrieve: .success(events), file: file, line: line)
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
        sut.insert(events) { result in
            if case let .failure(insertError) = result {
                error = insertError
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        return error
    }

    func deleteCache(from sut: EventStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        let exp = expectation(description: "Wait for store insertion")
        var error: Error?
        sut.deleteCachedEvents { result in
            if case let .failure(de) = result {
                error = de
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        return error
    }

    func expect(_ sut: EventStore, toRetrieveTwice expectedResult: EventStore.RetrievalResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

    func expect(_ sut: EventStore, toRetrieve expectedResult: EventStore.RetrievalResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { result in
            switch (result, expectedResult) {
            case let (.success(events), .success(expectedEvents)):
                XCTAssertEqual(
                    events.sorted(by: { e1, e2 in e1.id < e2.id}),
                    expectedEvents.sorted(by: { e1, e2 in e1.id < e2.id}), file: file, line: line)
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
