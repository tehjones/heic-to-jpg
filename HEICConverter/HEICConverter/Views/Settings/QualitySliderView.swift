//
//  QualitySliderView.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import SwiftUI

struct QualitySliderView: View {
    @Binding var quality: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("JPEG quality", systemImage: "slider.horizontal.3")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(quality * 100))%")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }

            Slider(value: $quality, in: 0.6...1.0, step: 0.05)
                .tint(GlassStyle.accentBlue)
                .accessibilityLabel("JPEG quality")
                .accessibilityValue("\(Int(quality * 100)) percent")
        }
    }
}
