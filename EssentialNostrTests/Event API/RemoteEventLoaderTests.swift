//
//  Created by Jericho Hasselbush on 5/14/24.
//

import XCTest
import EssentialNostr
import Network

class RemoteEventLoaderTests: XCTestCase {
    func test_init_doesNotRequestWhenCreated() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.sendMessages.isEmpty)
    }

    func test_request_requestsEventFromClient() {
        let request = "Some Request"
        let (sut, client) = makeSUT()

        sut.request(request)

        XCTAssertEqual(client.sendMessages, [request])
    }

    func test_requestTwice_requestEventFromClientTwice() {
        let request = "Some Request"
        let (sut, client) = makeSUT()

        sut.request(request)
        sut.request(request)

        XCTAssertEqual(client.sendMessages, [request, request])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()

        expect(sut, toLoadWith: failure(.connectivity)) {
            let clientError = NSError(domain: "", code: 0)
            client.complete(with: clientError)
        }
    }

    func test_load_deliversErrorOnClosedResponse() {
        let (sut, client) = makeSUT()

        expect(sut, toLoadWith: failure(.closed(sub: "sub1", message: "duplicate: already opened"))) {
            let closedMessage = Data("[\"CLOSED\",\"sub1\",\"duplicate: already opened\"]".utf8)
            client.complete(with: closedMessage)
        }
    }

    func test_load_deliversErrorOnClosedResponseInvalidFormat() {
        let (sut, client) = makeSUT()

        expect(sut, toLoadWith: failure(.invalidData)) {
            let closedMessage = Data("[\"CLOSED\",\"duplicate: already opened\"]".utf8)
            client.complete(with: closedMessage)
        }
    }

    func test_load_deliversErrorOnEventResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()

        expect(sut, toLoadWith: failure(.invalidData)) {
            let closedMessage = Data("[\"EVENT\",\"sub1\",\"INVALID_event_JSON\"]".utf8)
            client.complete(with: closedMessage)
        }
    }

    func test_load_deliversEOSEErrorOnEndOfStoredEvents() {
        let (sut, client) = makeSUT()

        expect(sut, toLoadWith: failure(.eose(sub: "sub1"))) {
            let eoseMessage = Data("[\"EOSE\",\"sub1\"]".utf8)
            client.complete(with: eoseMessage)
        }
    }

    func test_load_deliversNoticeErrorOnNotice() {
        let (sut, client) = makeSUT()
        let message = "Notice Message"
        expect(sut, toLoadWith: failure(.notice(message: message))) {
            let noticeMessage = Data("[\"NOTICE\",\"\(message)\"]".utf8)
            client.complete(with: noticeMessage)
        }
    }

    func test_load_deliversOKNoticeErrorOnNoticeWithAcceptedFalse() {
        let (sut, client) = makeSUT()
        let message = "duplicate: already have this event"
        expect(sut, toLoadWith: failure(.ok(sub: "sub1", accepted: false, reason: message))) {
            let okMessage = Data("[\"OK\",\"sub1\",false,\"\(message)\"]".utf8)
            client.complete(with: okMessage)
        }
    }

    func test_load_deliversEventOnValidEvent() {
        let (sut, client) = makeSUT()
        let date = Date.distantPast

        let event = makeEvent(id: "id1", pubkey: "pubkey1", created_at: date, kind: 1, tags: [["e", "event1", "event2"], ["p", "pub1", "pub2"]], content: "content1", sig: "sig1")

        expect(sut, toLoadWith: .success(event.model)) {
            client.complete(with: event.data)
        }
    }

    func test_loadRepeatedly_deliversEventsOnValidEvents() {
        let (sut, client) = makeSUT()
        let date = Date.distantPast

        let event = makeEvent(id: "id1", pubkey: "pubkey1", created_at: date, kind: 1, tags: [["e", "event1", "event2"], ["p", "pub1", "pub2"]], content: "content1", sig: "sig1")

        let event2 = makeEvent(id: "id2", pubkey: "pubkey2", created_at: date, kind: 1, tags: [["e", "event1", "event2"], ["p", "pub1", "pub2"]], content: "content2", sig: "sig2")

        expect(sut, toLoadWith: .success(event.model)) {
            client.complete(with: event.data)
        }

        expect(sut, toLoadWith: .success(event2.model)) {
            client.complete(with: event2.data, at: 1)
        }
    }

    func test_load_doesNotDeliverResultsAfterLoaderDeallocated() {
        let client = WebSocketClientSpy()
        var sut:RemoteEventLoader? = RemoteEventLoader(client: client)

        var capturedResults = [RemoteEventLoader.Result]()

        let request = "Some Request"
        sut?.request(request)
        sut?.load { capturedResults.append($0) }

        sut = nil

        client.complete(with: NSError())


        XCTAssertTrue(capturedResults.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: RemoteEventLoader, client: WebSocketClientSpy) {
        let client = WebSocketClientSpy()
        let sut = RemoteEventLoader(client: client)
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }

    private func failure(_ error: RemoteEventLoader.Error) -> RemoteEventLoader.Result {
        .failure(error)
    }

    private func makeEvent(id: String, pubkey: String, created_at: Date, kind: UInt16, tags: [[String]], content: String, sig: String) -> (model: Event, data: Data) {
        let event = Event(id: id, pubkey: pubkey, created_at: created_at, kind: kind, tags: tags, content: content, sig: sig)
        let time = created_at.timeIntervalSince1970
        let tagString = tags.stringed

        let eventJSON = "[\"EVENT\",\"sub1\",{\"id\":\"\(id)\",\"pubkey\":\"\(pubkey)\",\"created_at\":\(time),\"kind\":\(kind),\"tags\":\(tagString),\"content\":\"\(content)\",\"sig\":\"\(sig)\"}]"
        return (event, Data(eventJSON.utf8))
    }

    private func expect(_ sut: RemoteEventLoader, toLoadWith expectedResult: RemoteEventLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {

        let exp = expectation(description: "Wait for load completion.")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedEvent), .success(expectedEvent)):
                XCTAssertEqual(receivedEvent, expectedEvent, "Got \(receivedEvent), expected \(expectedEvent)",
                               file: file, line: line)
            case let (.failure(receivedError as RemoteEventLoader.Error), .failure(expectedError as RemoteEventLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, "Got \(receivedError), expected \(expectedError)",
                               file: file, line: line)

            default:
                XCTFail("Got \(receivedResult), expected \(expectedResult)", 
                        file: file, line: line)
            }
            exp.fulfill()
        }

        action()

        waitForExpectations(timeout: 1)
    }

    class WebSocketClientSpy: WebSocketClient {
        var sendMessages = [String]()
        var loadCompletions = [(Result<Data, Error>) -> Void]()

        func complete(with error: Error, at index: Int = 0) {
            loadCompletions[index](.failure(error))
        }

        func complete(with message: Data, at index: Int = 0) {
            loadCompletions[index](.success(message))
        }

        func send(message: String, completion: @escaping (Error) -> Void) {
            sendMessages.append(message)
        }

        func receive(completion: @escaping (Result<Data, Error>) -> Void) {
            loadCompletions.append(completion)
        }

        // MARK: - Conformance requirement
        var delegate: EssentialNostr.WebSocketDelegate?
        func start() throws {}
        func disconnect() {}
    }
}

private extension Array where Element == [String] {
    var stringed: String {
        if let json = try? JSONEncoder().encode(self), let string = String(data: json, encoding: .utf8) {
            return string
        }
        return ""
    }
}
