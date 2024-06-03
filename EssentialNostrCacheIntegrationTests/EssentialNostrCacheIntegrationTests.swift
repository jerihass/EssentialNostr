//
//  Created by Jericho Hasselbush on 6/1/24.
//

import XCTest
import SwiftData
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

        expect(sutToSave, toSave: events, overwrite: true)
        expect(sutToLoad, toLoad: events)
    }

    func test_save_appendsEventsSavedOnSeprateInstance() {
        let sutForFirstSave = makeSUT()
        let sutForAppending = makeSUT()
        let sutForLoad = makeSUT()

        let firstEvents = uniqueEvents().model
        let lastEvents = uniqueEvents().model

        expect(sutForFirstSave, toSave: firstEvents, overwrite: true)
        expect(sutForAppending, toSave: lastEvents, overwrite: false)
        expect(sutForLoad, toLoad: firstEvents + lastEvents)
    }

    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> LocalEventsLoader {
        let storeURL = testingStoreURL()
        let schema = SwiftDataEventStore.modelSchema()
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let container = SwiftDataEventStore.container(configuration: configuration)
        let store = SwiftDataEventStore(container: container)
        let loader = LocalEventsLoader(store: store)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return loader
    }

    private func expect(_ sut: LocalEventsLoader, toSave events: [Event], overwrite: Bool = true, file: StaticString = #file, line: UInt = #line) {

        let saveExp = expectation(description: "Wait for save completion")
        sut.save(events, overwrite: overwrite) { saveError in
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
                XCTAssertEqual(loadedEvents.sorted(by: { lh, rh in lh.id < rh.id }),
                               events.sorted(by: { lh, rh in lh.id < rh.id }),
                               "\nLoaded: \(loadedEvents.count) events,\nExpected: \(events.count) events", file: file, line: line)
            case let .failure(error):
                XCTFail("Expected successful events result, got \(error) instead.")
            }
            loadExp.fulfill()
        }
        wait(for: [loadExp], timeout: 1)
    }

    private func testingStoreURL() -> URL {
        FileManager
            .default.urls(for: .cachesDirectory, in: .localDomainMask)
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
