//
//  Created by Jericho Hasselbush on 5/31/24.
//

import Foundation

public protocol FeedLoader {
    typealias LoadResult = Result<[Event], Error>
    func load(completion: @escaping (LoadResult) -> Void)
}

public typealias EventsRequester = () -> String
