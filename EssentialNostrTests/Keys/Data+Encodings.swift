//
//  Created by Jericho Hasselbush on 5/21/24.
//

import Foundation

public extension Data {
    var hex: String {
        var out: String = ""
        for item in self {
            if item <= 15 { out += "0" }
            out += String(item, radix: 16)
        }
        return out
    }
}
extension Data {
    /// Converts base two bytes to base 5 // from nostr sdk
    var base5: Data {
        var outputSize = (count * 8) / 5
        if ((count * 8) % 5) != 0 {
            outputSize += 1
        }
        var outputArray: [UInt8] = []
        for i in (0..<outputSize) {
            let quotient = (i * 5) / 8
            let remainder = (i * 5) % 8
            var element = self[quotient] << remainder
            element >>= 3

            if (remainder > 3) && (i + 1 < outputSize) {
                element = element | (self[quotient + 1] >> (8 - remainder + 3))
            }

            outputArray.append(element)
        }

        return Data(outputArray)
    }

    var base8FromBase5: Data? {
        let destinationBase = 8
        let startingBase = 5
        let maxValueMask: UInt32 = ((UInt32(1)) << 8) - 1
        var value: UInt32 = 0
        var bits: Int = 0
        var output = Data()

        for i in (0..<count) {
            value = (value << startingBase) | UInt32(self[i])
            bits += startingBase
            while bits >= destinationBase {
                bits -= destinationBase
                output.append(UInt8((value >> bits) & maxValueMask))
            }
        }

        if ((value << (destinationBase - bits)) & maxValueMask) != 0 || bits >= startingBase {
            return nil
        }

        return output
    }
}


public extension String {
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
