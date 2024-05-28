//
//  Created by Jericho Hasselbush on 5/27/24.
//

import Foundation

public class LocalEventLoader {
    private let store: EventStore
    public init(store: EventStore) {
        self.store = store
    }

    public func save(_ events: [Event], completion: @escaping (Error?) -> Void = { _ in }) {
        store.deleteCachedEvents { [weak self] error in
            if error == nil {
                self?.store.insert(events, completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

public class EventStore {
    public typealias DeletionCompletion = (Error?) -> Void
    public typealias InsertionCompletion = (Error?) -> Void

    public enum ReceivedMessage: Equatable {
        case insert([Event])
        case deleteCachedEvents
    }

    private(set) public var receivedMessages = [ReceivedMessage]()
    public init() {}

    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()

    public func deleteCachedEvents(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedEvents)
    }

    public func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }

    public func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func insert(_ events: [Event], completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(events))
    }

    public func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }

    public func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}
