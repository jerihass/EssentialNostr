//
//  Created by Jericho Hasselbush on 5/14/24.
//

import Foundation

protocol EventLoader {
    typealias LoadEventResult = Result<[Event], Error>
    func load(completion: @escaping (LoadEventResult) -> Void)
}
