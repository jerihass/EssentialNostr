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
