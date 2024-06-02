//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation

public protocol EventLoader {
    typealias LoadEventResult = Result<Event, Error>
    func request(_ message: String)
    func load(_ completion: @escaping (LoadEventResult) -> Void)
}
