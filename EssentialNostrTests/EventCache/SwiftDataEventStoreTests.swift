//
//  Created by Jericho Hasselbush on 6/1/24.
//

import XCTest
import SwiftData
import EssentialNostr

@available(macOS 14, *)
class SwiftDataEventStoreTests: XCTestCase, EventStoreSpecs {

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
        // How to force swift data to have retrieve error?
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {
        // How to force swift data to have retrieve error?
    }
    
    func test_insert_appendsCacheValuesToPreviousValues() {
        let sut = makeSUT()
        assertThatInsertAppendsCacheValuesToPreviousValues(sut)
    }
    
    func test_insert_deliversErroOnInsertionError() {
        // How to force swift data to have insert error?
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
        // How to force swift data to have delete error?
    }
    
    @MainActor func test_storeSideEffects_runSerially() {
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
        XCTAssertEqual(completedOps, [op1, op2, op3])    }

    // MARK: - Helpers

    func makeSUT(configuration: ModelConfiguration? = nil) -> SwiftDataEventStore {
        let memoryConfig = SwiftDataEventStore.modelConfig(inMemory: true)
        let container = SwiftDataEventStore.container(configuration: memoryConfig)
        let sut = SwiftDataEventStore(container: container)
        trackForMemoryLeaks(sut)
        return sut
    }
}
