//
//  Created by Jericho Hasselbush on 6/30/24.
//
import Foundation

public protocol DataLoader {
    typealias Result = Swift.Result<Data, Error>
    func load(_ completion: @escaping (Result) -> Void)
}
