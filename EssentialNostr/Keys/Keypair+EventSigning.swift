//
//  Created by Jericho Hasselbush on 7/5/24.
//

import Foundation

protocol EventSigner {
    func sign(_ event: BaseEvent) throws -> Event
}

extension Keypair: EventSigner {
    private struct SigningFailureError: Error {}

    public func sign(_ event: BaseEvent) throws -> Event {
        guard let id = event.eventID, let bytes = id.bytes else { throw SigningFailureError() }
        let sig = try privateKey.signature(for: bytes)
        return Event(event, signed: { sig.dataRepresentation.hex })
    }
}
