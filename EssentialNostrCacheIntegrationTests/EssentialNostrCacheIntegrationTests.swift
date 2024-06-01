//
//  Created by Jericho Hasselbush on 6/1/24.
//

import XCTest
import EssentialNostr

final class EssentialNostrCacheIntegrationTests: XCTestCase {
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
}
