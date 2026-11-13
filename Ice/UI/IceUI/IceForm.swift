//
//  IceForm.swift
//  Ice
//

import SwiftUI

/// A settings page: the system's grouped form, the same one System Settings is built from.
///
/// Rows get the standard control sizes, switches at the trailing edge, separators between rows
/// and the system's own spacing, margins and scrolling.
struct IceForm<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Form {
            content
        }
        .formStyle(.grouped)
    }
}
