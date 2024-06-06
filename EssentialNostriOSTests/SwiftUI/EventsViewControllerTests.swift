//
//  Created by Jericho Hasselbush on 6/6/24.
//

import XCTest
import EssentialNostr

class EventsViewController {
    init(loader: EventsViewControllerTests.LoaderSpy) {
        
    }
}

class EventsViewControllerTests: XCTestCase {
    func test_init_doesNotLoadEvents() {
        let loader = LoaderSpy()
        let sut = EventsViewController(loader: loader)
        XCTAssertEqual(loader.loadCallCount, 0)
    }

    class LoaderSpy {
        private(set) var loadCallCount = 0
    }
}

