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
        do {
            let decoder = JSONDecoder()
            let codableEvents = try decoder.decode([CodableEvent].self, from: data)
            let events = codableEvents.map(\.local)
            completion(.success(events))
        } catch {
            completion(.failure(error))
        }
    }

    func insert(_ events: [LocalEvent], completion: @escaping EventStore.InsertionCompletion) {
        var storedEvents: [LocalEvent]?
        retrieve { result in
            storedEvents = try? result.get()
        }
        var tempEvents = events
        tempEvents.insert(contentsOf: storedEvents ?? [], at: 0)

        do {
            let encoder = JSONEncoder()
            let codableEvents = tempEvents.map(CodableEvent.init)
            let data = try encoder.encode(codableEvents)
            try data.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
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

        expect(sut, toRetrieveTwice: .success([]))
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let events = uniqueEvents().local

        insert(events, to: sut)

        expect(sut, toRetrieve: .success(events))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let events = uniqueEvents().local

        insert(events, to: sut)

        expect(sut, toRetrieveTwice: .success(events))
    }

    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalidData".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieve: .failure(anyError()))
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalidData".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieveTwice: .failure(anyError()))
    }

    func test_insert_appendsCacheValuesToPreviousValues() {
        let sut = makeSUT()
        let events = uniqueEvents().local
        let events2 = uniqueEvents().local

        let firstError = insert(events, to: sut)
        XCTAssertNil(firstError, "Expected first insertion success")

        let secondError = insert(events2, to: sut)
        XCTAssertNil(secondError, "Expected first insertion success")

        expect(sut, toRetrieve: .success(events + events2))
    }

    func test_insert_deliversErroOnInsertionError() {
        let invalidURL = URL(string: "invalid://store")!
        let sut = makeSUT(storeURL: invalidURL)
        let events = uniqueEvents().local

        let insertError = insert(events, to: sut)

        XCTAssertNotNil(insertError)
    }

    // MARK: - Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodableEventStore {
        let sut = CodableEventStore(storeURL: storeURL ?? testStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    @discardableResult
    private func insert(_ events: [LocalEvent], to sut: CodableEventStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        let exp = expectation(description: "Wait for store insertion")
        var error: Error?
        sut.insert(events) { insertError in
            error = insertError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        return error
    }

    private func expect(_ sut: CodableEventStore, toRetrieveTwice expectedResult: Result<[LocalEvent], Error>, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }

    private func expect(_ sut: CodableEventStore, toRetrieve expectedResult:  Result<[LocalEvent], Error>, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { result in
            switch (result, expectedResult) {
            case let (.success(events), .success(expectedEvents)):
                XCTAssertEqual(events, expectedEvents)
            case (.failure, .failure):
                break
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
