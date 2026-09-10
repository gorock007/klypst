import SwiftUI

/// In-app privacy policy. Keep in sync with the public policy URL in App Store Connect.
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Klypst Privacy Policy")
                    .font(.title2.bold())
                Text("Last updated: September 2026")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                section("What Klypst stores", """
                Klypst stores the text, links and images you explicitly save — by tapping Save Clipboard, running a Klypst shortcut, or sharing to Klypst from another app. Nothing is captured without one of these actions. Klypst does not record the app you copied from.
                """)

                section("Where it is stored", """
                Everything stays on this iPhone, in a private container shared only between Klypst and its own extensions so they can show you your clips. Klypst has no server, no account, and no iCloud sync in this version.
                """)

                section("Clipboard access", """
                Klypst reads the system clipboard only when you ask it to. iOS may show its standard paste notice when Klypst reads content that was copied in another app. Klypst never monitors the clipboard in the background.
                """)

                section("Retention and deletion", """
                Unpinned clips are deleted automatically after the period you choose in Settings (default 30 days). You can delete any clip, or every clip, at any time. Deleting removes the database entry and any image files immediately.
                """)

                section("Tracking, analytics and third parties", """
                Klypst contains no advertising, analytics or tracking software, and includes no third-party SDKs. It makes no network requests.
                """)

                section("Your rights", """
                Because your data never leaves your device, you are always in full control of it. Uninstalling Klypst removes all stored clips.
                """)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .brandCanvas()
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(body).font(.body)
        }
        .accessibilityElement(children: .combine)
    }
}
