//
//  Created by Jericho Hasselbush on 5/20/24.
//

import XCTest
import secp256k1
import CryptoKit
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
        let eventID = CryptoKit.SHA256.hash(data: data)
        XCTAssertEqual(eventID.bytes.count, 32)
    }

    func test_() {
        let json = """
        [0,"17538dc2a62769d09443f18c37cbe358fab5bbf981173542aa7c5ff171ed77c4",1716341530,1,[["t","asknostr"]],"Anyone have experience installing a whole house carbon (or otherwise) water filtration system? \\n\\n\\n#asknostr"]
        """.data(using: .utf8)!
        let hash = CryptoKit.SHA256.hash(data: json)
        let hex = Data(hash.bytes).hex
        print(hex)
        XCTAssertEqual(hex, "f97819289cf0bcfb727ded99dc2ebc04d60fe9e4be0097e84fce8d1cc7f252b7")
    }
}

private func baseEventJSONData(pubkey: String, created_at: Date, kind: UInt16, tags: [[String]], content: String) -> Data {
    let event = BaseEvent(pubkey: pubkey, created_at: created_at, kind: kind, tags: tags, content: content)
    let time = Int(created_at.timeIntervalSince1970)
    let tagString = tags.stringed

    let eventJSON = "{\"pubkey\":\"\(pubkey)\",\"created_at\":\(time),\"kind\":\(kind),\"tags\":\(tagString),\"content\":\"\(content)\"}"
    return Data(eventJSON.utf8)
}
