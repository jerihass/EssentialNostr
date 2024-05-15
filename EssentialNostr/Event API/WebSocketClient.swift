//
//  Created by Jericho Hasselbush on 5/15/24.
//

import Foundation

public protocol WebSocketClient {
    typealias ReceiveResult = Result<Data, Error>
    func receive(with request: String, completion: @escaping (ReceiveResult) -> Void)
}
