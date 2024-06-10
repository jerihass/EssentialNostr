//
//  Created by Jericho Hasselbush on 6/8/24.
//

import XCTest
import EssentialNostr

class LoadEventsFromRemoteTests: XCTestCase {
    func test_init_doesNotRequestLoadWhenCreated() {
        let (_, eventLoader) = makeSUT()

        XCTAssertEqual(eventLoader.receivedMessages, [])
    }

    func test_load_requestsEvents() {
        let (sut, eventLoader) = makeSUT()

        sut.load() { _ in }

        XCTAssertEqual(eventLoader.receivedMessages, [.loadEvents])
    }

    func test_load_givesErrorOnLoaderError() {
        let (sut, eventLoader) = makeSUT()

        let error = anyError()

        expect(sut, toCompleteWith: .failure(error)) {
            eventLoader.complete(with: error)
        }
    }

    func test_load_givesEmptyEventsOnEmptyLoaderSuccess() {
        let (sut, eventLoader) = makeSUT()

        expect(sut, toCompleteWith: .success([])) {
            eventLoader.complete(with: [])
        }
    }

    func test_load_givesSingleEventOnSingleLoaderSuccess() {
        let (sut, eventLoader) = makeSUT()
        let event = uniqueEvent()
        expect(sut, toCompleteWith: .success([event])) {
            eventLoader.complete(with: [event])
        }
    }

    func test_load_givesMultipleEventsOnMultipleLoaderSuccess() {
        let (sut, eventLoader) = makeSUT()
        let events = [uniqueEvent(), uniqueEvent()]
        expect(sut, toCompleteWith: .success(events)) {
            eventLoader.complete(with: events)
        }
    }

    func test_load_givesEventsOnFirstLoadAndMoreOnSubsequentLoads() {
        let (sut, eventLoader) = makeSUT()

        let uniqueEvents0 = uniqueEvents().model
        let uniqueEvents1 = uniqueEvents().model
        var receivedEvents = [Event]()

        let exp0 = expectation(description: "Wait for load completion")

        sut.load { result in
            switch result {
            case let .success(events):
                receivedEvents.append(contentsOf: events)
            case .failure:
                XCTFail("Expected success, got failure instead")
            }
            exp0.fulfill()
        }

        eventLoader.complete(with: uniqueEvents0)

        wait(for: [exp0], timeout: 1)

        XCTAssertEqual(receivedEvents, uniqueEvents0)

        let exp1 = expectation(description: "Wait for load completion")

        sut.load { result in
            switch result {
            case let .success(events):
                receivedEvents.append(contentsOf: events)
            case .failure:
                XCTFail("Expected success, got failure instead")
            }
            exp1.fulfill()
        }

        eventLoader.complete(with: uniqueEvents1, at: uniqueEvents0.count + 1) // This is because we are using EOSE to signal end of events

        wait(for: [exp1], timeout: 1)

        XCTAssertEqual(receivedEvents.count, (uniqueEvents0 + uniqueEvents1).count)
        XCTAssertEqual(receivedEvents, uniqueEvents0 + uniqueEvents1)
    }

    func test_load_givesEventAsItOccurs() {
        var capturedEvent: Event?

        let handler: (Event) -> Void = { event in
            capturedEvent = event
        }

        let loader = RemoteLoaderSpy()
        let sut = RemoteEventsLoader(eventHandler: handler, eventLoader: loader)
        let event = uniqueEvent()
        let exp = expectation(description: "Wait for load completion")

        sut.load { _ in
            exp.fulfill()
        }

        loader.complete(with: [event])

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(capturedEvent, event)
    }

    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: RemoteEventsLoader, loader: RemoteLoaderSpy) {
        let loader = RemoteLoaderSpy()
        let sut = RemoteEventsLoader(eventLoader: loader)
        trackForMemoryLeaks(loader)
        trackForMemoryLeaks(sut)
        return (sut, loader)
    }

    private func expect(_ sut: RemoteEventsLoader, toCompleteWith expectedResult: EventsLoader.LoadResult, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {

        let exp = expectation(description: "Wait for load completion")
        
        sut.load { result in
            switch (result, expectedResult) {
            case let (.success(receivedEvents), .success(expectedEvents)):
                XCTAssertEqual(receivedEvents, expectedEvents)
            case let (.failure(receivedError as NSError?), .failure(expectedError as NSError?)):
                XCTAssertEqual(receivedError, expectedError)
            default:
                XCTFail("Expected: \(expectedResult), got \(result) instead)")
            }
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1)
    }

    private class RemoteLoaderSpy: EventLoader {
        enum Message {
            case loadEvents
        }

        var receivedMessages = [Message]()
        var loadCompletions = [(LoadEventResult) -> Void]()
        func request(_ message: String) {

        }
        
        func load(_ completion: @escaping (LoadEventResult) -> Void) {
            receivedMessages.append(.loadEvents)
            loadCompletions.append(completion)
        }

        func complete(with error: Error, at index: Int = 0) {
            loadCompletions[index](.failure(error))
        }

        func complete(with events: [Event], at index: Int = 0) {
            if events.isEmpty { return loadCompletions[index](.success(.none)) }
            for (i, event) in events.enumerated() {
                loadCompletions[index + i](.success(event))
            }
            loadCompletions[index + events.count](.failure(RemoteEventLoader.Error.eose(sub: "any")))
        }
    }
}
