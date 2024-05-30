//
//  Created by Jericho Hasselbush on 5/29/24.
//

import Foundation
import EssentialNostr

class EventStoreSpy: EventStore {
    enum ReceivedMessage: Equatable {
        case insert([LocalEvent])
        case deleteCachedEvents
    }

    private(set) public var receivedMessages = [ReceivedMessage]()
    init() {}

    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()

    func deleteCachedEvents(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedEvents)
    }

    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func insert(_ events: [LocalEvent], completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(events))
    }

    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }

    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}
