//
//  Created by Jericho Hasselbush on 5/16/24.
//

import XCTest
extension XCTestCase {
    func trackForMemoryLeaks(_ object: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Instance should have been deallocated. Possible memory leak.", file: file, line: line)
        }
    }
}
