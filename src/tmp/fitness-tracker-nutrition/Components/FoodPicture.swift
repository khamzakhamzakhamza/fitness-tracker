import SwiftUI

struct FoodPicture: View {
    let imageURL: URL?
    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some View {
        if FoodItemImage.shouldLoadImage(
            imageURL: imageURL,
            isInternetAvailable: networkMonitor.isConnected
        ) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .empty:
                    ProgressView()
                case .failure:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 220)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("Food picture")
        }
    }
}

#Preview {
    FoodPicture(
        imageURL: URL(string: "https://picsum.photos/seed/food/600")
    )
    .padding(20)
    .background(Color("AppBackground"))
}
