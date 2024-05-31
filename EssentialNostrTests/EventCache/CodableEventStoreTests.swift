//
//  Created by Jericho Hasselbush on 5/31/24.
//

import XCTest
import EssentialNostr

class CodableEventStore {
    func retrieve(completion: @escaping EventStore.RetrievalCompletion) {
        completion(.success([]))
    }
}

class CodableEventStoreTests: XCTestCase {
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableEventStore()
        let exp = expectation(description: "Wait for store retrieval")
        sut.retrieve { result in
            switch result {
            case let .success(events):
                XCTAssertTrue(events.isEmpty)
                break
            default:
                XCTFail("Expected success, got \(result) instead")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }
}
