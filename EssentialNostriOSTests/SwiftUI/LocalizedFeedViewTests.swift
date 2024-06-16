//
//  Created by Jericho Hasselbush on 6/15/24.
//

import XCTest
@testable import EssentialNostriOS

class LocalizedFeedViewTests: XCTestCase {
    func test_feedViewTitle() {
        let sut = TitleViewModel()

        XCTAssertEqual(sut.title, localized("EVENT_VIEW_TITLE"))
    }
}
