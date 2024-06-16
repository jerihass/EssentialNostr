//
//  Created by Jericho Hasselbush on 6/15/24.
//

import XCTest
@testable import EssentialNostriOS

class LocalizedFeedViewTests: XCTestCase {
    func test_feedViewTitle() {
        let sut = TitleViewModel()
        let bundle = Bundle(for: NostrLocalizedStrings.self)
        let localizedKey = "EVENT_VIEW_TITLE"
        let localizedTitle = bundle.localizedString(forKey: localizedKey, value: nil, table: "EventsFeed")
        XCTAssertEqual(sut.title, localizedTitle)
        XCTAssertNotEqual(localizedKey, localizedTitle, "Missing localized string for key: \(localizedKey)")
    }
}
