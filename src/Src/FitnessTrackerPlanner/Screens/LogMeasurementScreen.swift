import SwiftUI

public struct LogMeasurementScreen: View {
    public init() {}

    public var body: some View {
        Text("Log measurement")
            .font(.system(size: 28, weight: .black))
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .padding(20)
            .navigationTitle("Log measurement")
            .navigationBarTitleDisplayMode(.inline)
    }
}
