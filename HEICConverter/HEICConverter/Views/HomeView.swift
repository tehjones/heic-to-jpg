//
//  HomeView.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import SwiftUI

struct HomeView: View {
    @State private var conversionViewModel = ConversionViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var isDropTargeted = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            if !reduceTransparency {
                RadialGradient(
                    colors: [
                        GlassStyle.accentBlue.opacity(0.10),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 520
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack(spacing: 20) {
                SettingsPanel(viewModel: settingsViewModel)

                if conversionViewModel.conversionItems.isEmpty {
                    DropZoneView(
                        isTargeted: $isDropTargeted,
                        outputFolder: settingsViewModel.outputFolder,
                        onSelectInput: selectInputFiles,
                        onDrop: { providers in
                            Task {
                                await conversionViewModel.handleDrop(
                                    providers: providers,
                                    settings: settingsViewModel.settings
                                )
                            }
                        }
                    )
                } else {
                    ConversionListView(viewModel: conversionViewModel)
                }

                FooterView()
            }
            .padding(24)
        }
        .alert("Error", isPresented: $conversionViewModel.showError) {
            Button("OK") {
                conversionViewModel.showError = false
            }
        } message: {
            if let errorMessage = conversionViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func selectInputFiles() {
        Task {
            await conversionViewModel.selectInputFiles(
                settings: settingsViewModel.settings
            )
        }
    }
}

#Preview {
    HomeView()
}
