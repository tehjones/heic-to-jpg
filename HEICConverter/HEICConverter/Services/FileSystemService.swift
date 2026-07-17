//
//  FileSystemService.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import Foundation

actor FileSystemService {
    private let fileManager = FileManager.default

    /// Collects all HEIC files from the provided URLs (files or directories).
    func collectHEICFiles(from urls: [URL]) async -> [(url: URL, relativePath: String?)] {
        urls.flatMap { url -> [(url: URL, relativePath: String?)] in
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return [] }

            if isDirectory.boolValue {
                return collectHEICFilesRecursively(from: url, baseURL: url)
            } else if url.isHEICFile {
                return [(url, nil)]
            }
            return []
        }
    }

    /// Recursively collects HEIC files from a directory.
    private func collectHEICFilesRecursively(from directory: URL, baseURL: URL) -> [(url: URL, relativePath: String?)] {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        return enumerator
            .compactMap { $0 as? URL }
            .filter { url in
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                return !isDirectory && url.isHEICFile
            }
            .map { ($0, $0.relativePath(from: baseURL)) }
    }

    /// Creates the destination URL for a converted file, creating intermediate directories as needed.
    func createDestinationURL(
        for sourceURL: URL,
        relativePath: String?,
        settings: ConversionSettings
    ) async throws -> URL {
        let directory: URL

        if let outputFolder = settings.customOutputFolder {
            var customDirectory = outputFolder

            if let relativePath {
                let subdirectory = (relativePath as NSString).deletingLastPathComponent
                if !subdirectory.isEmpty {
                    customDirectory = customDirectory.appendingPathComponent(subdirectory)
                }
            }

            try fileManager.createDirectory(at: customDirectory, withIntermediateDirectories: true)
            directory = customDirectory
        } else {
            directory = sourceURL.deletingLastPathComponent()
        }

        let filename = sourceURL.deletingPathExtension().lastPathComponent
        return directory.appendingPathComponent("\(filename).jpg")
    }
}
