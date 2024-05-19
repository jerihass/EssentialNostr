//
//  Created by Jericho Hasselbush on 5/18/24.
//

import XCTest
import EssentialNostr

struct ClientMessage {
    enum Message {
        case close(sub: String)
        case event(event: Event)
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
