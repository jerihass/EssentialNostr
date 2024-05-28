//
//  Created by Jericho Hasselbush on 5/27/24.
//

import Foundation

public class LocalEventLoader {
    private let store: EventStore
    public init(store: EventStore) {
        self.store = store
    }

    public func save(_ events: [Event]) {
        store.deleteCachedFeed { [weak self] error in
            if error == nil {
                self?.store.insert(events)
            }
        }
    }
}

public class EventStore {
    public typealias DeletionCompletion = (Error?) -> Void
    public var deleteCachedEventsCallCount:Int { deletionCompletions.count }
    public var insertCallCount: Int { insertions.count }
    public var insertions = [[Event]]()
    public init() {}

    private var deletionCompletions = [DeletionCompletion]()

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
    }

    public func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }

    public func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func insert(_ events: [Event]) {
        self.insertions.append(events)
    }
}
