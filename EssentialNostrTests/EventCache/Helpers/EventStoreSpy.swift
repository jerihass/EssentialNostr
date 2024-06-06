//
//  Created by Jericho Hasselbush on 5/29/24.
//

import Foundation
import EssentialNostr

class EventStoreSpy: EventStore {
    enum ReceivedMessage: Equatable {
        case insert([LocalEvent])
        case deleteCachedEvents
        case retrieve
    }

    private(set) public var receivedMessages = [ReceivedMessage]()
    init() {}

    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private var retrievalCompletions = [RetrievalCompletion]()

    func deleteCachedEvents(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedEvents)
    }

    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](.failure(error))
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](.success(()))
    }

    func insert(_ events: [LocalEvent], completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(events))
    }

    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](.failure(error))
    }

    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](.success(()))
    }

    func retrieve(completion: @escaping RetrievalCompletion) {
        retrievalCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }

    func completeRetrieval(with error: Error, at index: Int = 0) {
        retrievalCompletions[index](.failure(error))
    }

    func completeRetrievalWithEmptyCache(at index: Int = 0) {
        retrievalCompletions[index](.success([]))
    }

    func completeRetrieval(with events: [LocalEvent], at index: Int = 0) {
        retrievalCompletions[index](.success(events))
    }
}