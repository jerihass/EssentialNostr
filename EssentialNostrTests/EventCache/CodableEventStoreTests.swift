//
//  Created by Jericho Hasselbush on 5/31/24.
//

import XCTest
import EssentialNostr

class CodableEventStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrieve: .success([]))
    }

    func test_retrieve_hasNoSideEffects() {
        let sut = makeSUT()

        expect(sut, toRetrieveTwice: .success([]))
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let events = uniqueEvents().local

        insert(events, to: sut)

        expect(sut, toRetrieve: .success(events))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let events = uniqueEvents().local

        insert(events, to: sut)

        expect(sut, toRetrieveTwice: .success(events))
    }

    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testingStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalidData".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieve: .failure(anyError()))
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testingStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalidData".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieveTwice: .failure(anyError()))
    }

    func test_insert_appendsCacheValuesToPreviousValues() {
        let sut = makeSUT()
        let events = uniqueEvents().local
        let events2 = uniqueEvents().local

        let firstError = insert(events, to: sut)
        XCTAssertNil(firstError, "Expected first insertion success")

        let secondError = insert(events2, to: sut)
        XCTAssertNil(secondError, "Expected first insertion success")

        expect(sut, toRetrieve: .success(events + events2))
    }

    func test_insert_deliversErroOnInsertionError() {
        let invalidURL = URL(string: "invalid://store")!
        let sut = makeSUT(storeURL: invalidURL)
        let events = uniqueEvents().local

        let insertError = insert(events, to: sut)

        XCTAssertNotNil(insertError)
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Exepected cache deletion to succeed")
        expect(sut, toRetrieve: .success([]))
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        let events = uniqueEvents().local
        insert(events, to: sut)

        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Exepected cache deletion to succeed")
        expect(sut, toRetrieve: .success([]))
    }

    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        let events = uniqueEvents().local
        insert(events, to: sut)

        let deletionError = deleteCache(from: sut)

        XCTAssertNotNil(deletionError, "Exepected cache deletion to fail")
    }

    // MARK: - Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> EventStore {
        let sut = CodableEventStore(storeURL: storeURL ?? testingStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    @discardableResult
    private func insert(_ events: [LocalEvent], to sut: EventStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        let exp = expectation(description: "Wait for store insertion")
        var error: Error?
        sut.insert(events) { insertError in
            error = insertError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        return error
    }

    private func deleteCache(from sut: EventStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        let exp = expectation(description: "Wait for store insertion")
        var error: Error?
        sut.deleteCachedEvents { deleteError in
            error = deleteError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        return error
    }

    private func expect(_ sut: EventStore, toRetrieveTwice expectedResult: Result<[LocalEvent], Error>, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }

    private func expect(_ sut: EventStore, toRetrieve expectedResult:  Result<[LocalEvent], Error>, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { result in
            switch (result, expectedResult) {
            case let (.success(events), .success(expectedEvents)):
                XCTAssertEqual(events, expectedEvents)
            case (.failure, .failure):
                break
            default:
                XCTFail("Expected \(expectedResult), got \(result) instead")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testingStoreURL())
    }

    private func testingStoreURL() -> URL {
        FileManager
            .default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("\(type(of: self)).store")
    }
}
