//
//  FooterView.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import SwiftUI

struct FooterView: View {
    var body: some View {
        Label("Private and offline — your photos never leave this Mac", systemImage: "lock.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
