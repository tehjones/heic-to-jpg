//
//  NotificationsSection.swift
//  HEICConverter
//
//  Created by Anton Paliakov on 06/03/2026.
//

import SwiftUI

struct NotificationsSection: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showSettingsAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notifications", systemImage: "bell.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Toggle(isOn: Binding(
                get: { viewModel.notifyOnCompletion },
                set: { newValue in
                    if !newValue {
                        viewModel.notifyOnCompletion = false
                        return
                    }
                    Task { @MainActor in
                        viewModel.notifyOnCompletion = true
                        let enabled = await viewModel.enableNotifications()
                        if !enabled {
                            viewModel.notifyOnCompletion = false
                            showSettingsAlert = true
                        }
                    }
                }
            )) {
                Text("Completion alert")
                    .font(.callout.weight(.medium))
            }
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .alert("Notifications are disabled", isPresented: $showSettingsAlert) {
            Button("Open System Settings") {
                viewModel.openNotificationSettings()
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable notifications for HEIC to JPG in System Settings → Notifications.")
        }
    }
}
