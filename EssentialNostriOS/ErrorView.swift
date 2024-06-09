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
        Text(model.message)
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            .background(.red)
    }
}

#Preview {
    let model = ErrorViewModel(message: "Some Error")
    return ErrorView(model: model)
}
