//
//  ConversionListView.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import SwiftUI

struct ConversionListView: View {
    var viewModel: ConversionViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.headline)

                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        viewModel.clearItems()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.isConverting)
                }

                ProgressView(value: progress)
                    .tint(GlassStyle.accentBlue)
            }
            .padding(18)

            Divider()

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.conversionItems) { item in
                        ConversionItemRow(item: item)
                    }
                }
                .padding(12)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(GlassStyle.glassBorder, lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var progress: Double {
        guard !viewModel.conversionItems.isEmpty else { return 0 }
        return Double(viewModel.completedCount + viewModel.failedCount)
            / Double(viewModel.conversionItems.count)
    }

    private var title: String {
        if viewModel.isConverting {
            return "Converting photos…"
        }
        if viewModel.failedCount > 0 {
            return "Finished with issues"
        }
        return "Conversion complete"
    }

    private var summary: String {
        let totalCount = viewModel.conversionItems.count
        if viewModel.isConverting {
            let processedCount = viewModel.completedCount + viewModel.failedCount
            return "\(processedCount) of \(totalCount) processed"
        }
        if viewModel.failedCount > 0 {
            return "\(viewModel.completedCount) converted · \(viewModel.failedCount) failed"
        }
        return "\(viewModel.completedCount) of \(totalCount) converted"
    }
}
