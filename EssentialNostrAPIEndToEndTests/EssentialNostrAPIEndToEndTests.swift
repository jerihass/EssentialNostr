//
//  Created by Jericho Hasselbush on 5/18/24.
//

import XCTest
import EssentialNostr
import Network

final class EssentialNostrAPIEndToEndTests: XCTestCase {
    // Use this test on local echo server modified for event canned responses
    func test_endToEndTestServer_retrievesExpectedEvents() throws {
        let loader = makeSUT()

        loader.request("EVENT_REQUEST")
        var receivedResult: EventLoader.LoadEventResult?

        let exp = expectation(description: "Wait for load completion")
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3.0)

        switch receivedResult {
        case let .success(event)?:
            XCTAssertEqual(event?.id, "eventID")
        case let .failure(error)?:
            XCTFail("Expected at successful event result, got \(error) instead.")
        default:
            XCTFail("Expected successful event result, got no result instead.")
        }
    }

    func test_endToEndTestServer_retrievesTwoExpectedEvents() throws {
        let loader = makeSUT()

        loader.request("EVENT_REQUEST_TWO")
        var receivedResult = [EventLoader.LoadEventResult]()

        let exp = expectation(description: "Wait for load completion")
        loader.load {[weak loader] result in
            receivedResult.append(result)
            if ((try? result.get()) != nil) {
                loader?.load {
                    receivedResult.append($0)
                    exp.fulfill()
                }
            }
        }

        wait(for: [exp], timeout: 3.0)

        XCTAssertEqual(receivedResult.count, 3) // Two events and EOSE
        XCTAssertEqual(receivedResult.compactMap { try? $0.get()?.id }, ["eventID", "eventID"])
    }

    func test_endToEndTestServer_badEventJSONGivesErrorReply() throws {
        let loader = makeSUT()
        let event = Event(id: "bdID", publicKey: "npub1el277q4kesp8vhs7rq6qkwnhpxfp345u7tnuxykwr67d9wg0wvyslam5n0", created: .now, kind: 1, tags: [], content: "Test", signature: "badsig")
        let message = ClientMessage.Message.event(event: event)

        loader.request(ClientMessageMapper.mapMessage(message))
        var receivedResult: EventLoader.LoadEventResult?

        let exp = expectation(description: "Wait for load completion")
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3.0)

        switch receivedResult {
        case let .success(event)?:
            XCTFail("Expected failure, got \(String(describing: event)) instead.")
        case let .failure(error)?:
            print(error)
            XCTAssertNotNil(error, "Expected Error")
        default:
            XCTFail("Expected error response, got no result instead.")
        }
    }

    func test_endToEndTestServer_retrieves3Events_EOSE_Then2Events() throws {
        let requester: EventsRequester = { "3EVENT_EOSE_2EVENT" }
        var events = [Event]()

        let eventHandler: EventHandler = { event in
            events.append(event)
        }

        let (sut, loader) = makeEventsLoader(handler: eventHandler)

        loader.request(requester())
        var results = [Result<[Event], Error>]()
        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            results.append(result)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 3.0)

        XCTAssertEqual(events.count, 5) // Two events
        XCTAssertEqual(try results[0].get(), [events[0], events[1], events[2]]) // Events from the initial request
    }

    // MARK: - Helpers

    func makeSUT(file: StaticString = #file, line: UInt = #line) -> RemoteEventLoader {
        let url = URL(string: "ws://127.0.0.1:8080")!
        let client = NetworkConnectionWebSocketClient(url: url)
        client.stateHandler = { _ in }
        let loader = RemoteEventLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)

        try? client.start()

        return loader
    }

    func makeEventsLoader(handler: @escaping EventHandler, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteEventsLoader, eventLoader: RemoteEventLoader) {
        let loader = makeSUT()
        let sut = RemoteEventsLoader(eventHandler: handler, eventLoader: loader)
        trackForMemoryLeaks(loader)
        trackForMemoryLeaks(sut)
        return (sut, loader)
    }
}
