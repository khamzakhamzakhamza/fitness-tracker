import Charts
import SwiftUI

struct WeeklyWeightChangeEvent {
    let date: Date
    let originWeightSi: Double
    let weightSi: Double
}

struct WeeklyWeightLongPressEvent {
    let date: Date
    let weightSi: Double
}

private struct PlanChartGesturesModifier: ViewModifier {
    @Binding var scrollPosition: Date
    let siConversionValue: Double
    let onChanged: (WeeklyWeightChangeEvent) -> Void
    let onChangeEnded: () -> Void
    let onLongPress: (WeeklyWeightLongPressEvent) -> Void

    @State private var latestHorizontalDragPosition: Double?
    @State private var isHorizontalDragLocked: Bool?

    func body(content: Content) -> some View {
        content.chartOverlay { proxy in
            GeometryReader { geometry in
                if let plotFrameAnchor = proxy.plotFrame {
                    let plotFrame = geometry[plotFrameAnchor]

                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { drag in
                                    if isHorizontalDragLocked == nil {
                                        isHorizontalDragLocked = isHorizontalDrag(drag)
                                    }

                                    if isHorizontalDragLocked == true {
                                        guard let minimumDate = proxy.value(
                                            atX: 0,
                                            as: Date.self
                                        ),
                                        let maximumDate = proxy.value(
                                            atX: plotFrame.width,
                                            as: Date.self
                                        ) else {
                                            return
                                        }

                                        updateHorizontalScroll(
                                            drag: drag,
                                            minDate: minimumDate,
                                            maxDate: maximumDate
                                        )

                                        return
                                    }

                                    guard let event = makeWeeklyWeightChangeEvent(
                                        from: drag,
                                        proxy: proxy,
                                        plotFrame: plotFrame
                                    ) else {
                                        return
                                    }

                                    onChanged(event)
                                }
                                .onEnded { _ in
                                    if isHorizontalDragLocked == false {
                                        onChangeEnded()
                                    }

                                    isHorizontalDragLocked = nil
                                    latestHorizontalDragPosition = nil
                                }
                        )
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .sequenced(
                                    before: DragGesture(minimumDistance: 0)
                                )
                                .onEnded { gesture in
                                    guard case .second(true, let drag?) = gesture,
                                          let event = makeWeeklyWeightLongPressEvent(
                                              at: drag.startLocation,
                                              proxy: proxy,
                                              plotFrame: plotFrame
                                          ) else {
                                        return
                                    }

                                    onLongPress(event)
                                }
                        )
                }
            }
        }
    }

    private func makeWeeklyWeightChangeEvent(
        from drag: DragGesture.Value,
        proxy: ChartProxy,
        plotFrame: CGRect
    ) -> WeeklyWeightChangeEvent? {
        let plotX = drag.startLocation.x - plotFrame.minX
        let originPlotY = drag.startLocation.y - plotFrame.minY
        let plotY = drag.location.y - plotFrame.minY

        guard let date: Date = proxy.value(atX: plotX) else {
            return nil
        }

        guard let originWeight: Double = proxy.value(atY: originPlotY),
              let weight: Double = proxy.value(atY: plotY) else {
            return nil
        }

        return WeeklyWeightChangeEvent(
            date: date,
            originWeightSi: convertWeightToSi(originWeight),
            weightSi: convertWeightToSi(weight)
        )
    }

    private func makeWeeklyWeightLongPressEvent(
        at location: CGPoint,
        proxy: ChartProxy,
        plotFrame: CGRect
    ) -> WeeklyWeightLongPressEvent? {
        let plotX = location.x - plotFrame.minX
        let plotY = location.y - plotFrame.minY

        guard let date: Date = proxy.value(atX: plotX),
              let weight: Double = proxy.value(atY: plotY) else {
            return nil
        }

        return WeeklyWeightLongPressEvent(
            date: date,
            weightSi: convertWeightToSi(weight)
        )
    }

    private func convertWeightToSi(_ weightSi: Double) -> Double {
        weightSi * siConversionValue
    }

    private func updateHorizontalScroll(
        drag: DragGesture.Value,
        minDate: Date,
        maxDate: Date
    ) {
        let day = 60.0 * 60 * 24
        let secondsPerPoint: TimeInterval = day / 3

        let currentPosition = drag.location.x
        let previousPosition = latestHorizontalDragPosition
            ?? drag.startLocation.x

        let positionDelta = currentPosition - previousPosition

        let proposedPosition = scrollPosition.addingTimeInterval(
            -TimeInterval(positionDelta) * secondsPerPoint
        )

        scrollPosition = min(
            max(proposedPosition, minDate),
            maxDate
        )

        latestHorizontalDragPosition = currentPosition
    }

    private func isHorizontalDrag(_ drag: DragGesture.Value) -> Bool {
        abs(drag.translation.width) > abs(drag.translation.height)
    }
}

extension View {
    func addChartGestures(
        siConversionValue: Double,
        scrollPosition: Binding<Date>,
        onChanged: @escaping (WeeklyWeightChangeEvent) -> Void,
        onChangeEnded: @escaping () -> Void,
        onLongPress: @escaping (WeeklyWeightLongPressEvent) -> Void
    ) -> some View {
        modifier(
            PlanChartGesturesModifier(
                scrollPosition: scrollPosition,
                siConversionValue: siConversionValue,
                onChanged: onChanged,
                onChangeEnded: onChangeEnded,
                onLongPress: onLongPress
            )
        )
    }
}
