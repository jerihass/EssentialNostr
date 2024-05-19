//
//  Created by Jericho Hasselbush on 5/19/24.
//

import Foundation

public struct ClientMessage {
    public enum Message {
        case close(sub: String)
        case event(event: Event)
        case request(sub: String, filters: [Filter])
    }
}

public struct Filter {
    let ids: [String]?
    let authors: [String]?
    let kinds: [UInt16]?
    let tags: [Tag]?
    let since: Date?
    let until: Date?
    let limit: UInt?

    public init(ids: [String]? = nil, authors: [String]? = nil, kinds: [UInt16]? = nil, tags: [[String]]? = nil, since: Date? = nil, until: Date? = nil, limit: UInt? = nil) {
        self.ids = ids
        self.authors = authors
        self.kinds = kinds
        self.tags = tags?.compactMap(Tag.init)
        self.since = since
        self.until = until
        self.limit = limit
    }
}

struct Tag {
    let key: Character
    let tags: [String]

    init?(_ array: [String]) {
        guard array.count > 1 else { return nil }
        guard array.first?.count == 1, let key = array.first?.first else { return nil }
        let tags = Array(array.dropFirst())
        self.key = key
        self.tags = tags
    }
}
