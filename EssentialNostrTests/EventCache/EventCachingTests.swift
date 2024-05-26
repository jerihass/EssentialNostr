//
//  Created by Jericho Hasselbush on 5/26/24.
//

import XCTest

class LocalEventLoader {
    init(store: EventStore) {

    }
}

class EventStore {
    var deleteCachedEventsCallCount = 0
}

class EventCachingTests: XCTestCase {
    func test_init_doesNoteDeleteCacheWhenCreated() {
        let store = EventStore()
        _ = LocalEventLoader(store: store)
        XCTAssertEqual(store.deleteCachedEventsCallCount, 0)
    }
}
