//
//  IceSection.swift
//  Ice
//

import SwiftUI

/// A group of related rows inside an ``IceForm``, drawn by the system as one rounded card.
struct IceSection<Header: View, Content: View, Footer: View>: View {
    private let header: Header
    private let content: Content
    private let footer: Footer

    init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.header = header()
        self.content = content()
        self.footer = footer()
    }

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) where Header == EmptyView {
        self.init {
            EmptyView()
        } content: {
            content()
        } footer: {
            footer()
        }
    }

    init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) where Footer == EmptyView {
        self.init {
            header()
        } content: {
            content()
        } footer: {
            EmptyView()
        }
    }

    init(
        @ViewBuilder content: () -> Content
    ) where Header == EmptyView, Footer == EmptyView {
        self.init {
            EmptyView()
        } content: {
            content()
        } footer: {
            EmptyView()
        }
    }

    init(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) where Header == Text, Footer == EmptyView {
        self.init {
            Text(title)
        } content: {
            content()
        }
    }

    var body: some View {
        Section {
            content
        } header: {
            header
        } footer: {
            footer
        }
    }
}
