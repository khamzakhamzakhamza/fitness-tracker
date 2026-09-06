import SwiftUI

struct FoodItemImage: View {
    let imageURL: URL?
    let isInternetAvailable: Bool

    nonisolated static func shouldLoadImage(
        imageURL: URL?,
        isInternetAvailable: Bool
    ) -> Bool {
        guard
            isInternetAvailable,
            let imageURL,
            let scheme = imageURL.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            imageURL.host != nil
        else {
            return false
        }

        return true
    }

    var body: some View {
        Group {
            if Self.shouldLoadImage(
                imageURL: imageURL,
                isInternetAvailable: isInternetAvailable
            ) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty, .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 52, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            Color("SearchBoxSecondary").opacity(0.15)

            Image(systemName: "photo")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color("SearchBoxSecondary"))
        }
    }
}

#Preview("Online") {
    FoodItemImage(
        imageURL: URL(string: "https://picsum.photos/seed/food/100"),
        isInternetAvailable: true
    )
}

#Preview("Offline") {
    FoodItemImage(
        imageURL: URL(string: "https://picsum.photos/seed/food/100"),
        isInternetAvailable: false
    )
}
