//
//  Created by Jericho Hasselbush on 6/1/24.
//

import XCTest
import SwiftData
import EssentialNostr

@available(macOS 14, *)
class SwiftDataEventStore: EventStore {
    func deleteCachedEvents(completion: @escaping DeletionCompletion) {

    }
    
    func insert(_ events: [EssentialNostr.LocalEvent], completion: @escaping InsertionCompletion) {

    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.success([]))
    }

    @Model
    class SDEvent {
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
    }
}

@available(macOS 14, *)
class SwiftDataEventStoreTests: XCTestCase, EventStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = SwiftDataEventStore()
        assertThatStoreDeliversEmptyOnEmptyCache(sut)
    }
    
    func test_retrieve_hasNoSideEffects() {
        let sut = SwiftDataEventStore()
        assertThatRetrieveHasNoSideEffects(sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {

    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {

    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {

    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {

    }
    
    func test_insert_appendsCacheValuesToPreviousValues() {

    }
    
    func test_insert_deliversErroOnInsertionError() {

    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {

    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {

    }
    
    func test_delete_deliversErrorOnDeletionError() {

    }
    
    func test_storeSideEffects_runSerially() {

    }
}
