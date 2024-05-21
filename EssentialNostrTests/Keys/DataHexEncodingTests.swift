//
//  Created by Jericho Hasselbush on 5/21/24.
//

import XCTest

extension Data {
    var hex: String {
        var out: String = ""
        for item in self {
            if item <= 15 { out += "0" }
            out += String(item, radix: 16)
        }
        return out
    }
}

class DataHexEncodingTests: XCTestCase {
    func test_hex_converts8BitToHex() {
        let data: Data = Data([10, 11, 12, 13, 14])
        let hex = data.hex
        XCTAssertEqual(hex, "abcde")
    }
}
