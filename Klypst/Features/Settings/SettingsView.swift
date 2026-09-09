import KlypstCore
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var state
    @State private var retention = AppEnvironment.shared.preferences.retentionPolicy
    @State private var clipCount: Int?
    @State private var showDeleteAllConfirmation = false
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Keep unpinned clips for", selection: $retention) {
                        ForEach(RetentionPolicy.allCases) { policy in
                            Text(policy.displayName).tag(policy)
                        }
                    }
                    .onChange(of: retention) { _, newValue in
                        AppEnvironment.shared.preferences.retentionPolicy = newValue
                        Task { await AppEnvironment.shared.runRetention(force: true) }
                    }
                } header: {
                    Text("Retention")
                } footer: {
                    Text("Unpinned clips are deleted after they haven’t been used for this long. Pinned clips never expire. Cleanup runs when you open Klypst.")
                }

                Section {
                    NavigationLink { HelpView() } label: {
                        Label("Help & Setup", systemImage: "questionmark.circle")
                    }
                    Button {
                        showOnboarding = true
                    } label: {
                        Label("Show Welcome Again", systemImage: "hand.wave")
                    }
                } header: {
                    Text("Get the most out of Klypst")
                }

                Section {
                    NavigationLink { PrivacyPolicyView() } label: {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    LabeledContent("Data storage", value: "On this device only")
                    if let clipCount {
                        LabeledContent("Stored clips", value: clipCount.formatted())
                    }
                    Button(role: .destructive) {
                        showDeleteAllConfirmation = true
                    } label: {
                        Label("Delete All Clips…", systemImage: "trash")
                    }
                    .disabled(clipCount == 0)
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Deleting removes every clip and image file from this device immediately.")
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.versionString)
                    LabeledContent("Account", value: "None required")
                    LabeledContent("Analytics", value: "None")
                }
            }
            .navigationTitle("Settings")
            .task(id: state.changeToken) {
                clipCount = try? await AppEnvironment.shared.repository?.count()
            }
            .confirmationDialog("Delete all clips?", isPresented: $showDeleteAllConfirmation, titleVisibility: .visible) {
                Button("Delete All Clips", role: .destructive) {
                    Task {
                        do {
                            try await AppEnvironment.shared.deleteAll()
                            state.showToast("All clips deleted")
                        } catch {
                            state.showToast("Couldn’t delete clips", isSuccess: false)
                        }
                    }
                }
            } message: {
                Text("This permanently removes every clip, including pinned ones, from this device.")
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView { showOnboarding = false }
            }
        }
    }
}

extension Bundle {
    var versionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}
