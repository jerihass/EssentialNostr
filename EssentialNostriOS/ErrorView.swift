//
//  Created by Jericho Hasselbush on 6/9/24.
//

import SwiftUI

public struct ErrorView: View {
    let message: String
    public var body: some View {
        Text(message)
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            .background(.red)
    }
}

#Preview {
    ErrorView(message: "Some Error")
}
