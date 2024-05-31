//
//  Created by Jericho Hasselbush on 5/31/24.
//

import XCTest
import EssentialNostr

class CodableEventStore {
    private let storeURL: URL

    init(storeURL: URL) {
        self.storeURL = storeURL
    }

    func retrieve(completion: @escaping EventStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.success([]))
        }

        let decoder = JSONDecoder()
        let codableEvents = try! decoder.decode([CodableEvent].self, from: data)
        let events = codableEvents.map(\.local)
        completion(.success(events))
    }

    func insert(_ events: [LocalEvent], completion: @escaping EventStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let codableEvents = events.map(CodableEvent.init)
        let data = try! encoder.encode(codableEvents)
        try! data.write(to: storeURL)
        completion(nil)
    }

    private struct CodableEvent: Codable {
        private let id: String
        private let publickey: String
        private let created: Date
        private let kind: UInt16
        private let tags: [[String]]
        private let content: String
        private let signature: String

        init(id: String, publicKey: String, created: Date, kind: UInt16, tags: [[String]], content: String, signature: String) {
            self.id = id
            self.publickey = publicKey
            self.created = created
            self.kind = kind
            self.tags = tags
            self.content = content
            self.signature = signature
        }

        init(_ event: LocalEvent) {
            id = event.id
            publickey = event.publickey
            created = event.created
            kind = event.kind
            tags = event.tags
            content = event.content
            signature = event.signature
        }

        var local: LocalEvent {
            LocalEvent(id: self.id, publicKey: self.publickey, created: self.created, kind: self.kind, tags: self.tags, content: self.content, signature: self.signature)
        }
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
        try? FileManager.default.removeItem(at: testStoreURL())
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
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
        let sut = makeSUT()
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
        let sut = makeSUT()
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

    // MARK: - Helpers

    func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableEventStore {
        let storeURL = testStoreURL()

        let sut = CodableEventStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func testStoreURL() -> URL {
        FileManager
            .default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("\(type(of: self)).store")
    }
}
