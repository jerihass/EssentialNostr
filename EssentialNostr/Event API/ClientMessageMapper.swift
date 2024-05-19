//
//  Created by Jericho Hasselbush on 5/19/24.
//

import Foundation

public struct Filter: Encodable {
    let ids: [String]?
    let authors: [String]?
    let kinds: [UInt16]?
    let tags: [[String]]?
    let since: Date?
    let until: Date?
    let limit: UInt?

    public init(ids: [String]? = nil, authors: [String]? = nil, kinds: [UInt16]? = nil, tags: [[String]]? = nil, since: Date? = nil, until: Date? = nil, limit: UInt? = nil) {
        self.ids = ids
        self.authors = authors
        self.kinds = kinds
        self.tags = tags
        self.since = since
        self.until = until
        self.limit = limit
    }
}

private extension Array where Element == Filter {
    var json: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
}

public struct ClientMessage {
    public enum Message {
        case close(sub: String)
        case event(event: Event)
        case request(sub: String, filters: [Filter])
    }
}

public final class ClientMessageMapper {
    public static func mapMessage(_ message: ClientMessage.Message) -> String {
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
