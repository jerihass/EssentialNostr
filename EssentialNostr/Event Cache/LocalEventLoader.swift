//
//  Created by Jericho Hasselbush on 5/27/24.
//

import Foundation

public class LocalEventLoader {
    private let store: EventStore

    public typealias SaveResult = Error?
    public init(store: EventStore) {
        self.store = store
    }

    public func save(_ events: [Event], completion: @escaping (SaveResult) -> Void) {
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
        store.insert(events.toLocal()) { [weak self] insertError in
            guard self != nil else { return }
            completion(insertError)
        }
    }
}

private extension Array where Element == Event {
    func toLocal() -> [LocalEvent] {
        map{ LocalEvent(id: $0.id,
                        publicKey: $0.publicKey,
                        created: $0.created,
                        kind: $0.kind,
                        tags: $0.tags,
                        content: $0.content,
                        signature: $0.signature)
        }
    }
}
