import SwiftUI

public struct NutritionScreen: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading) {
            Text("Nutrition")
                .font(.system(size: 28, weight: .black))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}
