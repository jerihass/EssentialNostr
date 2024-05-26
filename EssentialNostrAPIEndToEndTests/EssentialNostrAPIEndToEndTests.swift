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
        var receivedResult: LoadEventResult?

        let exp = expectation(description: "Wait for load completion")
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3.0)

        switch receivedResult {
        case let .success(event)?:
            XCTAssertEqual(event.id, "eventID")
        case let .failure(error)?:
            XCTFail("Expected at successful event result, got \(error) instead.")
        default:
            XCTFail("Expected successful event result, got no result instead.")
        }
    }

    func test_endToEndTestServer_badEventJSONGivesErrorReply() throws {
        let loader = makeSUT()
        let event = Event(id: "bdID", pubkey: "npub1el277q4kesp8vhs7rq6qkwnhpxfp345u7tnuxykwr67d9wg0wvyslam5n0", created_at: .now, kind: 1, tags: [], content: "Test", sig: "badsig")
        let message = ClientMessage.Message.event(event: event)

        loader.request(ClientMessageMapper.mapMessage(message))
        var receivedResult: LoadEventResult?

        let exp = expectation(description: "Wait for load completion")
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3.0)

        switch receivedResult {
        case let .success(event)?:
            XCTFail("Expected failure, got \(event) instead.")
        case let .failure(error)?:
            print(error)
            XCTAssertNotNil(error, "Expected Error")
        default:
            XCTFail("Expected error response, got no result instead.")
        }
    }

    // MARK: - Helpers

    func makeSUT(file: StaticString = #file, line: UInt = #line) -> RemoteEventLoader {
        let url = URL(string: "wss://127.0.0.1:4433")!
        let client = NetworkConnectionWebSocketClient(url: url)
        client.stateHandler = { _ in }
        let loader = RemoteEventLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)

        try? client.start()

        return loader
    }
}
