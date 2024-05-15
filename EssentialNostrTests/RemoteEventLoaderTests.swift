//
//  Created by Jericho Hasselbush on 5/14/24.
//

import XCTest
import EssentialNostr

class RemoteEventLoaderTests: XCTestCase {
    func test_init_doesNotRequestWhenCreated() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requests.isEmpty)
    }

    func test_load_requestEventFromClient() {
        let request = "Some Request"
        let (sut, client) = makeSUT()

        sut.load(request: request) { _ in }

        XCTAssertEqual(client.requests, [request])
    }

    func test_loadTwice_requestEventFromClientTwice() {
        let request = "Some Request"
        let (sut, client) = makeSUT()

        sut.load(request: request) { _ in }
        sut.load(request: request) { _ in }

        XCTAssertEqual(client.requests, [request, request])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(.connectivity)) {
            let clientError = NSError(domain: "", code: 0)
            client.complete(with: clientError)
        }
    }

    func test_load_deliversErrorOnClosedResponse() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(.closed)) {
            let closedMessage = Data("[\"CLOSED\",\"sub1\",\"duplicate: sub1 already opened\"]".utf8)
            client.complete(with: closedMessage)
        }
    }

    func test_load_deliversErrorOnEventResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(.invalidData)) {
            let closedMessage = Data("[\"EVENT\",\"sub1\",\"INVALID_event_JSON\"]".utf8)
            client.complete(with: closedMessage)
        }
    }

    func test_load_deliversNoEventsOnEndOfStoredEvents() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(.eose)) {
            let eoseMessage = Data("[\"EOSE\",\"sub1\"]".utf8)
            client.complete(with: eoseMessage)
        }
    }

    func test_load_deliversEventOnValidEvents() {
        let (sut, client) = makeSUT()
        let date = Date.distantPast

        let (event1, event1Data) = makeEvent(id: "id1", pubkey: "pubkey1", created_at: date, kind: 1, tags: [["e", "event1", "event2"], ["p", "pub1", "pub2"]], content: "content1", sig: "sig1")

        expect(sut, toCompleteWith: .success(event1)) {
            client.complete(with: event1Data)
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: RemoteEventLoader, client: WebSocketClientSpy) {
        let client = WebSocketClientSpy()
        let sut = RemoteEventLoader(client: client)
        return (sut, client)
    }

    private func makeEvent(id: String, pubkey: String, created_at: Date, kind: UInt16, tags: [[String]], content: String, sig: String) -> (event: Event, data: Data) {
        let event = Event(id: id, pubkey: pubkey, created_at: created_at, kind: kind, tags: tags, content: content, sig: sig)
        let time = created_at.timeIntervalSince1970
        let tagString = tags.stringed

        let eventJSON = "[\"EVENT\",\"sub1\",{\"id\":\"\(id)\",\"pubkey\":\"\(pubkey)\",\"created_at\":\(time),\"kind\":\(kind),\"tags\":\(tagString),\"content\":\"\(content)\",\"sig\":\"\(sig)\"}]"
        return (event, Data(eventJSON.utf8))
    }

    private func expect(_ sut: RemoteEventLoader, toCompleteWith result: RemoteEventLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let request = "Some Request"
        var capturedResults = [RemoteEventLoader.Result]()

        sut.load(request: request) { capturedResults.append($0) }

        action()

        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }

    class WebSocketClientSpy: WebSocketClient {
        var allRequests = [(request: String, completion: (Result<Data, Error>) -> Void)]()
        var requests: [String] { allRequests.map { $0.request }}
        func receive(with request: String, completion: @escaping (Result<Data, Error>) -> Void) {
            allRequests.append((request, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            allRequests[index].completion(.failure(error))
        }

        func complete(with message: Data, at index: Int = 0) {
            allRequests[index].completion(.success(message))
        }
    }
}

private extension Array where Element == [String] {
    var stringed: String {
        let final = self.map { array in
            var temp: String = ""

            array.forEach { tag in
                temp += "\"\(tag)\","
            }
            temp = String(temp.dropLast())
            temp = "[\(temp)]"
            return temp
        }

        let temp = "[\(final.joined(separator: ","))]"
        return temp
    }
}
