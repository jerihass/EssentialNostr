//
//  Created by Jericho Hasselbush on 6/6/24.
//

import XCTest
import EssentialNostr

class EventsViewModel {
    init(loader: EventsViewViewModelTests.LoaderSpy) {
        
    }
}

class EventsViewViewModelTests: XCTestCase {
    func test_init_doesNotLoadEvents() {
        let loader = LoaderSpy()
        let sut = EventsViewModel(loader: loader)
        XCTAssertEqual(loader.loadCallCount, 0)
    }

    class LoaderSpy {
        private(set) var loadCallCount = 0
    }
}

