//
//  Created by Jericho Hasselbush on 5/20/24.
//

import XCTest
import secp256k1
import CryptoKit
import EssentialNostr

class KeypairTests: XCTestCase {
    func test_init_generatesPrivateKey() throws {
        let key = try Keypair()
        XCTAssertEqual(key.privateKey.dataRepresentation.count, 32)
        XCTAssertEqual(key.publicKeyData.count, 32)
    }

    func test_event_fromBaseEventFillsID() {
        let pub = "17538dc2a62769d09443f18c37cbe358fab5bbf981173542aa7c5ff171ed77c4"
        let created = Date(timeIntervalSince1970: .init(integerLiteral: 1716341530))
        let kind: UInt16 = 1
        let tags = [["t","asknostr"]]
        let content = "Anyone have experience installing a whole house carbon (or otherwise) water filtration system? \n\n\n#asknostr"
        let base = BaseEvent(pubkey: pub, created_at: created, kind: kind, tags: tags, content: content)

        let event = Event(base)

        XCTAssertEqual(event.id, "f97819289cf0bcfb727ded99dc2ebc04d60fe9e4be0097e84fce8d1cc7f252b7")
    }
}

private func baseEventJSONData(pubkey: String, created_at: Date, kind: UInt16, tags: [[String]], content: String) -> Data {
    let event = BaseEvent(pubkey: pubkey, created_at: created_at, kind: kind, tags: tags, content: content)
    return try! JSONEncoder().encode(event)
}

extension Event {
    init(_ base: BaseEvent) {
        self.init(id: base.eventID!, pubkey: base.pubkey, created_at: base.created_at, kind: base.kind, tags: base.tags, content: base.content, sig: "SIGNATURE")
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

    var eventID: String? {
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
