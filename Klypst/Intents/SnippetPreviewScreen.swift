#if DEBUG
import KlypstCore
import SwiftUI
import UIKit

/// Debug-only gallery of the clip cards with sample data, for design review and
/// screenshots. Launch with `--preview-snippets`.
struct SnippetPreviewScreen: View {
    static var isRequested: Bool { CommandLine.arguments.contains("--preview-snippets") }

    private let samples = SnippetSamples.make()

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                platter {
                    ClipPickerCardView(clips: samples.picker, selectedID: samples.picker[0].id)
                }
                platter {
                    RecentClipsSnippetView(clips: samples.recent, copiedID: samples.recent[1].id)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 24)
        }
        .background {
            LinearGradient(colors: [Color(white: 0.25), Color(white: 0.12)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
    }

    /// Approximates the system's snippet platter.
    private func platter<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 24, y: 10)
    }
}

enum SnippetSamples {
    static func make() -> (picker: [ClipEntity], recent: [ClipEntity]) {
        let now = Date()
        func clip(_ kind: ClipKind, _ preview: String, minutesAgo: Double, pinned: Bool = false, thumbnail: URL? = nil) -> ClipEntity {
            let date = now.addingTimeInterval(-minutesAgo * 60)
            return ClipEntity(summary: ClipSummary(
                id: UUID(), kind: kind, preview: preview, createdAt: date, lastUsedAt: date,
                isPinned: pinned, byteSize: 64, thumbnailURL: thumbnail
            ))
        }
        let picker = [
            clip(.url, "https://naatiace.com/", minutesAgo: 0),
            clip(.text, "Meeting notes about Q3 planning and hiring", minutesAgo: 4),
            clip(.url, "https://gorock.sh/writings/clipboard-memory", minutesAgo: 60),
            clip(.text, "npm install klypst", minutesAgo: 180),
            clip(.text, "42 Wallaby Way, Sydney NSW 2000", minutesAgo: 1440, pinned: true),
        ]
        let recent = [
            picker[0],
            picker[1],
            clip(.image, "IMG_8421.PNG", minutesAgo: 12, thumbnail: sampleThumbnail()),
            picker[2],
            picker[3],
        ]
        return (picker, recent)
    }

    /// A small mountain-and-sky image written to tmp, standing in for a saved photo.
    private static func sampleThumbnail() -> URL? {
        let url = FileManager.default.temporaryDirectory.appending(path: "klypst-sample-thumb.png")
        let size = CGSize(width: 150, height: 150)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            let sky = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
                UIColor(red: 0.33, green: 0.62, blue: 0.93, alpha: 1).cgColor,
                UIColor(red: 0.78, green: 0.9, blue: 0.98, alpha: 1).cgColor,
            ] as CFArray, locations: [0, 1])!
            cg.drawLinearGradient(sky, start: .zero, end: CGPoint(x: 0, y: 110), options: [])
            UIColor(red: 0.45, green: 0.47, blue: 0.55, alpha: 1).setFill()
            let mountain = UIBezierPath()
            mountain.move(to: CGPoint(x: 0, y: 115)); mountain.addLine(to: CGPoint(x: 75, y: 35)); mountain.addLine(to: CGPoint(x: 150, y: 115)); mountain.close()
            mountain.fill()
            UIColor.white.setFill()
            let snow = UIBezierPath()
            snow.move(to: CGPoint(x: 60, y: 51)); snow.addLine(to: CGPoint(x: 75, y: 35)); snow.addLine(to: CGPoint(x: 90, y: 51)); snow.close()
            snow.fill()
            UIColor(red: 0.3, green: 0.6, blue: 0.3, alpha: 1).setFill()
            cg.fill(CGRect(x: 0, y: 110, width: 150, height: 40))
        }
        try? image.pngData()?.write(to: url)
        return url
    }
}

#Preview("Clip cards") {
    SnippetPreviewScreen()
}
#endif
