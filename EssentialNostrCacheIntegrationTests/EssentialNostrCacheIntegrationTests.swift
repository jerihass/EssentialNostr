//
//  Created by Jericho Hasselbush on 6/1/24.
//

import XCTest
import EssentialNostr

final class EssentialNostrCacheIntegrationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }
    
    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()

        let exp = expectation(description: "wait for load completion")

        sut.load { result in
            switch result {
            case let .success(events):
                XCTAssertEqual(events, [], "Expected empty events")
            case let .failure(error):
                XCTFail("Expected successful events result, got \(error) instead.")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func test_load_deliversEventsSavedOnSeprateInstance() {
        let sutToSave = makeSUT()
        let sutToLoad = makeSUT()
        let events = uniqueEvents().model

        let saveExp = expectation(description: "Wait for save completion")
        sutToSave.save(events) { saveError in
            XCTAssertNil(saveError, "Expected successful save")
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1)

        let loadExp = expectation(description: "Wait for load completion")
        sutToLoad.load { result in
            switch result {
            case let .success(loadedEvents):
                XCTAssertEqual(loadedEvents, events, "Expected empty events")
            case let .failure(error):
                XCTFail("Expected successful events result, got \(error) instead.")
            }
            loadExp.fulfill()
        }
        wait(for: [loadExp], timeout: 1)

    }

    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> LocalEventsLoader {
        let storeURL = testingStoreURL()
        let store = CodableEventStore(storeURL: storeURL)
        let loader = LocalEventsLoader(store: store)
        trackForMemoryLeaks(loader, file: file, line: line)
        return loader
    }

    private func testingStoreURL() -> URL {
        FileManager
            .default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("\(type(of: self)).store")
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
}
