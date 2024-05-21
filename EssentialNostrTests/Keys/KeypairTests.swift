//
//  Created by Jericho Hasselbush on 5/20/24.
//

import XCTest
import secp256k1
import EssentialNostr

class Keypair {
    let privateKey: secp256k1.Signing.PrivateKey
    let publicKeyData: Data
    init() throws {
        privateKey = try secp256k1.Signing.PrivateKey()
        publicKeyData = Data(privateKey.publicKey.xonly.bytes)
    }
}

class KeypairTests: XCTestCase {
    func test_init_generatesPrivateKey() throws {
        let key = try Keypair()
        XCTAssertEqual(key.privateKey.dataRepresentation.count, 32)
        XCTAssertEqual(key.publicKeyData.count, 32)
    }

    func test_sha256_eventJSONdata() {
        let data = baseEventJSONData(pubkey: "badpubkey", created_at: .now, kind: 1, tags: [["e"]], content: "content")
        let eventID = SHA256.hash(data: data)
        XCTAssertEqual(eventID.bytes.count, 32)
    }
}

private func baseEventJSONData(pubkey: String, created_at: Date, kind: UInt16, tags: [[String]], content: String) -> Data {
    let event = BaseEvent(pubkey: pubkey, created_at: created_at, kind: kind, tags: tags, content: content)
    let time = Int(created_at.timeIntervalSince1970)
    let tagString = tags.stringed

    let eventJSON = "{\"pubkey\":\"\(pubkey)\",\"created_at\":\(time),\"kind\":\(kind),\"tags\":\(tagString),\"content\":\"\(content)\"}"
    return Data(eventJSON.utf8)
}
