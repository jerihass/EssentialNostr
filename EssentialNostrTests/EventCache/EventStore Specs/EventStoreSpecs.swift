//
//  Created by Jericho Hasselbush on 6/1/24.
//

import Foundation

protocol EventStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache()
    func test_retrieve_hasNoSideEffects()
    func test_retrieve_deliversFoundValuesOnNonEmptyCache()
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache()
    func test_retrieve_deliversFailureOnRetrievalError()
    func test_retrieve_hasNoSideEffectsOnFailure()
    func test_insert_appendsCacheValuesToPreviousValues()
    func test_insert_deliversErroOnInsertionError()
    func test_delete_hasNoSideEffectsOnEmptyCache()
    func test_delete_emptiesPreviouslyInsertedCache()
    func test_delete_deliversErrorOnDeletionError()
    func test_storeSideEffects_runSerially()
}
