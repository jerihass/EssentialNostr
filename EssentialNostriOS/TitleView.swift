//
//  Created by Jericho Hasselbush on 6/15/24.
//

import SwiftUI

public struct TitleViewModel {
    let title: String
}

public struct TitleView: View {
    private let model: TitleViewModel

    public init(model: TitleViewModel) {
        self.model = model
    }

    public var body: some View {
        Text(model.title)
            .font(.title)
    }
}
