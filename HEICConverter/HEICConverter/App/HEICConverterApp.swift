//
//  HEICConverterApp.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import SwiftUI

@main
struct HEICConverterApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .frame(minWidth: 760, minHeight: 580)
        }
        .defaultSize(width: 800, height: 660)
        .windowToolbarLabelStyle(fixed: .titleOnly)
        .windowResizability(.contentMinSize)
    }
}
