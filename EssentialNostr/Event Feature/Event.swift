//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation

public struct Event: Equatable {
    public let id: String
    public let pubkey: String
    public let created_at: Date
    public let kind: UInt16
    public let tags: [[String]]
    public let content: String
    public let sig: String

    public init(id: String, pubkey: String, created_at: Date, kind: UInt16, tags: [[String]], content: String, sig: String) {
        self.id = id
        self.pubkey = pubkey
        self.created_at = created_at
        self.kind = kind
        self.tags = tags
        self.content = content
        self.sig = sig
    }
}
