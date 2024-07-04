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

    func test_event_fromBaseEventFillsID2() {
        let pub = "b154080cb49639bb079a6a53c1d98e7130eeab3c61aa95dd9e38f9e400027cc7"
        let created = Date(timeIntervalSince1970: .init(integerLiteral: 1720110007))
        let kind: UInt16 = 1
        let tags: [[String]] = []
        let content = "Zach Bryan has already done way enough for Country to be put in the Hall of Fame"
        let base = BaseEvent(pubkey: pub, created_at: created, kind: kind, tags: tags, content: content)

        let event = Event(base)

        XCTAssertEqual(event.id, "4e9d274e0817aca5dbc0d9abcdafaf6abf73faf8109d76e09dab241d7685694c")
    }

    func test_sign_eventGivesSignatureInEvent() {
        let keys = try! Keypair()
        let pub = keys.publicKeyData.hex
        let created = Date.now
        let kind: UInt16 = 1
        let tags: [[String]] = []
        let content = "Some test content"
        let base = BaseEvent(pubkey: pub, created_at: created, kind: kind, tags: tags, content: content)

        let signer = Signer()
        signer.signatory = { _ in
            let sig = try! keys.privateKey.signature(for: (base.eventID?.bytes)!)
            return sig.dataRepresentation.hex
        }
        let event = try! signer.sign(base)

        print(event.sig)
        XCTAssertTrue(event.sig.count == 128)
    }
}

private func baseEventJSONData(pubkey: String, created_at: Date, kind: UInt16, tags: [[String]], content: String) -> Data {
    let event = BaseEvent(pubkey: pubkey, created_at: created_at, kind: kind, tags: tags, content: content)
    return try! JSONEncoder().encode(event)
}

protocol EventSigner {
    var signatory: (String) -> String { get }
    func sign(_ event: BaseEvent) throws -> Event
}

class Signer: EventSigner {
    var signatory: (String) -> String = { _ in "" }
    private struct SigningFailureError: Error {}
    func sign(_ event: EssentialNostr.BaseEvent) throws -> EssentialNostr.Event {
        guard let id = event.eventID else { throw SigningFailureError() }
        let sig = signatory(id)
        return Event(event, signed: { sig })
    }
}
