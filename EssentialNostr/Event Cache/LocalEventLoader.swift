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
            guard let self = self else { return }
            if error == nil {
                self.store.insert(events) { [weak self] error in
                    guard self != nil else { return }
                    completion(error)
                }
            } else {
                completion(error)
            }
        }
    }
}
