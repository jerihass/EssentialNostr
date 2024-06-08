//
//  Created by Jericho Hasselbush on 6/8/24.
//

import XCTest
import EssentialNostr

class RemoteEventsLoader {
    let eventLoader: EventLoader

    init(eventLoader: EventLoader) {
        self.eventLoader = eventLoader
    }

    func load(completion: @escaping (EventsLoader.LoadResult) -> Void) {
        var events = [Event]()

        var load: (_ : Result<Event?, Error>) -> Void = { _ in }

        load = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(event):
                guard let event = event else { return completion(.success(events)) }
                events.append(event)
                eventLoader.load(load)
            case let .failure(error):
                if case RemoteEventLoader.Error.eose = error {
                    completion(.success(events))
                } else {
                    completion(.failure(error))
                }
                break
            }
        }

        eventLoader.load(load)
    }
}

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
