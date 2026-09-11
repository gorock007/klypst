# Klypst

A privacy-first iPhone clipboard utility for iOS 26. Capture → remember → summon → select → paste, using only Apple-supported, user-initiated surfaces: the main app, App Intents / App Shortcuts, the Action Button, an iOS 26 interactive snippet, and a Share Extension.

Source documents: `docs/PRD.md` (what), `docs/architecture.md` (how) and `docs/brand.md` (look, feel, voice).

Debug launch arguments: `--reset-state`, `--skip-onboarding`, `--seed-sample-clips`, and `--preview-snippets` (renders the clip cards with sample data for design review). `PickerFlowTests` drives the real card from Spotlight and is opt-in (`TEST_RUNNER_KLYPST_SYSTEM_UI=1`); the iOS 26.5 simulator's Shortcuts backend reports "Couldn't find shortcut" for every App Shortcut, so run it on a device.

Brand in code: color tokens are asset-catalog colorsets (`BrandBackground` (white / near-black), `BrandSurface`, `BrandInk`, … plus the orange `AccentColor`), and `Klypst/App/Brand.swift` holds radii, motion, the mascot view, the card-stack glyph and the primary button style. The mascot (`Mascot` imageset, light/dark) appears only in onboarding, the empty history state and Settings.

## Layout

```
Klypst/                     Main app (SwiftUI, App Intents, snippet)
  App/                      Entry point, AppEnvironment, AppState, RootView, toast
  Features/                 History, Pinned, Settings, Onboarding, Help
  Intents/                  SaveCurrentClipboard, SaveClip (Shortcuts input), ShowRecentClips (+ snippet), CopyClip, PickClip, PickImageClip, ClipEntity, App Shortcuts
  Resources/                Assets, PrivacyInfo.xcprivacy
KlypstShareExtension/       Share Sheet extension (UIKit, no marketing UI)
brand/                      Canonical brand assets (mascot master/flat, app icon masters)
Klypst/Resources/AppIcon.icon  Icon Composer bundle (layered iOS 26 icon; the .appiconset is the flat fallback)
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
- **Capture and retrieval go through Shortcuts.** The recommended Action Button shortcut (published as an iCloud link in `KlypstLinks`) is *Get Clipboard → Pick a Clip (Save First: Clipboard) → Copy to Clipboard*, and the Back Tap shortcut for images is *Get Clipboard → Get Images from Input → Pick an Image Clip (Save First: Images) → Copy to Clipboard*. **Both are deliberately linear:** wiring an empty variable (Get Images from Input over a text clipboard) into a file parameter fails parameter resolution before the picker card can appear, which silently breaks the Action Button (observed on device, 11 Sep 2026). Shortcuts also coerces a copied image into its file name when it lands in a `String` parameter ("Clipboard 11 Sep 2026 at 2.04.png", or "Klypst Clip.png" for an image Klypst wrote). `ShortcutsCoercion.textToSave` refuses to store that, deciding from `UIPasteboard`'s `has*` flags (metadata, no paste notice) rather than the string: an image on the clipboard with no text means any string is an artifact; with both present only a bare image file name is rejected, so real text is never dropped. Shortcuts (privileged) reads and writes the pasteboard; `PickClipIntent` saves, shows the branded Klypst card via `requestConfirmation(snippetIntent:)` (row taps run `SelectPickerClipIntent` and reload the card; the system Copy button returns the selection), and returns text. Its Style parameter can switch to the plain one-tap system list (`requestDisambiguation`). A snippet can't finish on a row tap, which is why the card needs Copy (the confirmation button is relabelled with `ConfirmationActionName.custom`; its color and placement are the system's). `.glassEffect` inside a snippet makes the Shortcuts host render the card blank (verified on device, iOS 26), so the card uses plain fills only. The snippet route (*Save to Klypst → Recent Clips*) remains as an alternative but must open the app to copy (see spike C).
- **Store is shared multi-process state.** SwiftData store and image payloads live in the App Group. The repository actor uses short transactions, refetches before mutations, and treats a unique-constraint failure on save as a duplicate written by another process.
- **Pasteboard writes are local-only and can expire.** `GeneralPasteboardClipboard` writes with `UIPasteboard.OptionsKey.localOnly` (default on, so a clip copied from Klypst is never handed to Universal Clipboard) and an optional `expirationDate`. Both are user settings in `PreferencesStore` (`allowsUniversalClipboard`, `pasteboardExpiry`), surfaced under Settings → Copying from Klypst.
- **Images are a separate surface.** `PickClipIntent` is text and links only in both directions: its confirmation card returns text to Shortcuts, which can't carry an image. `PickImageClipIntent` saves the copied image (Save First) and returns the picked one as an `IntentFile`, so one Back Tap both captures and pastes images, fully in the background. `GetClipImageIntent` exposes the same file for custom shortcuts.
- **Setup is a file, not a recipe.** The app bundles signed `.shortcut` files (see `tools/shortcuts/build.py`); Help and onboarding share them into the Shortcuts app with an "Add the Klypst shortcut" button, with the iCloud link and the manual steps as fallbacks.
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
- [x] D — App Intents extension (device, 11 Sep 2026, inconclusive, removed): an ExtensionKit `com.apple.appintents-extension` target rendered its snippet out of process from a Shortcuts-app shortcut, but `Button(intent:)` rows in that Shortcuts result sheet (the one with a Done button) never dispatched, so whether an extension's pasteboard write survives was never observed. Not pursued; the product flow stays Get Clipboard → Pick a Clip → Copy to Clipboard.
- [ ] Locked device: intents require authentication (`.requiresAuthentication`); confirm nothing is shown on the lock screen.
- [ ] Share Sheet from Safari (URL), Notes (text), Photos (image), Files (file URL image); cancel; large image.
- [ ] Airplane mode and low memory.

## Before App Store submission

- The ready-made shortcuts are signed files in `Klypst/Resources/Shortcuts/`, generated by `python3 tools/shortcuts/build.py` (`shortcuts sign --mode anyone`; the signer requires a `.shortcut` input extension). Rerun it after any recipe change and keep `HelpView.manualRecipeSteps` in step. `KlypstLinks` also keeps iCloud links as a fallback; those are snapshots and must be re-shared after changes.
- Test on iOS 27 (ships 14 Sep 2026; this machine only has the iOS 26.5 SDK): Action Button snippet, Pick a Clip, Pick an Image Clip, Share Extension, and the new keyboard paste button alongside Klypst.
- Host the privacy policy (in-app copy is in `PrivacyPolicyView.swift`) and add the support URL.
- Re-audit `PrivacyInfo.xcprivacy` against the Release archive's privacy report. Currently declares only `UserDefaults` (1C8F.1, App Group suite).
- Run the accessibility pass (VoiceOver, Dynamic Type, Reduce Motion, contrast) and only claim tested Accessibility Nutrition Label features.
- Write App Review notes explaining the user-initiated capture model and how to test each extension.
