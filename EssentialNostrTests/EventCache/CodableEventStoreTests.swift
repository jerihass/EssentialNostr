//
//  Created by Jericho Hasselbush on 5/31/24.
//

import XCTest
import EssentialNostr

class CodableEventStoreTests: XCTestCase, EventStoreSpecs {
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
        assertThatStoreDeliversEmptyOnEmptyCache(sut)
    }

    func test_retrieve_hasNoSideEffects() {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffects(sut)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(sut)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(sut)
    }

    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testingStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalidData".write(to: storeURL, atomically: false, encoding: .utf8)

        assertThatRetrieveDeliversFailureOnRetrievalError(sut)
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testingStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalidData".write(to: storeURL, atomically: false, encoding: .utf8)

        assertThatRetrieveHasNoSideEffectsOnFailure(sut)
    }

    func test_insert_appendsCacheValuesToPreviousValues() {
        let sut = makeSUT()
        assertThatInsertAppendsCacheValuesToPreviousValues(sut)
    }

    func test_insert_deliversErroOnInsertionError() {
        let invalidURL = URL(string: "invalid://store")!
        let sut = makeSUT(storeURL: invalidURL)
        assertThatInsertDeliversErrorOnInsertionError(sut)
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        assertThatDeleteHasNoSideEffectsOnEmptyCache(sut)
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        assertThatDeleteEmptiesPreviouslyInsertedCache(sut)
    }

    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        assertThatDeleteDeliversErrorOnDeletionError(sut)
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()

        var completedOps = [XCTestExpectation]()
        let op1 = expectation(description: "Operation 1")
        sut.insert(uniqueEvents().local) { _ in
            completedOps.append(op1)
            op1.fulfill()
        }

        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedEvents { _ in
            completedOps.append(op2)
            op2.fulfill()
        }

        let op3 = expectation(description: "Operation 3")
        sut.insert(uniqueEvents().local) { _ in
            completedOps.append(op3)
            op3.fulfill()
        }

        wait(for: [op1, op2, op3], enforceOrder: true)
        XCTAssertEqual(completedOps, [op1, op2, op3])
    }

    // MARK: - Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> EventStore {
        let sut = CodableEventStore(storeURL: storeURL ?? testingStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
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
