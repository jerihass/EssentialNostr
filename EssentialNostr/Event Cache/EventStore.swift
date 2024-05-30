//
//  Created by Jericho Hasselbush on 5/28/24.
//

import Foundation

public protocol EventStore {
    typealias InsertionCompletion = (Error?) -> Void
    typealias DeletionCompletion = (Error?) -> Void
    func deleteCachedEvents(completion: @escaping DeletionCompletion)
    func insert(_ events: [LocalEvent], completion: @escaping InsertionCompletion)
}
