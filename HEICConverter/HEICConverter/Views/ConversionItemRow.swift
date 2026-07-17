//
//  ConversionItemRow.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import SwiftUI

struct ConversionItemRow: View {
    let item: ConversionItem

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.sourceURL.lastPathComponent)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)

                if let relativePath = item.relativePath, !relativePath.isEmpty {
                    Text(relativePath)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let error = item.error {
                    Text(error.localizedDescription)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(statusText)
                .font(.caption.weight(.medium))
                .foregroundStyle(statusColor)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(rowBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(rowBorder, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.state {
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)

        case .converting:
            ProgressView()
                .controlSize(.small)

        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    private var statusText: String {
        switch item.state {
        case .pending:
            return "Waiting"
        case .converting:
            return "\(Int(item.progress * 100))%"
        case .completed:
            return "Done"
        case .failed:
            return "Failed"
        }
    }

    private var statusColor: Color {
        switch item.state {
        case .completed:
            return .green
        case .failed:
            return .red
        default:
            return .secondary
        }
    }

    private var rowBackground: Color {
        switch item.state {
        case .completed:
            return .green.opacity(0.06)
        case .failed:
            return .red.opacity(0.07)
        default:
            return Color.primary.opacity(0.035)
        }
    }

    private var rowBorder: Color {
        switch item.state {
        case .failed:
            return .red.opacity(0.20)
        default:
            return Color.primary.opacity(0.06)
        }
    }
}
