//
//  Created by Jericho Hasselbush on 5/28/24.
//

import Foundation

public protocol EventStore {
    typealias InsertionCompletion = (Error?) -> Void
    typealias DeletionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (Result<[LocalEvent], Error>) -> Void

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads if needed.
    func deleteCachedEvents(completion: @escaping DeletionCompletion)

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads if needed.
    func insert(_ events: [LocalEvent], completion: @escaping InsertionCompletion)

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads if needed.
    func retrieve(completion: @escaping RetrievalCompletion)
}
