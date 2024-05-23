//
//  Created by Jericho Hasselbush on 5/21/24.
//

import XCTest
import EssentialNostr

class DataHexEncodingTests: XCTestCase {
    func test_hex_converts8BitToHex() {
        let data: Data = Data([255, 17, 0, 15, 255])
        let hex = data.hex
        XCTAssertEqual(hex, "ff11000fff")
    }

    func test_data_convertsHexToBytes() {
        let hex = "ff11000fff"
        let out = hex.bytes
        XCTAssertEqual(out, Data([255, 17, 0, 15, 255]))
    }

    func test_hex_toBech32() {
        let data = Data([255, 255, 255, 255, 255])
        let chars = data.hex
        let charData = Data(chars.utf8)
        let encoded = Bech32.encode("npub", baseEightData: charData)
        XCTAssertTrue(encoded.starts(with: "npub"))
    }
}
