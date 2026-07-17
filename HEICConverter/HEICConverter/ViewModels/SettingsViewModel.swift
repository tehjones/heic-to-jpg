//
//  SettingsViewModel.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import Foundation
import SwiftUI
import AppKit

enum OutputLocationMode: String {
    case sourceFolders
    case downloads
    case customFolder
}

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Properties

    var quality: Double = UserDefaults.standard.conversionQuality {
        didSet {
            UserDefaults.standard.conversionQuality = quality
        }
    }

    var notifyOnCompletion: Bool = UserDefaults.standard.notifyOnCompletion {
        didSet {
            UserDefaults.standard.notifyOnCompletion = notifyOnCompletion
        }
    }

    private(set) var outputLocationMode: OutputLocationMode
    private(set) var customOutputFolder: URL?

    var downloadsFolder: URL {
        Self.downloadsFolder
    }

    var outputFolder: URL? {
        switch outputLocationMode {
        case .sourceFolders:
            nil
        case .downloads:
            downloadsFolder
        case .customFolder:
            customOutputFolder
        }
    }

    var settings: ConversionSettings {
        ConversionSettings(
            quality: quality,
            customOutputFolder: outputFolder,
            notifyOnCompletion: notifyOnCompletion
        )
    }

    // MARK: - Private

    @ObservationIgnored
    private var scopedURL: URL?

    @ObservationIgnored
    private let notificationService: NotificationService

    // MARK: - Init

    init(notificationService: NotificationService = .init()) {
        self.notificationService = notificationService

        let restoredFolder = Self.restoreOutputFolder()
        let restoredDownloads = restoredFolder.map(Self.isDownloadsFolder) ?? false
        let restoredCustomFolder = restoredDownloads ? nil : restoredFolder
        customOutputFolder = restoredCustomFolder

        if restoredDownloads {
            UserDefaults.standard.outputFolderBookmark = nil
        }

        if let savedMode = UserDefaults.standard.outputLocationMode
            .flatMap(OutputLocationMode.init(rawValue:)) {
            if savedMode == .customFolder && restoredDownloads {
                outputLocationMode = .downloads
            } else if savedMode == .customFolder && restoredCustomFolder == nil {
                outputLocationMode = .sourceFolders
            } else {
                outputLocationMode = savedMode
            }
        } else {
            // Before the destination menu existed, a saved bookmark meant the
            // custom folder was active. Preserve that choice during migration.
            if restoredDownloads {
                outputLocationMode = .downloads
            } else {
                outputLocationMode = restoredFolder == nil ? .sourceFolders : .customFolder
            }
        }

        UserDefaults.standard.outputLocationMode = outputLocationMode.rawValue

        if outputLocationMode == .customFolder, let url = restoredCustomFolder {
            if url.startAccessingSecurityScopedResource() {
                scopedURL = url
            }
        }
    }

    deinit {
        scopedURL?.stopAccessingSecurityScopedResource()
    }

    // MARK: - Notifications

    func enableNotifications() async -> Bool {
        await notificationService.enableCompletionNotifications()
    }

    func openNotificationSettings() {
        notificationService.openNotificationSettings()
    }

    // MARK: - Folder Selection

    func selectCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder for converted images"

        let completion: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }

            if Self.isDownloadsFolder(url) {
                self.useDownloadsFolder()
                return
            }

            self.scopedURL?.stopAccessingSecurityScopedResource()
            self.customOutputFolder = url
            self.scopedURL = url.startAccessingSecurityScopedResource() ? url : nil
            self.saveOutputFolder(url)
            self.setOutputLocationMode(.customFolder)
        }

        if let window = NSApp.keyWindow ?? NSApp.mainWindow {
            panel.beginSheetModal(for: window, completionHandler: completion)
        } else {
            panel.begin(completionHandler: completion)
        }
    }

    func useSourceFolders() {
        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = nil
        setOutputLocationMode(.sourceFolders)
    }

    func useDownloadsFolder() {
        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = nil
        setOutputLocationMode(.downloads)
    }

    func useCustomFolder() {
        guard let customOutputFolder else {
            selectCustomFolder()
            return
        }

        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = customOutputFolder.startAccessingSecurityScopedResource()
            ? customOutputFolder
            : nil
        setOutputLocationMode(.customFolder)
    }

    // MARK: - Persistence

    private func saveOutputFolder(_ url: URL) {
        UserDefaults.standard.outputFolderBookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    private func setOutputLocationMode(_ mode: OutputLocationMode) {
        outputLocationMode = mode
        UserDefaults.standard.outputLocationMode = mode.rawValue
    }

    private static var downloadsFolder: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    }

    private static func isDownloadsFolder(_ url: URL) -> Bool {
        url.standardizedFileURL == downloadsFolder.standardizedFileURL
    }

    private static func restoreOutputFolder() -> URL? {
        guard let bookmark = UserDefaults.standard.outputFolderBookmark else { return nil }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            UserDefaults.standard.outputFolderBookmark = nil
            return nil
        }

        if isStale {
            let refreshedBookmark = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            if let refreshedBookmark {
                UserDefaults.standard.outputFolderBookmark = refreshedBookmark
            }
        }

        return url
    }
}
