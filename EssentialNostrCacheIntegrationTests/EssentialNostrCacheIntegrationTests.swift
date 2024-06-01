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

        expect(sut, toLoad: [])
    }

    func test_load_deliversEventsSavedOnSeprateInstance() {
        let sutToSave = makeSUT()
        let sutToLoad = makeSUT()
        let events = uniqueEvents().model

        expect(sutToSave, toSave: events)
        expect(sutToLoad, toLoad: events)
    }

    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> LocalEventsLoader {
        let storeURL = testingStoreURL()
        let store = CodableEventStore(storeURL: storeURL)
        let loader = LocalEventsLoader(store: store)
        trackForMemoryLeaks(loader, file: file, line: line)
        return loader
    }

    private func expect(_ sut: LocalEventsLoader, toSave events: [Event], file: StaticString = #file, line: UInt = #line) {

        let saveExp = expectation(description: "Wait for save completion")
        sut.save(events) { saveError in
            XCTAssertNil(saveError, "Expected successful save")
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1)
    }

    private func expect(_ sut: LocalEventsLoader, toLoad events: [Event], file: StaticString = #file, line: UInt = #line) {
        let loadExp = expectation(description: "Wait for load completion")
        sut.load { result in
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
