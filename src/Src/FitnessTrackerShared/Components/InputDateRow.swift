import SwiftUI

public struct InputDateRow: View {
    @Binding public var date: Date?
    public let label: String
    @State private var isShowingPicker = false

    public init(date: Binding<Date?>, label: String) {
        _date = date
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color("SearchBoxSecondary"))

            Button {
                isShowingPicker.toggle()
            } label: {
                HStack {
                    Text(displayValue)
                        .foregroundStyle(date == nil ? Color("SearchBoxSecondary") : .primary)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.primary.opacity(0.15), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            if isShowingPicker {
                DatePicker(
                    "Date of birth",
                    selection: pickerDate,
                    in: earliestDate...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity, height: 180)
                .clipped()
            }
        }
    }

    private var displayValue: String {
        guard let date else {
            return "DD / MM / YYYY"
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
        Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    }

    private var earliestDate: Date {
        Calendar.current.date(from: DateComponents(year: 1900, month: 1, day: 1)) ?? .distantPast
    }
}
