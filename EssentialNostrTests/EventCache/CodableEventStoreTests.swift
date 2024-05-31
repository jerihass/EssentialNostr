//
//  Created by Jericho Hasselbush on 5/31/24.
//

import XCTest
import EssentialNostr

class CodableEventStore {
    func retrieve(completion: @escaping EventStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.success([]))
        }

        let decoder = JSONDecoder()
        let events = try! decoder.decode([LocalEvent].self, from: data)
        completion(.success(events))
    }

    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("event-feed.store")
    func insert(_ events: [LocalEvent], completion: @escaping EventStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(events)
        try! data.write(to: storeURL)
        completion(nil)
    }
}

class CodableEventStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        undoSideEffects()
    }

    override func tearDown() {
        super.tearDown()
        undoSideEffects()
    }

    private func undoSideEffects() {
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("event-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

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

    func test_retrieve_hasNoSideEffects() {
        let sut = CodableEventStore()
        let exp = expectation(description: "Wait for store retrieval")
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case let (.success(firstEvents), .success(secondEvents)):
                    XCTAssertTrue(firstEvents.isEmpty == secondEvents.isEmpty)
                    break
                default:
                    XCTFail("Expected success, got \(firstResult) instead")
                }
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1)
    }

    func test_retrieve_afterInsertingToEmptyCacheRetrievesInsertedValue() {
        let sut = CodableEventStore()
        let exp = expectation(description: "Wait for store retrieval")
        let events = uniqueEvents().local
        sut.insert(events) { insertError in
            XCTAssertNil(insertError)
            sut.retrieve { retrieveResult in
                switch retrieveResult {
                case let .success(insertEvents):
                    XCTAssertEqual(insertEvents, events)
                    break
                default:
                    XCTFail("Expected success, got \(retrieveResult) instead")
                }
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1)
    }
}
