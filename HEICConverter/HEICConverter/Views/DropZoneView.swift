//
//  DropZoneView.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Binding var isTargeted: Bool
    let outputFolder: URL?
    let onSelectInput: () -> Void
    let onDrop: ([NSItemProvider]) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Button(action: onSelectInput) {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(GlassStyle.accentBlue.opacity(isTargeted ? 0.18 : 0.10))
                        .frame(width: 84, height: 84)

                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(GlassStyle.accentGradient)
                        .scaleEffect(isTargeted ? 1.06 : 1.0)
                }

                VStack(spacing: 8) {
                    Text(isTargeted ? "Drop to convert" : "Choose or drop HEIC photos")
                        .font(.title2.weight(.semibold))

                    Text(instructionText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Label("Ready — conversion starts automatically", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

                ZStack {
                    if reduceTransparency {
                        shape.fill(GlassStyle.reducedTransparencyFill)
                    } else {
                        shape.fill(.thinMaterial)
                    }

                    if isTargeted {
                        shape.fill(GlassStyle.accentBlue.opacity(0.10))
                    }

                    shape
                        .strokeBorder(
                            style: StrokeStyle(
                                lineWidth: isTargeted ? 2 : 1.5,
                                lineCap: .round,
                                dash: [8, 6]
                            )
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: isTargeted ? [
                                    GlassStyle.accentBlue,
                                    GlassStyle.accentPurple
                                ] : [
                                    GlassStyle.glassBorder,
                                    GlassStyle.glassBorder.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(DropZoneButtonStyle())
        .scaleEffect(isTargeted ? 1.005 : 1.0)
        .animation(
            reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 1.0),
            value: isTargeted
        )
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            onDrop(providers)
            return true
        }
        .accessibilityHint("Opens a file picker. You can also drag HEIC files or folders here.")
        .help("Click to choose HEIC photos or folders")
    }

    private var instructionText: String {
        if let outputFolder {
            return "JPEGs will be saved to \(outputFolder.lastPathComponent)."
        }
        return "Each JPEG will be saved beside its original."
    }
}

private struct DropZoneButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? 0.997 : 1.0))
    }
}
