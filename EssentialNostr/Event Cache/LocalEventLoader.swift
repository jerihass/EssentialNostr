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
        store.deleteCachedEvents { [weak self] deleteError in
            guard let self = self else { return }
            if let de = deleteError {
                completion(de)
            } else {
                self.cacheEventsWithCompletion(events, completion)
            }
        }
    }

    private func cacheEventsWithCompletion(_ events: [Event], _ completion: @escaping (Error?) -> Void) {
        store.insert(events) { [weak self] insertError in
            guard self != nil else { return }
            completion(insertError)
        }
    }
}
