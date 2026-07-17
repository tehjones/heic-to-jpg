//
//  SettingsPanel.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import SwiftUI

struct SettingsPanel: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        HStack(spacing: 18) {
            SaveLocationSection(viewModel: viewModel)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 52)

            QualitySliderView(quality: $viewModel.quality)
                .frame(width: 220)

            Divider()
                .frame(height: 52)

            NotificationsSection(viewModel: viewModel)
                .frame(width: 150)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(GlassStyle.glassBorder, lineWidth: 1)
                }
        }
    }
}

#Preview {
    ZStack {
        GlassStyle.darkBackground
            .ignoresSafeArea()

        SettingsPanel(viewModel: SettingsViewModel())
    }
}
