//
//  Created by Jericho Hasselbush on 6/16/24.
//

import Foundation
import SwiftData
import EssentialNostr

@Model
class SDEvent {
    public let id: String
    public let publickey: String
    public let created: Date
    public let kind: UInt16
    public let tags: [[String]]
    public let content: String
    public let signature: String

    public init(id: String, publicKey: String, created: Date, kind: UInt16, tags: [[String]], content: String, signature: String) {
        self.id = id
        self.publickey = publicKey
        self.created = created
        self.kind = kind
        self.tags = tags
        self.content = content
        self.signature = signature
    }
}
