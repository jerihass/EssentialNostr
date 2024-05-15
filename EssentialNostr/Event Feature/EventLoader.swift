//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation

public protocol EventLoader {
    typealias LoadEventResult = Result<[Event], Error>
    func load(request: String, completion: @escaping (LoadEventResult) -> Void)
}
