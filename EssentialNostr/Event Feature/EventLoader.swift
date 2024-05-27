//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation
public typealias LoadEventResult = Result<Event, Error>

public protocol EventLoader {
    func request(_ message: String)
    func load(_ completion: @escaping (LoadEventResult) -> Void)
}
