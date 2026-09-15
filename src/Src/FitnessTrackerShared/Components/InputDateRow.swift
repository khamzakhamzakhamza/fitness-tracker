import SwiftUI

public struct InputDateRow: View {
    @Binding public var date: Date?
    public let label: String
    public let showValidationError: Bool
    public let allowedDateRange: ClosedRange<Date>?
    private let pickerVisibility: Binding<Bool>?
    @State private var internalPickerVisibility = false

    public init(
        date: Binding<Date?>,
        label: String,
        showValidationError: Bool = false,
        allowedDateRange: ClosedRange<Date>? = nil,
        isPickerShowing: Binding<Bool>? = nil
    ) {
        _date = date
        self.label = label
        self.showValidationError = showValidationError
        self.allowedDateRange = allowedDateRange
        pickerVisibility = isPickerShowing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(Constants.secondaryTextColor))

            Button {
                setPickerShowing(!isPickerShowing)
            } label: {
                HStack {
                    Text(displayValue)
                        .foregroundStyle(date == nil ? Color(Constants.secondaryTextColor) : .primary)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            showValidationError ? Color.red : Color.primary.opacity(0.15),
                            lineWidth: showValidationError ? 1.5 : 1
                        )
                }
            }
            .buttonStyle(.plain)

            if isPickerShowing {
                DatePicker(
                    Constants.datePickerLabel,
                    selection: pickerDate,
                    in: effectiveDateRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipped()
            }
        }
    }

    private var displayValue: String {
        guard let date else {
            return Constants.placeholder
        }

        return date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year())
    }

    private var pickerDate: Binding<Date> {
        Binding(
            get: { date ?? defaultDate },
            set: { date = $0 }
        )
    }

    private var defaultDate: Date {
        let twentyFiveYearsAgo = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
        return min(max(twentyFiveYearsAgo, effectiveDateRange.lowerBound), effectiveDateRange.upperBound)
    }

    private var effectiveDateRange: ClosedRange<Date> {
        allowedDateRange ?? earliestDate...Date()
    }

    private var isPickerShowing: Bool {
        pickerVisibility?.wrappedValue ?? internalPickerVisibility
    }

    private func setPickerShowing(_ isShowing: Bool) {
        if let pickerVisibility {
            pickerVisibility.wrappedValue = isShowing
        } else {
            internalPickerVisibility = isShowing
        }
    }

    private var earliestDate: Date {
        Calendar.current.date(from: DateComponents(year: 1900, month: 1, day: 1)) ?? .distantPast
    }
}

private enum Constants {
    static let secondaryTextColor = "SearchBoxSecondary"
    static let datePickerLabel = "Date of birth"
    static let placeholder = "DD / MM / YYYY"
}
