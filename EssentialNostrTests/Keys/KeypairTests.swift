//
//  Created by Jericho Hasselbush on 5/20/24.
//

import XCTest
import secp256k1

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
}
