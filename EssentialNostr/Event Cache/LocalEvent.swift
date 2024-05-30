//
//  Created by Jericho Hasselbush on 5/29/24.
//

import Foundation

public struct LocalEvent: Equatable {
    public let id: String
    public let publickey: String
    public let created: Date
    public let kind: UInt16
    public let tags: [[String]]
    public let content: String
    public let signature: String

    public init(id: String, pubkey: String, created_at: Date, kind: UInt16, tags: [[String]], content: String, sig: String) {
        self.id = id
        self.publickey = pubkey
        self.created = created_at
        self.kind = kind
        self.tags = tags
        self.content = content
        self.signature = sig
    }
}
