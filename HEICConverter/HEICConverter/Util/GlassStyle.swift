//
//  GlassStyle.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import AppKit
import SwiftUI

enum GlassStyle {
    static let darkBackground = Color(nsColor: .windowBackgroundColor)

    static let glassBorder = Color.primary.opacity(0.14)

    static let accentBlue = Color(red: 0.4, green: 0.6, blue: 1.0)
    static let accentPurple = Color(red: 0.6, green: 0.4, blue: 1.0)

    static let accentGradient = LinearGradient(
        colors: [accentBlue, accentPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let reducedTransparencyFill = Color(nsColor: .controlBackgroundColor)
}
