//
//  Created by Jericho Hasselbush on 6/8/24.
//

import XCTest
import EssentialNostr

class LoadEventsFromRemoteTests: XCTestCase {
    func test_init_doesNotRequestLoadWhenCreated() {
        let (_, eventLoader) = makeSUT { _ in }

        XCTAssertEqual(eventLoader.receivedMessages, [])
    }

    func test_load_requestsEvents() {
        let (sut, eventLoader) = makeSUT { _ in }

        sut.load() { _ in }

        XCTAssertEqual(eventLoader.receivedMessages, [.loadEvents])
    }

    func test_load_givesErrorOnLoaderError() {
        let (sut, eventLoader) = makeSUT { _ in }

        let error = anyError()

        expect(sut, toCompleteWith: error) {
            eventLoader.complete(with: error)
        }
    }

    func test_load_givesEmptyEventsOnEmptyLoaderSuccess() {
        let (sut, eventLoader) = makeSUT { _ in }

        expect(sut, toCompleteWith: .none) {
            eventLoader.complete(with: [])
        }
    }

    func test_load_givesSingleEventOnSingleLoaderSuccess() {
        let (sut, eventLoader) = makeSUT { _ in }
        let event = uniqueEvent()
        expect(sut, toCompleteWith: .none) {
            eventLoader.complete(with: [event])
        }
    }

    func test_load_givesMultipleEventsOnMultipleLoaderSuccess() {
        let (sut, eventLoader) = makeSUT { _ in }
        let events = [uniqueEvent(), uniqueEvent()]
        expect(sut, toCompleteWith: .none) {
            eventLoader.complete(with: events)
        }
    }

    func test_load_givesEvenstBeforeAndAfterEOSE() {
        var capturedEvents = [Event]()

        let handler: (Event) -> Void = { event in
            capturedEvents.append(event)
        }

        let loader = RemoteLoaderSpy()
        let sut = RemoteFeedLoader(eventHandler: handler, eventLoader: loader)
        let events = uniqueEvents().model
        let exp = expectation(description: "Wait for load completion")
        exp.isInverted = true
        sut.load { _ in
            exp.fulfill()
        }

        loader.complete(with: events)

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(capturedEvents, events)

        let newEvents = uniqueEvents().model

        loader.complete(with: newEvents, withEOSE: false)

        XCTAssertEqual(capturedEvents, events + newEvents)
    }

    // MARK: - Helpers
    private func makeSUT(eventHandler: @escaping EventHandler, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedLoader, loader: RemoteLoaderSpy) {
        let loader = RemoteLoaderSpy()
        let sut = RemoteFeedLoader(eventHandler: eventHandler, eventLoader: loader)
        trackForMemoryLeaks(loader)
        trackForMemoryLeaks(sut)
        return (sut, loader)
    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedError: Error?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {

        let exp = expectation(description: "Wait for load completion")

        sut.load { receivedError in
            XCTAssertEqual(receivedError as NSError?, expectedError as NSError?)
        }
        exp.fulfill()

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

        func complete(with events: [Event], withEOSE: Bool = true, at index: Int = 0) {
            if events.isEmpty { return loadCompletions[index](.success(.none)) }
            for (i, event) in events.enumerated() {
                loadCompletions[index + i](.success(event))
            }
            if withEOSE {
                loadCompletions[index + events.count](.failure(RemoteEventLoader.Error.eose(sub: "any")))
            }
        }
    }
}
