//
//  Created by Jericho Hasselbush on 6/6/24.
//

import XCTest
import EssentialNostr

class EventsViewModel {
    private let loader: EventsLoader
    private(set) var isRefreshing: Bool = false
    init(loader: EventsLoader) {
        self.loader = loader
    }

    func refreshEvents() {
        loadEvents()
    }

    func loadEvents() {
        isRefreshing = true
        loader.load() { [weak self] _ in
            guard let self = self else { return }
            isRefreshing = false
        }
    }
}

class EventsViewViewModelTests: XCTestCase {
    func test_init_doesNotLoadEvents() {
        let (_, loader) = makeSUT()

        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_loadActionsRequestFeed() {
        let (sut, loader) = makeSUT()

        sut.loadEvents()
        XCTAssertEqual(loader.loadCallCount, 1)

        sut.simulateRefresh()
        XCTAssertEqual(loader.loadCallCount, 2)

        sut.simulateRefresh()
        XCTAssertEqual(loader.loadCallCount, 3)
    }

    func test_load_showsLoadingIndicator() {
        let (sut, loader) = makeSUT()

        sut.loadEvents()
        XCTAssertTrue(sut.isShowingLoadingIndicator)

        loader.completeEventsLoading()
        XCTAssertFalse(sut.isShowingLoadingIndicator)

        sut.simulateRefresh()
        XCTAssertTrue(sut.isShowingLoadingIndicator)

        loader.completeEventsLoading()
        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }



    // MARK: - Helpers
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: EventsViewModel, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = EventsViewModel(loader: loader)
        trackForMemoryLeaks(loader)
        trackForMemoryLeaks(sut)
        return (sut, loader)
    }

    class LoaderSpy: EventsLoader {
        private var loadRequests = [(LoadResult) -> Void]()
        var loadCallCount: Int { loadRequests.count }

        func load(completion: @escaping (LoadResult) -> Void) {
            loadRequests.append(completion)
        }

        func completeEventsLoading() {
            loadRequests[0](.success([]))
        }
    }
}

extension EventsViewModel {
    func simulateRefresh() {
        self.refreshEvents()
    }

    var isShowingLoadingIndicator: Bool {
        isRefreshing
    }
}

