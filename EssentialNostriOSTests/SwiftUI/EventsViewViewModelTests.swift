//
//  Created by Jericho Hasselbush on 6/6/24.
//

import XCTest
import EssentialNostr

class EventsViewModel {
    private let loader: EventsLoader
    init(loader: EventsLoader) {
        self.loader = loader
    }

    func loadEvents() {
        loader.load() { _ in }
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

    class LoaderSpy: EventsLoader {
        private var loadRequests = [(LoadResult) -> Void]()
        var loadCallCount: Int { loadRequests.count }

        func load(completion: @escaping (LoadResult) -> Void) {
            loadRequests.append(completion)
        }
    }
}

