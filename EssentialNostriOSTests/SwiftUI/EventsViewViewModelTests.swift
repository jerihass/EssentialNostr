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

        sut.loadEvents() { _ in }
        XCTAssertEqual(loader.loadCallCount, 1)

        sut.simulateRefresh()
        XCTAssertEqual(loader.loadCallCount, 2)

        sut.simulateRefresh()
        XCTAssertEqual(loader.loadCallCount, 3)
    }

    func test_load_givesErrorOnLoaderError() {
        let (sut, loader) = makeSUT()
        
        let error = anyError()

        let exp = expectation(description: "Wait for load")
        var gotError: Error?
        sut.loadEvents { error in
            gotError = error
            exp.fulfill()
        }

        loader.completeEventLoading(with: error)
        
        wait(for: [exp], timeout: 1.0)

        XCTAssertNotNil(gotError)
    }

    func test_loadEvents_deliversSingleEvent() async {
        let (sut, loader) = makeSUT()
        let event0 = Event(id: "someID", publicKey: "somePubkey", created: .now, kind: 1, tags: [], content: "some content", signature: "some sig")
       sut.loadEvents() { _ in }

        loader.completeEventLoading(with: [event0], at: 0)

        let count = await sut.eventCount()
        XCTAssertEqual(count, 1)
    }

    func test_loadEvents_deliversMultipleEvents() async {
        let (sut, loader) = makeSUT()
        let event0 = Event(id: "someID", publicKey: "somePubkey", created: .now, kind: 1, tags: [], content: "some content", signature: "some sig")
        let event1 = Event(id: "someID1", publicKey: "somePubkey1", created: .now, kind: 1, tags: [], content: "some content1", signature: "some sig1")

        sut.loadEvents() { _ in }

        loader.completeEventLoading(with: [event0, event1], at: 0)

        let events = await sut.fetchEvents()

        XCTAssertEqual(events, [event0, event1])
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
        func request(_ message: String) {

        }

        func load(completion: @escaping (LoadResult) -> Void) {
            loadRequests.append(completion)
        }

        func completeEventLoading(with events: [Event], at index: Int = 0) {
            loadRequests[index](.success(events))
        }

        func completeEventLoading(with error: Error, at index: Int = 0) {
            loadRequests[index](.failure(error))
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

