//
//  Created by Jericho Hasselbush on 5/18/24.
//

import XCTest
import EssentialNostr

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

    func test_map_requestMessageToString_multiple() {
        let sub = "sub1"
        let filters = [Filter(ids: ["id1", "id2"]), Filter(ids: ["id1", "id2"])]
        let request = "[\"REQ\",\"\(sub)\",{\"ids\":[\"id1\",\"id2\"]},{\"ids\":[\"id1\",\"id2\"]}]"
        let requestMessage = ClientMessage.Message.request(sub: sub, filters: filters)
        let mapped = ClientMessageMapper.mapMessage(requestMessage)
        XCTAssertTrue(areJSONEqual(mapped.data(using: .utf8)!, request.data(using: .utf8)!))
        print("Request: " + request)
        print("Mapped:  " + mapped)
    }

    func test_map_requestMessageToString_idAuthKinds() {
        let sub = "sub1"
        let filters = [Filter(ids: ["id1", "id2"], authors: ["auth1"], kinds: [1, 2])]
        let request = "[\"REQ\",\"\(sub)\",{\"ids\":[\"id1\",\"id2\"],\"authors\":[\"auth1\"],\"kinds\":[1,2]}]"
        let requestMessage = ClientMessage.Message.request(sub: sub, filters: filters)
        let mapped = ClientMessageMapper.mapMessage(requestMessage)
        XCTAssertTrue(areJSONEqual(mapped.data(using: .utf8)!, request.data(using: .utf8)!))
        print("Request: " + request)
        print("Mapped:  " + mapped)
    }

    func test_map_requestMessageToString_sinceUntilLimit() {
        let sub = "sub1"
        let since: Date = .distantPast
        let until: Date = .now
        let filters = [Filter(since: since, until: until, limit: 10)]
        let request = "[\"REQ\",\"\(sub)\",{\"since\":\(Int(since.timeIntervalSince1970)),\"until\":\(Int(until.timeIntervalSince1970)),\"limit\":10}]"
        let requestMessage = ClientMessage.Message.request(sub: sub, filters: filters)
        let mapped = ClientMessageMapper.mapMessage(requestMessage)
        XCTAssertTrue(areJSONEqual(mapped.data(using: .utf8)!, request.data(using: .utf8)!))
        print("Request: " + request)
        print("Mapped:  " + mapped)
    }

    func test_map_requestMessageToString_tags() {
        let sub = "sub1"
        let filters = [Filter(tags: [["e", "eventID_1", "eventID_2"],["p", "pubkey_1", "pubkey_2"]])]
        let request = "[\"REQ\",\"\(sub)\",{\"#e\":[\"eventID_1\",\"eventID_2\"],\"#p\":[\"pubkey_1\",\"pubkey_2\"]}]"
        let requestMessage = ClientMessage.Message.request(sub: sub, filters: filters)
        let mapped = ClientMessageMapper.mapMessage(requestMessage)
        XCTAssertTrue(areJSONEqual(mapped.data(using: .utf8)!, request.data(using: .utf8)!))
        print("Request: " + request)
        print("Mapped:  " + mapped)
    }

    func test_map_requestMessageToString_kindsTagsSince() {
        let sub = "sub1"
        let since = Date.now
        let filters = [Filter(kinds: [1,2], tags: [["e", "eventID_1", "eventID_2"]], since: since)]
        let request = "[\"REQ\",\"\(sub)\",{\"kinds\":[1,2],\"#e\":[\"eventID_1\",\"eventID_2\"],\"since\":\(Int(since.timeIntervalSince1970))}]"
        let requestMessage = ClientMessage.Message.request(sub: sub, filters: filters)
        let mapped = ClientMessageMapper.mapMessage(requestMessage)
        XCTAssertTrue(areJSONEqual(mapped.data(using: .utf8)!, request.data(using: .utf8)!))
        print("Request: " + request)
        print("Mapped:  " + mapped)
    }

    // MARK: - Helpers

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
