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
            let local = filters.map(MessageFilter.init)
            if let filterJSON = local.json, let string = String(data: filterJSON, encoding: .utf8) {
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

private struct MessageFilter: Encodable {
    let ids: [String]?
    let authors: [String]?
    let kinds: [UInt16]?
    let tags: [[String]]?
    let since: Double?
    let until: Double?
    let limit: UInt?

    init(ids: [String]? = nil, authors: [String]? = nil, kinds: [UInt16]? = nil, tags: [[String]]? = nil, since: Double? = nil, until: Double? = nil, limit: UInt? = nil) {
        self.ids = ids
        self.authors = authors
        self.kinds = kinds
        self.tags = tags
        self.since = since
        self.until = until
        self.limit = limit
    }

    enum CodingKeys: CodingKey {
        case ids
        case authors
        case kinds
        case tags
        case since
        case until
        case limit
    }

    init(_ filter: Filter) {
        ids = filter.ids
        authors = filter.authors
        kinds = filter.kinds
        tags = filter.tags
        since = filter.since?.timeIntervalSince1970
        until = filter.until?.timeIntervalSince1970
        limit = filter.limit
    }

    func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<MessageFilter.CodingKeys> = encoder.container(keyedBy: MessageFilter.CodingKeys.self)
        try container.encodeIfPresent(self.ids, forKey: MessageFilter.CodingKeys.ids)
        try container.encodeIfPresent(self.authors, forKey: MessageFilter.CodingKeys.authors)
        try container.encodeIfPresent(self.kinds, forKey: MessageFilter.CodingKeys.kinds)
        try container.encodeIfPresent(self.tags, forKey: MessageFilter.CodingKeys.tags)
        try container.encodeIfPresent(self.since, forKey: MessageFilter.CodingKeys.since)
        try container.encodeIfPresent(self.until, forKey: MessageFilter.CodingKeys.until)
        try container.encodeIfPresent(self.limit, forKey: MessageFilter.CodingKeys.limit)
    }
}

extension Array where Element == MessageFilter {
    var json: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
}
