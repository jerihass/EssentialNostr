//
//  Created by Jericho Hasselbush on 5/20/24.
//

import Foundation

public struct BaseEvent {
    public let pubkey: String
    public let created_at: Date
    public let kind: UInt16
    public let tags: [[String]]
    public let content: String

    public init(pubkey: String, created_at: Date, kind: UInt16, tags: [[String]], content: String) {
        self.pubkey = pubkey
        self.created_at = created_at
        self.kind = kind
        self.tags = tags
        self.content = content
    }
}
