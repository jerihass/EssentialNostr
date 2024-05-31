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

        expect(sut, toRetrieve: .success([]))
        expect(sut, toRetrieve: .success([]))
    }

    func test_retrieve_afterInsertingToEmptyCacheRetrievesInsertedValue() {
        let sut = makeSUT()
        let events = uniqueEvents().local
        let exp = expectation(description: "Wait for store retrieval")

        sut.insert(events) { insertError in
            XCTAssertNil(insertError)
            exp.fulfill()
        }        
        wait(for: [exp], timeout: 1)

        expect(sut, toRetrieve: .success(events))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let events = uniqueEvents().local
        let exp = expectation(description: "Wait for store retrieval")
        
        sut.insert(events) { insertError in
            XCTAssertNil(insertError)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        expect(sut, toRetrieve: .success(events))
        expect(sut, toRetrieve: .success(events))
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableEventStore {
        let storeURL = testStoreURL()

        let sut = CodableEventStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func expect(_ sut: CodableEventStore, toRetrieve expectedResult:  Result<[LocalEvent], Error>, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { result in
            switch (result, expectedResult) {
            case let (.success(events), .success(expectedEvents)):
                XCTAssertEqual(events, expectedEvents)
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
        try? FileManager.default.removeItem(at: testStoreURL())
    }

    private func testStoreURL() -> URL {
        FileManager
            .default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("\(type(of: self)).store")
    }
}
