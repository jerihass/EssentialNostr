//
//  Created by Jericho Hasselbush on 5/18/24.
//

import XCTest
import EssentialNostr


struct Filter: Encodable {
    let ids: [String]?
    let authors: [String]?
    let kinds: [UInt16]?
    let tags: [[String]]?
    let since: Date?
    let until: Date?
    let limit: UInt?

    init(ids: [String]? = nil, authors: [String]? = nil, kinds: [UInt16]? = nil, tags: [[String]]? = nil, since: Date? = nil, until: Date? = nil, limit: UInt? = nil) {
        self.ids = ids
        self.authors = authors
        self.kinds = kinds
        self.tags = tags
        self.since = since
        self.until = until
        self.limit = limit
    }
}

extension Array where Element == Filter {
    var json: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
}

struct ClientMessage {
    enum Message {
        case close(sub: String)
        case event(event: Event)
        case request(sub: String, filters: [Filter])
    }
}

final class ClientMessageMapper {
    static func mapMessage(_ message: ClientMessage.Message) -> String {
        switch message {
        case let .close(sub):
            return "[\"CLOSE\",\"\(sub)\"]"
        case let .event(event):
            let local = MessageEvent(event)
            if let eventJSON = local.json, let string = String(data: eventJSON, encoding: .utf8) {
                return "[\"EVENT\",\(string)]"
            }
        case let .request(sub, filters):
            if let filterJSON = filters.json, let string = String(data: filterJSON, encoding: .utf8) {
                var trimmed = string
                trimmed = trimmed.trimmingCharacters(in: ["[","]"])
                return "[\"REQ\",\"\(sub)\",\(trimmed)]"
            }
        }
        return ""
    }

    private struct MessageEvent: Encodable {
        let id: String
        let pubkey: String
        let created_at: Double
        let kind: UInt16
        let tags: [[String]]
        let content: String
        let sig: String
        
        init(_ event: Event) {
            id = event.id
            pubkey = event.pubkey
            created_at = event.created_at.timeIntervalSince1970
            kind = event.kind
            tags = event.tags
            content = event.content
            sig = event.sig
        }

        var json: Data? {
            let encoder = JSONEncoder()
            return try? encoder.encode(self)
        }
    }
}

class ClientMessageMapperTests: XCTestCase {
    func test_map_closeMessageToString() {
        let subID = "sub_id"
        let closeMessage = ClientMessage.Message.close(sub: subID)
        let mapped = ClientMessageMapper.mapMessage(closeMessage)
        XCTAssertEqual(mapped, "[\"CLOSE\",\"\(subID)\"]")
    }

    func test_map_eventMessageToString() {
        let event = makeEvent(id: "id", pubkey: "somepubkey", created_at: .distantPast, kind: 1, tags: [["e", "some1", "some2"]], content: "the content", sig: "signature")
        let eventMessage = ClientMessage.Message.event(event: event.model)
        let mapped = ClientMessageMapper.mapMessage(eventMessage)

        XCTAssertTrue(areJSONEqual(mapped.data(using: .utf8)!, event.data))
    }

    func test_map_requestMessageToString() {
        let sub = "sub1"
        let filters = [Filter(ids: ["id1", "id2"])]
        let request = "[\"REQ\",\"\(sub)\",{\"ids\":[\"id1\",\"id2\"]}]"
        let requestMessage = ClientMessage.Message.request(sub: sub, filters: filters)
        let mapped = ClientMessageMapper.mapMessage(requestMessage)
        XCTAssertTrue(areJSONEqual(mapped.data(using: .utf8)!, request.data(using: .utf8)!))
        print("Request: " + request)
        print("Mapped:  " + mapped)
    }

    func test_map_requestMessageToString2() {
        let sub = "sub1"
        let filters = [Filter(ids: ["id1", "id2"]), Filter(ids: ["id1", "id2"])]
        let request = "[\"REQ\",\"\(sub)\",{\"ids\":[\"id1\",\"id2\"]},{\"ids\":[\"id1\",\"id2\"]}]"
        let requestMessage = ClientMessage.Message.request(sub: sub, filters: filters)
        let mapped = ClientMessageMapper.mapMessage(requestMessage)
        XCTAssertTrue(areJSONEqual(mapped.data(using: .utf8)!, request.data(using: .utf8)!))
        print("Request: " + request)
        print("Mapped:  " + mapped)
    }

    func test_map_requestMessageToString3() {
        let sub = "sub1"
        let filters = [Filter(ids: ["id1", "id2"], authors: ["auth1"], kinds: [1, 2])]
        let request = "[\"REQ\",\"\(sub)\",{\"ids\":[\"id1\",\"id2\"],\"authors\":[\"auth1\"],\"kinds\":[1,2]}]"
        let requestMessage = ClientMessage.Message.request(sub: sub, filters: filters)
        let mapped = ClientMessageMapper.mapMessage(requestMessage)
        XCTAssertTrue(areJSONEqual(mapped.data(using: .utf8)!, request.data(using: .utf8)!))
        print("Request: " + request)
        print("Mapped:  " + mapped)
    }

    private func makeEvent(id: String, pubkey: String, created_at: Date, kind: UInt16, tags: [[String]], content: String, sig: String) -> (model: Event, data: Data) {
        let event = Event(id: id, pubkey: pubkey, created_at: created_at, kind: kind, tags: tags, content: content, sig: sig)
        let time = created_at.timeIntervalSince1970
        let tagString = tags.stringed

        let eventJSON = "[\"EVENT\",{\"id\":\"\(id)\",\"pubkey\":\"\(pubkey)\",\"created_at\":\(time),\"kind\":\(kind),\"tags\":\(tagString),\"content\":\"\(content)\",\"sig\":\"\(sig)\"}]"
        return (event, Data(eventJSON.utf8))
    }

    private func areJSONEqual(_ json1: Data, _ json2: Data) -> Bool {
        guard let jsonObject1 = try? JSONSerialization.jsonObject(with: json1, options: []),
              let jsonObject2 = try? JSONSerialization.jsonObject(with: json2, options: []) else {
            return false
        }

        guard let sortedJSONData1 = try? JSONSerialization.data(withJSONObject: jsonObject1, options: .sortedKeys),
              let sortedJSONData2 = try? JSONSerialization.data(withJSONObject: jsonObject2, options: .sortedKeys) else {

            return false
        }

        return sortedJSONData1 == sortedJSONData2
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
