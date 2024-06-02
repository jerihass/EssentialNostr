//
//  Created by Jericho Hasselbush on 5/29/24.
//

import Foundation

struct NostrEvent: Decodable {
    let id: String
    let pubkey: String
    let created_at: Double
    let kind: UInt16
    let tags: [[String]]
    let content: String
    let sig: String
}
