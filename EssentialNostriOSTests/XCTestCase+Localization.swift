//
//  Created by Jericho Hasselbush on 6/15/24.
//

import XCTest
@testable import EssentialNostriOS

extension XCTestCase {
    func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
        let table = "EventsFeed"
        let bundle = Bundle(for: NostrLocalizedStrings.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        if value == key {
            XCTFail("Missing localized string for key: \(key) in table \(table)", file: file, line: line)
        }
        return value
    }
}
