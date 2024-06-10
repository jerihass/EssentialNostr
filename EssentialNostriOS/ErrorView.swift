//
//  Created by Jericho Hasselbush on 6/9/24.
//

import SwiftUI

public struct ErrorViewModel {
    let message: String
}

public struct ErrorView: View {
    let model: ErrorViewModel
    public var body: some View {
        if !model.message.isEmpty {
            Text(model.message)
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .background(.red)
        }
    }
}

#Preview {
    let model = ErrorViewModel(message: "Some Error")
    return ErrorView(model: model)
}
