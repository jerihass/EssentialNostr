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

extension String {
    var bytes: Data? {
        guard self.count % 2 == 0 else { return nil }
        // check all values between 0-9a-f
        var bytes = [UInt8]()
        var index = self.startIndex
            for _ in 0..<self.count / 2 {
                let nextIndex = self.index(index, offsetBy: 2)
                let byteString = self[index..<nextIndex]
                guard let byte = UInt8(byteString, radix: 16) else { return nil }
                bytes.append(byte)
                index = nextIndex
            }
        return Data(bytes)
    }
}

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
}
