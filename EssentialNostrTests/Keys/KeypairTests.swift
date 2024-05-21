//
//  Created by Jericho Hasselbush on 5/20/24.
//

import XCTest
import secp256k1

class Keypair {
    let privateKey: secp256k1.Signing.PrivateKey

    init() throws {
        privateKey = try secp256k1.Signing.PrivateKey()
    }
}

class KeypairTests: XCTestCase {
    func test_init_generatesPrivateKey() throws {
        let key = try Keypair()
        XCTAssertEqual(key.privateKey.dataRepresentation.count, 32)
    }
}
