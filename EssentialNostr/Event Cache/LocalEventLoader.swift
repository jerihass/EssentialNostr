//
//  Created by Jericho Hasselbush on 5/27/24.
//

import Foundation

public protocol EventStore {
    typealias InsertionCompletion = (Error?) -> Void
    typealias DeletionCompletion = (Error?) -> Void
    func deleteCachedEvents(completion: @escaping DeletionCompletion)
    func insert(_ events: [Event], completion: @escaping InsertionCompletion)
}

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
