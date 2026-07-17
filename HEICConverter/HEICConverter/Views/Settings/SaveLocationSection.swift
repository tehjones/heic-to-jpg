//
//  SaveLocationSection.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import SwiftUI

struct SaveLocationSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Save JPEGs", systemImage: "folder.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            OutputLocationPicker(
                mode: viewModel.outputLocationMode,
                downloadsFolder: viewModel.downloadsFolder,
                customFolder: viewModel.customOutputFolder,
                onUseSourceFolders: viewModel.useSourceFolders,
                onUseDownloadsFolder: viewModel.useDownloadsFolder,
                onUseCustomFolder: viewModel.useCustomFolder,
                onSelectCustomFolder: viewModel.selectCustomFolder
            )
        }
    }
}
