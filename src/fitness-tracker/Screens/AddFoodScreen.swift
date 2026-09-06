import SwiftUI
import UIKit

struct AddFoodScreen: View {
    let foodID: Int64

    @Environment(\.dismiss) private var dismiss
    @State private var food: AddFoodModel?
    @State private var errorMessage: String?
    @State private var selectedWeightGrams = 0.0
    private let nutritionService = NutritionService()

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    ScreenTitle(food?.title ?? "Add food")

                    if let subtitle = food?.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color("SearchBoxSecondary"))
                    }
                }

                CloseButton {
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            if let food {
                FoodPicture(imageURL: food.imageURL)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                WeightSelector(
                    servingSizeGrams: food.servingSizeGrams,
                    totalAmountGrams: food.totalAmountGrams,
                    selectedGrams: $selectedWeightGrams
                )
                .padding(.horizontal, 20)
                .padding(.top, 24)

                FoodStats(stats: scaledStats(for: food))
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                WarningMessage(
                    message: "Scaled from the reference entry, which is "
                    + "quoted per 100 g of cooked weight. Figures come from "
                    + "\(food.sourceName) and may not be precisely accurate."
                )
                .padding(.horizontal, 20)
                .padding(.top, 24)
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(Color("SearchBoxSecondary"))
                    .padding(20)
            } else {
                ProgressView()
                    .padding(.top, 40)
            }

            Spacer()

            PrimaryActionButton(title: "ADD TO TODAY", action: {})
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground"))
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 16)
                .onChanged { value in
                    if
                        value.translation.height > 16,
                        abs(value.translation.height)
                            > abs(value.translation.width)
                    {
                        dismissKeyboard()
                    }
                }
        )
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await loadFood()
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func loadFood() async {
        do {
            guard let loadedFood = try await nutritionService.foodDetails(
                id: foodID
            ) else {
                errorMessage = "Food could not be found."
                return
            }
            food = loadedFood
            selectedWeightGrams = WeightSelector.clampedWeight(
                loadedFood.servingSizeGrams
            )
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scaledStats(for food: AddFoodModel) -> FoodStatsModel {
        let selectedWeight = WeightSelector.clampedWeight(
            selectedWeightGrams
        )
        let ratio = selectedWeight / food.servingSizeGrams

        return FoodStatsModel(
            calories: food.stats.calories.map { $0 * ratio },
            nutrients: food.stats.nutrients.map { nutrient in
                NutrientModel(
                    name: nutrient.name,
                    shortName: nutrient.shortName,
                    amount: nutrient.amount.map { $0 * ratio },
                    unit: nutrient.unit
                )
            }
        )
    }
}

#Preview {
    AddFoodScreen(foodID: 22_411)
}
