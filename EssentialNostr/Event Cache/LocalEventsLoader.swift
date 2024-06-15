//
//  Created by Jericho Hasselbush on 5/27/24.
//

import Foundation

public class LocalEventsLoader {
    private let store: EventStore

    public typealias SaveResult = Error?
    public init(store: EventStore) {
        self.store = store
    }
}

extension LocalEventsLoader: FeedLoader {
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard self != nil else { return  }
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(events):
                completion(.success(events.model()))
            }
        }
    }
}

extension LocalEventsLoader {
    public func save(_ events: [Event], overwrite: Bool = true, completion: @escaping (SaveResult) -> Void) {
        if overwrite {
            store.deleteCachedEvents { [weak self] deleteError in
                guard let self = self else { return }
                if case let .failure(error) = deleteError {
                    completion(error)
                } else {
                    self.cacheEventsWithCompletion(events, completion)
                }
            }
        }
        else {
            self.cacheEventsWithCompletion(events, completion)
        }
    }

    private func cacheEventsWithCompletion(_ events: [Event], _ completion: @escaping (Error?) -> Void) {
        store.insert(events.toLocal()) { [weak self] insertError in
            guard self != nil else { return }
            if case let .failure(error) = insertError {
                completion(error)
            } else {
                completion(nil)
            }
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

private extension Array where Element == LocalEvent {
    func model() -> [Event] {
        map{ Event(id: $0.id,
                        publicKey: $0.publickey,
                        created: $0.created,
                        kind: $0.kind,
                        tags: $0.tags,
                        content: $0.content,
                        signature: $0.signature)
        }
    }
}
