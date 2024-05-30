//
//  Created by Jericho Hasselbush on 5/29/24.
//

import XCTest
import EssentialNostr

class LoadEventsFromCacheTests: XCTestCase {
    func test_ini() {
        let store = EventStoreSpy()
        let sut = LocalEventLoader(store: store)
    }
}
