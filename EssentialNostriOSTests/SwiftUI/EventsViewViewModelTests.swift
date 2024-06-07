//
//  Created by Jericho Hasselbush on 6/6/24.
//

import XCTest
import EssentialNostr

class EventsViewModel {
    private let loader: EventsViewViewModelTests.LoaderSpy
    init(loader: EventsViewViewModelTests.LoaderSpy) {
        self.loader = loader
    }

    func loadEvents() {
        loader.load()
    }
}

class EventsViewViewModelTests: XCTestCase {
    func test_init_doesNotLoadEvents() {
        let loader = LoaderSpy()
        let _ = EventsViewModel(loader: loader)
        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_load_requestLoadFromLoader() {
        let loader = LoaderSpy()
        let sut = EventsViewModel(loader: loader)

        sut.loadEvents()

        XCTAssertEqual(loader.loadCallCount, 1)
    }

    class LoaderSpy {
        private(set) var loadCallCount = 0
        func load() {
            loadCallCount += 1
        }
    }
}

