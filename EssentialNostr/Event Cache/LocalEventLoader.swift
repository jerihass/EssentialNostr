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
        store.deleteCachedFeed()
    }
}

public class EventStore {
    public var deleteCachedEventsCallCount = 0
    public var insertCallCount = 0

    public init() {}

    public func deleteCachedFeed() {
        deleteCachedEventsCallCount += 1
    }

    public func completeDeletion(with error: Error, at index: Int = 0) {

    }
}
