//
//  Created by Jericho Hasselbush on 6/6/24.
//

import XCTest
import EssentialNostr
import EssentialNostriOS

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

    func test_loadEvents_deliversEvents() async {
        let (sut, loader) = makeSUT()
        let event0 = Event(id: "someID", publicKey: "somePubkey", created: .now, kind: 1, tags: [], content: "some content", signature: "some sig")
        sut.loadEvents()

        loader.completeEventLoading(with: event0, at: 0)

        let count = await sut.eventCount()
        XCTAssertEqual(count, 1)
    }

    // MARK: - Helpers
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: EventsViewModel, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = EventsViewModel(loader: loader)
        trackForMemoryLeaks(loader)
        trackForMemoryLeaks(sut)
        return (sut, loader)
    }

    class LoaderSpy: EventLoader {
        private var loadRequests = [(LoadEventResult) -> Void]()
        var loadCallCount: Int { loadRequests.count }
        func request(_ message: String) {

        }

        func load(_ completion: @escaping (LoadEventResult) -> Void) {
            loadRequests.append(completion)
        }

        func completeEventLoading(with event: Event, at index: Int = 0) {
            loadRequests[index](.success(event))
        }
    }
}

extension EventsViewModel {
    func simulateRefresh() {
        self.refreshEvents()
    }

    func eventCount() async -> Int {
        let events = await fetchEvents()
        return events.count
    }
}

