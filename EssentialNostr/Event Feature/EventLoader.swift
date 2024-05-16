//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation
public typealias LoadEventResult = Result<Event, Error>

public protocol EventLoader {
    func load(request: String, completion: @escaping (LoadEventResult) -> Void)
}
