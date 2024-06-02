//
//  Created by Jericho Hasselbush on 6/1/24.
//

import XCTest
import SwiftData
import EssentialNostr

@available(macOS 14, *)
class SwiftDataEventStore: EventStore {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func deleteCachedEvents(completion: @escaping DeletionCompletion) {
        completion(nil)
    }
    
    @MainActor func insert(_ events: [EssentialNostr.LocalEvent], completion: @escaping InsertionCompletion) {
        let sdEvents = events.toSwiftData()
        for event in sdEvents { container.mainContext.insert(event) }
        completion(nil)
    }
    
    @MainActor func retrieve(completion: @escaping RetrievalCompletion) {
        let sdEvents = FetchDescriptor<SDEvent>()
        do {
            let events = try container.mainContext.fetch(sdEvents)
            let found = events.map(\.local)
            completion(.success(found))
        } catch {
            completion(.failure(error))
        }
    }
}

@Model
private class SDEvent {
    public let id: String
    public let publickey: String
    public let created: Date
    public let kind: UInt16
    public let tags: [[String]]
    public let content: String
    public let signature: String

    public init(id: String, publicKey: String, created: Date, kind: UInt16, tags: [[String]], content: String, signature: String) {
        self.id = id
        self.publickey = publicKey
        self.created = created
        self.kind = kind
        self.tags = tags
        self.content = content
        self.signature = signature
    }

    var local: LocalEvent {
        LocalEvent(id: id, publicKey: publickey, created: created, kind: kind, tags: tags, content: content, signature: signature)
    }
}

extension Array where Element == LocalEvent {
    fileprivate func toSwiftData() -> [SDEvent] {
        map {
            SDEvent(id: $0.id, publicKey: $0.publickey, created: $0.created, kind: $0.kind, tags: $0.tags, content: $0.content, signature: $0.signature)
        }
    }
}

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

    }
    
    func test_delete_deliversErrorOnDeletionError() {

    }
    
    func test_storeSideEffects_runSerially() {

    }

    // MARK: - Helpers

    func makeSUT(configuration: ModelConfiguration? = nil) -> SwiftDataEventStore {
        let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: SDEvent.self, configurations: configuration ?? memoryConfig)
        let sut = SwiftDataEventStore(container: container)
        trackForMemoryLeaks(sut)
        return sut
    }
}
