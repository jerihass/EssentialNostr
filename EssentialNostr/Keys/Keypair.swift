//
//  Created by Jericho Hasselbush on 7/4/24.
//

import Foundation
import secp256k1

public class Keypair {
    public let privateKey: secp256k1.Signing.PrivateKey
    public let publicKeyData: Data
    public init() throws {
        privateKey = try secp256k1.Signing.PrivateKey()
        publicKeyData = Data(privateKey.publicKey.xonly.bytes)
    }
}
