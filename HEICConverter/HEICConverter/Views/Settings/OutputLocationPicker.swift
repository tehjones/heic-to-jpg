//
//  OutputLocationPicker.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import SwiftUI

struct OutputLocationPicker: View {
    let mode: OutputLocationMode
    let downloadsFolder: URL
    let customFolder: URL?
    let onUseSourceFolders: () -> Void
    let onUseDownloadsFolder: () -> Void
    let onUseCustomFolder: () -> Void
    let onSelectCustomFolder: () -> Void

    private var activeLabel: String {
        switch mode {
        case .sourceFolders:
            "Beside Each Original"
        case .downloads:
            downloadsFolder.path(percentEncoded: false)
        case .customFolder:
            customFolder?.path(percentEncoded: false) ?? "Choose a Folder"
        }
    }

    private var helpText: String {
        switch mode {
        case .sourceFolders:
            "Each JPEG is saved beside its original HEIC file."
        case .downloads:
            downloadsFolder.path(percentEncoded: false)
        case .customFolder:
            customFolder?.path(percentEncoded: false) ?? "Choose a folder for converted JPEGs."
        }
    }

    var body: some View {
        Menu {
            Button(action: onUseSourceFolders) {
                menuItem(
                    title: "Beside Each Original",
                    isSelected: mode == .sourceFolders
                )
            }

            Button(action: onUseDownloadsFolder) {
                menuItem(
                    title: "Downloads",
                    isSelected: mode == .downloads
                )
            }
            .help(downloadsFolder.path(percentEncoded: false))

            if let customFolder {
                Button(action: onUseCustomFolder) {
                    menuItem(
                        title: customFolder.lastPathComponent,
                        isSelected: mode == .customFolder
                    )
                }
                .help(customFolder.path(percentEncoded: false))
            }

            Divider()

            Button("Choose Another Folder…", systemImage: "folder.badge.plus", action: onSelectCustomFolder)
        } label: {
            Text(activeLabel)
                .font(.callout.weight(.medium))
                .lineLimit(1)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .menuStyle(.button)
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help(helpText)
    }

    private func menuItem(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }
}
