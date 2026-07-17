//
//  ImageConversionService.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

final class ImageConversionService: Sendable {

    // MARK: - Public

    nonisolated static var recommendedConcurrencyLimit: Int {
        max(2, min(ProcessInfo.processInfo.activeProcessorCount, 8))
    }

    nonisolated func convert(
        sourceURL: URL,
        destinationURL: URL,
        quality: Double,
        progressHandler: @escaping @MainActor @Sendable (Double) -> Void
    ) async throws -> ConversionResult {
        try await sourceURL.accessSecurityScopedResource {
            await progressHandler(0.1)

            guard let imageSource = CGImageSourceCreateWithURL(
                sourceURL as CFURL,
                [kCGImageSourceShouldCache: false] as CFDictionary
            ) else {
                throw ConversionError.fileReadError(sourceURL.lastPathComponent)
            }

            await progressHandler(0.35)

            let clampedQuality = min(max(quality, 0.0), 1.0)

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).jpg")

            guard let destination = CGImageDestinationCreateWithURL(
                tempURL as CFURL,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            ) else {
                throw ConversionError.fileWriteError("Failed to create JPEG destination")
            }

            let sourceProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as NSDictionary?
            let destinationProperties = (sourceProperties?.mutableCopy() as? NSMutableDictionary) ?? NSMutableDictionary()
            destinationProperties[kCGImageDestinationLossyCompressionQuality] = clampedQuality

            CGImageDestinationAddImageFromSource(destination, imageSource, 0, destinationProperties as CFDictionary)

            await progressHandler(0.85)

            guard CGImageDestinationFinalize(destination) else {
                try? FileManager.default.removeItem(at: tempURL)
                throw ConversionError.conversionFailed(sourceURL.lastPathComponent)
            }

            let finalDestinationURL: URL
            do {
                finalDestinationURL = try moveConvertedFile(
                    at: tempURL,
                    from: sourceURL,
                    to: destinationURL
                )
            } catch {
                try? FileManager.default.removeItem(at: tempURL)
                throw ConversionError.fileWriteError(error.localizedDescription)
            }

            await progressHandler(1.0)

            return ConversionResult(sourceURL: sourceURL, destinationURL: finalDestinationURL, success: true)
        }
    }

    nonisolated func convertBatch(
        items: [(source: URL, destination: URL)],
        quality: Double,
        progressHandler: @escaping @MainActor @Sendable (Int, Double) -> Void
    ) async -> [ConversionResult] {
        guard !items.isEmpty else { return [] }

        let maxConcurrentConversions = min(Self.recommendedConcurrencyLimit, items.count)
        return await withTaskGroup(of: (Int, ConversionResult).self) { group in
            var results = [ConversionResult?](repeating: nil, count: items.count)
            for itemIndex in 0..<maxConcurrentConversions {
                let item = items[itemIndex]
                group.addTask {
                    let result = await self.convertItem(item, quality: quality) { @MainActor progress in
                        progressHandler(itemIndex, progress)
                    }
                    return (itemIndex, result)
                }
            }
            var nextItemIndex = maxConcurrentConversions

            for await (completedIndex, result) in group {
                results[completedIndex] = result

                if nextItemIndex < items.count {
                    let itemIndex = nextItemIndex
                    nextItemIndex += 1
                    let item = items[itemIndex]
                    group.addTask {
                        let result = await self.convertItem(item, quality: quality) { @MainActor progress in
                            progressHandler(itemIndex, progress)
                        }
                        return (itemIndex, result)
                    }
                }
            }

            return results.enumerated().map { index, result in
                if let result { return result }

                let item = items[index]
                return ConversionResult(
                    sourceURL: item.source,
                    destinationURL: item.destination,
                    success: false,
                    error: .unknownError("Conversion did not produce a result.")
                )
            }
        }
    }

    // MARK: - Private

    private nonisolated func moveConvertedFile(
        at tempURL: URL,
        from sourceURL: URL,
        to preferredDestinationURL: URL
    ) throws -> URL {
        let sourceDirectory = sourceURL.deletingLastPathComponent().standardizedFileURL
        let destinationDirectory = preferredDestinationURL.deletingLastPathComponent().standardizedFileURL

        if sourceDirectory == destinationDirectory {
            return try moveRelatedFile(
                at: tempURL,
                from: sourceURL,
                to: preferredDestinationURL
            )
        }

        let destinationURL = availableDestinationURL(for: preferredDestinationURL)
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        return destinationURL
    }

    private nonisolated func moveRelatedFile(
        at tempURL: URL,
        from sourceURL: URL,
        to preferredDestinationURL: URL
    ) throws -> URL {
        for counter in 1... {
            let candidateURL = destinationURL(
                basedOn: preferredDestinationURL,
                counter: counter
            )
            let presenter = RelatedOutputPresenter(
                sourceURL: sourceURL,
                destinationURL: candidateURL
            )
            let coordinator = NSFileCoordinator(filePresenter: presenter)
            var coordinationError: NSError?
            var writeError: Error?
            var destinationExists = false
            var didMoveFile = false

            NSFileCoordinator.addFilePresenter(presenter)
            coordinator.coordinate(
                writingItemAt: candidateURL,
                options: .forReplacing,
                error: &coordinationError
            ) { coordinatedURL in
                if FileManager.default.fileExists(atPath: coordinatedURL.path) {
                    destinationExists = true
                    return
                }

                do {
                    try FileManager.default.moveItem(at: tempURL, to: coordinatedURL)
                    didMoveFile = true
                } catch {
                    writeError = error
                }
            }
            NSFileCoordinator.removeFilePresenter(presenter)

            if destinationExists {
                continue
            }
            if let writeError {
                throw writeError
            }
            if let coordinationError {
                throw coordinationError
            }
            if didMoveFile {
                return candidateURL
            }

            throw ConversionError.fileWriteError("Could not write the converted image")
        }

        throw ConversionError.fileWriteError("Could not find an available filename")
    }

    private nonisolated func availableDestinationURL(for preferredURL: URL) -> URL {
        for counter in 1... {
            let candidateURL = destinationURL(basedOn: preferredURL, counter: counter)
            if !FileManager.default.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
        }

        return preferredURL
    }

    private nonisolated func destinationURL(basedOn preferredURL: URL, counter: Int) -> URL {
        guard counter > 1 else { return preferredURL }

        let directory = preferredURL.deletingLastPathComponent()
        let filename = preferredURL.deletingPathExtension().lastPathComponent
        let pathExtension = preferredURL.pathExtension
        return directory.appendingPathComponent("\(filename) (\(counter)).\(pathExtension)")
    }

    /// Wraps `convert` to return a `ConversionResult` instead of throwing,
    /// so task group children always produce a value regardless of success or failure.
    private nonisolated func convertItem(
        _ item: (source: URL, destination: URL),
        quality: Double,
        progressHandler: @escaping @MainActor @Sendable (Double) -> Void
    ) async -> ConversionResult {
        do {
            return try await convert(
                sourceURL: item.source,
                destinationURL: item.destination,
                quality: quality,
                progressHandler: progressHandler
            )
        } catch let error as ConversionError {
            return ConversionResult(sourceURL: item.source, destinationURL: item.destination, success: false, error: error)
        } catch {
            return ConversionResult(sourceURL: item.source, destinationURL: item.destination, success: false, error: .unknownError(error.localizedDescription))
        }
    }
}

private final class RelatedOutputPresenter: NSObject, NSFilePresenter, @unchecked Sendable {
    nonisolated let presentedItemURL: URL?
    nonisolated let primaryPresentedItemURL: URL?
    nonisolated let presentedItemOperationQueue: OperationQueue

    nonisolated init(sourceURL: URL, destinationURL: URL) {
        primaryPresentedItemURL = sourceURL
        presentedItemURL = destinationURL
        presentedItemOperationQueue = OperationQueue()
        presentedItemOperationQueue.maxConcurrentOperationCount = 1
        super.init()
    }
}
