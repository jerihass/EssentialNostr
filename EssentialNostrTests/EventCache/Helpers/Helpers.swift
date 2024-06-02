//
//  Created by Jericho Hasselbush on 5/31/24.
//

import Foundation
import EssentialNostr

func anyError() -> NSError {
    NSError(domain: "domain", code: 1)
}

func uniqueEvent() -> Event {
    return Event(id: UUID().uuidString, publicKey: "pubkey", created: .now, kind: 1, tags: [[]], content: "Some content", signature: "signature")
}

func uniqueEvents() -> (model: [Event], local: [LocalEvent]) {
    let events = [uniqueEvent(), uniqueEvent()]
    let localEvents = events.map { LocalEvent(id: $0.id, publicKey: $0.publicKey, created: $0.created, kind: $0.kind, tags: $0.tags, content: $0.content, signature: $0.signature)}
    return (events, localEvents)
}
