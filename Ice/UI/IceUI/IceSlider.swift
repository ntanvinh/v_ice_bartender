//
//  IceSlider.swift
//  Ice
//

import SwiftUI

/// A standard slider with its current value written beside it.
struct IceSlider<Value: BinaryFloatingPoint, ValueLabel: View>: View where Value.Stride: BinaryFloatingPoint {
    @Binding private var value: Value

    private let bounds: ClosedRange<Value>
    private let step: Value?
    private let valueLabel: ValueLabel

    init(
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value? = nil,
        @ViewBuilder valueLabel: () -> ValueLabel
    ) {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.valueLabel = valueLabel()
    }

    init(
        _ valueLabelKey: LocalizedStringKey,
        value: Binding<Value>,
        in bounds: ClosedRange<Value>,
        step: Value? = nil
    ) where ValueLabel == Text {
        self._value = value
        self.bounds = bounds
        self.step = step
        self.valueLabel = Text(valueLabelKey)
    }

    var body: some View {
        HStack(spacing: 12) {
            Slider(value: snappedValue, in: bounds) { EmptyView() }
                .labelsHidden()
                .frame(minWidth: 140)
            valueLabel
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(minWidth: 84, alignment: .trailing)
        }
    }

    /// The value, rounded to the nearest step. The slider is continuous so that it does not
    /// draw a tick for every step, which on a long range is a dotted line.
    private var snappedValue: Binding<Value> {
        Binding {
            value
        } set: { newValue in
            guard let step, step > 0 else {
                value = newValue
                return
            }
            let snapped = bounds.lowerBound + ((newValue - bounds.lowerBound) / step).rounded() * step
            value = min(max(snapped, bounds.lowerBound), bounds.upperBound)
        }
    }
}
