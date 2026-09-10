# Klypst

A privacy-first iPhone clipboard utility for iOS 26. Capture → remember → summon → select → paste, using only Apple-supported, user-initiated surfaces: the main app, App Intents / App Shortcuts, the Action Button, an iOS 26 interactive snippet, and a Share Extension.

Source documents: `docs/PRD.md` and `docs/architecture.md`.

## Layout

```
Klypst/                     Main app (SwiftUI, App Intents, snippet)
  App/                      Entry point, AppEnvironment, AppState, RootView, toast
  Features/                 History, Pinned, Settings, Onboarding, Help
  Intents/                  SaveCurrentClipboard, SaveClip (Shortcuts input), ShowRecentClips (+ snippet), CopyClip, ClipEntity, App Shortcuts
  Resources/                Assets, PrivacyInfo.xcprivacy
KlypstShareExtension/       Share Sheet extension (UIKit, no marketing UI)
KlypstCore/                 Swift package shared by every target
  Domain/                   ClipKind, ClipSummary/ClipContent/ClipInput, ClipRepository, SystemClipboard, RetentionPolicy
  Persistence/              SwiftData versioned schema, SharedModelContainerFactory, SwiftDataClipRepository, KlypstStore
  Storage/                  AppGroupPaths, ImagePayloadStore (ImageIO), PreferencesStore
  Clipboard/                GeneralPasteboardClipboard (UIPasteboard adapter)
  Search/ Security/         ContentNormalizer, ContentHasher (SHA-256)
  Retention/                RetentionService (opportunistic purge)
KlypstUITests/              XCUITest smoke tests (save → list → copy)
project.yml                 xcodegen spec (the .xcodeproj is generated, not committed)
```

## Building

Requires Xcode 26.6+ (iOS 26.5 SDK) and [xcodegen](https://github.com/yonaskolb/XcodeGen).

```sh
xcodegen generate
open Klypst.xcodeproj
```

Command line (the machine's active developer dir may be Command Line Tools, so point at Xcode explicitly):

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
# Core package unit tests (run natively on macOS, fast)
(cd KlypstCore && swift test)
# App + extension + UI tests on the simulator
xcodebuild -project Klypst.xcodeproj -scheme Klypst \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' test
```

Identifiers (change in `project.yml` and `KlypstConfiguration.swift` together):

| Thing | Value |
| --- | --- |
| App bundle ID | `com.klypst.app` |
| Share Extension | `com.klypst.app.share` |
| App Group | `group.com.klypst.shared` |
| Team | `9PXJ82UU32` |

## Key decisions

- **No clipboard monitoring.** `UIPasteboard.general` is read only in `GeneralPasteboardClipboard.readUserInitiatedContent()`, called from the Save Clipboard control, the nudge card, and the foreground `SaveCurrentClipboardIntent`. The nudge card is driven by `changeCount` and the `has*` flags only, which never trigger the paste notice.
- **Capture and retrieval go through Shortcuts.** The recommended Action Button shortcut is *Get Clipboard → Pick a Clip (Save First: Clipboard) → Copy to Clipboard*. Shortcuts (privileged) reads and writes the pasteboard; `PickClipIntent` saves, shows a system picker via `requestDisambiguation`, and returns text. The snippet route (*Save to Klypst → Recent Clips*) remains as an alternative but must open the app to copy (see spike C).
- **Store is shared multi-process state.** SwiftData store and image payloads live in the App Group. The repository actor uses short transactions, refetches before mutations, and treats a unique-constraint failure on save as a duplicate written by another process.
- **Dedupe by content hash.** SHA-256 over kind-prefixed normalized content. A duplicate save refreshes `lastUsedAt` and moves the clip to the top.
- **Retention is "days since last used".** Default 30 days; pinned clips never expire; purge runs on foreground, after settings changes, and is throttled to once per 10 minutes.
- **Images are files, not blobs.** Original (downsampled to ≤4096 px if larger) and a ≤320 px JPEG thumbnail under `Payloads/<clip-id>/`. Orphan directories are swept during purge.
- **Intents run in the app process.** Simpler than an App Intents extension for V1; revisit if Action Button latency is a problem on device.
- **Keyboard extension is not included.** Per PRD, it ships only if the Full-Access-OFF spike passes on hardware.
- **Logging never includes clip bodies.** Only counts, kinds and fixed strings are marked `.public`.

## Physical-device spike checklist (must pass before wider build-out)

- [ ] A — App Group: save from the Share Extension, see it in the app; save in app, see it via Shortcuts.
- [x] B — Action Button (verified on device 10 Sep 2026): assign "Show Recent Clips" in Settings → Action Button; it runs without launching the app.
- [x] C — Interactive snippet (device, 10 Sep 2026): recent summaries display and tapping one runs `CopyClipIntent`. **Finding:** iOS discards `UIPasteboard` writes from the backgrounded app process (the first test passed only because the tapped clip was already on the clipboard). `changeCount` still advances locally, so it cannot detect the drop. `CopyClipIntent` now continues in the foreground (`.foreground(.dynamic)`) whenever `UIApplication.shared.applicationState != .active`, then writes. A fully background-safe alternative exists through Shortcuts: `Get Recent Clips → Choose from List → Get Clip Text → Copy to Clipboard`.
- [ ] Locked device: intents require authentication (`.requiresAuthentication`); confirm nothing is shown on the lock screen.
- [ ] Share Sheet from Safari (URL), Notes (text), Photos (image), Files (file URL image); cancel; large image.
- [ ] Airplane mode and low memory.

## Before App Store submission

- Replace the empty `AppIcon` asset.
- Host the privacy policy (in-app copy is in `PrivacyPolicyView.swift`) and add the support URL.
- Re-audit `PrivacyInfo.xcprivacy` against the Release archive's privacy report. Currently declares only `UserDefaults` (1C8F.1, App Group suite).
- Run the accessibility pass (VoiceOver, Dynamic Type, Reduce Motion, contrast) and only claim tested Accessibility Nutrition Label features.
- Write App Review notes explaining the user-initiated capture model and how to test each extension.
