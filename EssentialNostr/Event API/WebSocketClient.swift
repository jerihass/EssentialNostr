//
//  Created by Jericho Hasselbush on 5/15/24.
//

import Foundation
import Network

public protocol WebSocketClient: AnyObject {
    typealias ReceiveResult = Result<Data, Error>

    func start()
    func disconnect()

    func send(message: String, completion: @escaping (Swift.Error) -> Void)
    func receive(completion: @escaping (_ result: ReceiveResult) -> Void)
}
