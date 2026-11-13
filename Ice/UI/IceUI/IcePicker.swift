//
//  IcePicker.swift
//  Ice
//

import SwiftUI

/// A pop-up menu picker with its label at the leading edge of the row.
struct IcePicker<Label: View, SelectionValue: Hashable, Content: View>: View {
    @Binding var selection: SelectionValue

    let label: Label
    let content: Content

    init(
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self._selection = selection
        self.label = label()
        self.content = content()
    }

    init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) where Label == Text {
        self.init(selection: selection) {
            content()
        } label: {
            Text(titleKey)
        }
    }

    var body: some View {
        Picker(selection: $selection) {
            content
                .labelStyle(.titleAndIcon)
        } label: {
            label
        }
        .pickerStyle(.menu)
    }
}
