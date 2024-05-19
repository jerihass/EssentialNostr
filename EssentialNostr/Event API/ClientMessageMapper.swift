//
//  Created by Jericho Hasselbush on 5/19/24.
//

import Foundation

public final class ClientMessageMapper {
    public static func mapMessage(_ message: ClientMessage.Message) -> String {
        let tagSep = "]},{\"#"
        let tagRep = "],\"#"

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
                trimmed = trimmed.replacingOccurrences(of: tagSep, with: tagRep)
                trimmed = removeTagsSection(from: trimmed)!

                return "[\"REQ\",\"\(sub)\",\(trimmed)]"
            }
        }
        return ""

        func removeTagsSection(from jsonString: String) -> String? {
           let pattern = "\"tags\":\\[\\{(.*?)\\}\\]"

           let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])

           let modifiedString = regex?.stringByReplacingMatches(
               in: jsonString,
               options: [],
               range: NSRange(location: 0, length: jsonString.utf16.count),
               withTemplate: "$1"
           )

           return modifiedString
       }
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

private struct MessageTag: Encodable {
    let key: Character
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case tags
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        try container.encode(tags, forKey: DynamicCodingKey(stringValue: "#\(key)")!)
    }

    init(_ tag: Tag) {
        key = tag.key
        tags = tag.tags
    }

    init?(_ array: [String]) {
        guard array.count > 1 else { return nil }
        guard let key = array.first?.first else { return nil }
        let tags = Array(array.dropFirst())
        self.key = key
        self.tags = tags
    }
}

// Helper struct for dynamic coding keys
private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

private struct MessageFilter: Encodable {
    let ids: [String]?
    let authors: [String]?
    let kinds: [UInt16]?
    let tags: [MessageTag]?
    let since: Int?
    let until: Int?
    let limit: UInt?

    init(ids: [String]? = nil, authors: [String]? = nil, kinds: [UInt16]? = nil, tags: [[String]]? = nil, since: Int? = nil, until: Int? = nil, limit: UInt? = nil) {
        self.ids = ids
        self.authors = authors
        self.kinds = kinds
        self.tags = tags?.compactMap(MessageTag.init)
        self.since = since
        self.until = until
        self.limit = limit
    }

    init(_ filter: Filter) {
        ids = filter.ids
        authors = filter.authors
        kinds = filter.kinds
        tags = filter.tags?.compactMap(MessageTag.init)
        if let s = filter.since?.timeIntervalSince1970 {
            since = Int(s)
        } else { since = nil }
        if let u = filter.until?.timeIntervalSince1970 {
            until = Int(u)
        } else { until = nil }
        limit = filter.limit
    }
}

extension Array where Element == MessageFilter {
    var json: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
}
