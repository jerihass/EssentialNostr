//
//  Created by Jericho Hasselbush on 7/4/24.
//

import Foundation
import CryptoKit

public extension Event {
    init(_ base: BaseEvent, signed: () -> String = { "SIG" } ) {
        self.init(id: base.eventID!, pubkey: base.pubkey, created_at: base.created_at, kind: base.kind, tags: base.tags, content: base.content, sig: signed() )
    }
}

extension BaseEvent: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try? container.encode(0)
        try? container.encode(pubkey)
        try? container.encode(created_at.timeIntervalSince1970)
        try? container.encode(kind)
        try? container.encode(tags)
        try? container.encode(content)
    }

    public var eventID: String? {
        guard let serialized = serialized else { return nil }
        let hash = CryptoKit.SHA256.hash(data: serialized)
        return Data(hash.bytes).hex
    }

    private var serialized: Data? {
        do {
            let json = try JSONEncoder().encode(self)
            return json
        } catch {
            return nil
        }
    }
}
