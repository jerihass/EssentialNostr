//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation

public struct Event: Equatable {
    let id: String
    let pubkey: String
    let created_at: Date
    let kind: UInt16
    let tags: [[String]]
    let content: String
    let sig: String
}
