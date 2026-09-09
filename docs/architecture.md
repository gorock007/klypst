# Architecture --- iPhone Clipboard Utility

**Status:** Proposed V1 architecture\
**Updated:** 9 September 2026\
**Platform:** iOS 26+\
**Stack:** Swift 6, SwiftUI + UIKit where required\
**Principle:** Native, local-first, extension-safe, user-initiated
clipboard access.

## 1. Architecture goals

-   Main app + Share Extension + App Intents + Action Button + optional
    keyboard.
-   V1 data stays on device.
-   Offline-first.
-   No unsupported clipboard monitoring.
-   Fast extension/intent startup.
-   Safe cross-target data sharing.
-   Migration-ready.
-   Future private iCloud sync without rewriting the domain layer.
-   Clipboard payloads never enter logs/telemetry.

## 2. Recommended stack

-   Swift 6.
-   SwiftUI for app and snippet views.
-   UIKit for `UIPasteboard`, `UIInputViewController`, and
    extension-specific APIs.
-   AppIntents.
-   UniformTypeIdentifiers.
-   Foundation.
-   LocalAuthentication if app lock ships.
-   OSLog with privacy/redaction.
-   App Groups.
-   Share Extension + `NSItemProvider`.
-   SwiftData for metadata.
-   Files in App Group container for image payloads.
-   `UserDefaults(suiteName:)` only for small preferences.
-   No networking dependency in V1.

Apple documents that `ModelContainer` can use custom
`ModelConfiguration`, including custom/shared storage, and App Groups
are designed to share containers between an app and its extensions.

## 3. Target structure

``` text
ClipboardApp.xcodeproj
├── ClipboardApp/
│   ├── App/
│   ├── Features/
│   │   ├── History/
│   │   ├── Search/
│   │   ├── Pinned/
│   │   ├── Settings/
│   │   ├── Onboarding/
│   │   └── Help/
│   └── Resources/
├── ClipboardShareExtension/
├── ClipboardKeyboardExtension/     # only if spike passes
├── ClipboardIntents/
├── SharedCore/
│   ├── Domain/
│   ├── Persistence/
│   ├── Clipboard/
│   ├── Storage/
│   ├── Search/
│   ├── Security/
│   └── Utilities/
└── Tests/
```

Use a small internal Swift package/framework for shared pure logic.

## 4. High-level flow

``` text
                    ┌─────────────────────────┐
                    │ Shared App Group        │
                    │ SwiftData + payloads    │
                    └───────────┬─────────────┘
                                │
          ┌─────────────────────┼────────────────────┐
          ▼                     ▼                    ▼
     Main App              App Intents          Keyboard
          ▲                / Snippets           Extension
          │
     Share Extension
```

All targets use a narrow repository interface rather than duplicating
persistence logic.

## 5. Domain model

Suggested `Clip`: - unique UUID; - kind: text/url/image; -
text/normalized URL; - payload + thumbnail relative paths; - content
hash; - created/last-used timestamps; - expiration; - pinned flag; -
capture method; - byte size; - schema version.

Store binary payloads under:

``` text
<App Group>/
  Database/
  Payloads/<clip-id>/original
  Payloads/<clip-id>/thumbnail
  Temp/
```

Use atomic file writes and cleanup after failed transactions.

## 6. Repository boundary

``` swift
protocol ClipRepository {
    func recent(limit: Int) async throws -> [ClipSummary]
    func search(_ query: String, limit: Int) async throws -> [ClipSummary]
    func clip(id: UUID) async throws -> ClipContent?
    func save(_ input: ClipInput) async throws -> SaveResult
    func markUsed(id: UUID) async throws
    func setPinned(id: UUID, _ pinned: Bool) async throws
    func delete(id: UUID) async throws
    func deleteAll() async throws
    func purgeExpired() async throws
}
```

Extensions fetch lightweight summaries first. Load full image payload
only when required.

## 7. App Group

Create one group such as:

``` text
group.<reverse-dns-bundle>.clipboard
```

Enable only where needed.

Use `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`
for shared files and `UserDefaults(suiteName:)` for small settings.
Never store clip bodies in shared defaults.

## 8. Persistence

Create a single `SharedModelContainerFactory` that resolves the App
Group store location and creates the SwiftData `ModelContainer`.

Treat storage as multi-process shared state: - short transactions; -
atomic file writes; - refetch before sensitive mutations; - unique
constraints/content-hash handling for races; - stress-test Share
Extension + app access.

Keep the repository abstraction so SQLite/Core Data can replace
SwiftData if multi-process extension testing exposes reliability
problems.

## 9. System clipboard service

``` swift
protocol SystemClipboard {
    func readUserInitiatedContent() async throws -> ClipInput?
    func write(_ content: ClipContent) throws
}
```

Rules: - `UIPasteboard.general` reads only on user-initiated paths. - No
polling loop. - No read-on-foreground surveillance. - Use `hasStrings`,
`hasURLs`, `hasImages`, `canLoadObject` and pattern detection
appropriately. - Load only representations required.

Apple currently surfaces privacy notification behavior for cross-app
pasteboard reads without recognized user intent.

## 10. App Intents / Action Button

Initial intents: - `SaveCurrentClipboardIntent` -
`ShowRecentClipsIntent` - `CopyClipIntent` - optional
`SearchClipsIntent`

Expose appropriate intents through `AppShortcutsProvider`. Apple
documents App Shortcuts as available to Shortcuts, Spotlight, Siri, and
the Action Button on supported iPhones.

### iOS 26 interactive snippet

``` text
Action Button
   ↓
ShowRecentClipsIntent
   ↓
fetch 5 lightweight summaries
   ↓
RecentClipsSnippetView
   ├── clip A → CopyClipIntent(A)
   ├── clip B → CopyClipIntent(B)
   ├── clip C → CopyClipIntent(C)
   └── Open App
```

Apple's current documentation allows App Intents to return custom
interactive SwiftUI snippets. It also states Control Center controls
cannot display snippets, so provide fallbacks by invocation context.

### Relevant 2026 App Intents updates

Apple's June 2026 updates include `SyncableEntity`, `EntityCollection`,
`IndexedEntityQuery`, richer union values and improved localized intent
errors.

For V1: - stable clip IDs; - consider `AppEntity` for lightweight clip
summaries if needed; - use localized `AppIntentError`; - do not add
Apple Intelligence schemas without a product need; - revisit
`SyncableEntity` if private cross-device sync ships.

## 11. Share Extension

Flow:

``` text
Host Share Sheet
   ↓
NSItemProvider
   ↓
inspect supported UTTypes
   ↓
load best representation asynchronously
   ↓
normalize / hash
   ↓
ClipRepository.save
   ↓
completeRequest()
```

Narrow activation rules to text, URL, images. Downsample large images.
Do not load every representation. Complete promptly. No
marketing/ads/IAP.

## 12. Keyboard extension

Optional. Implement with `UIInputViewController`.

Core: - recent/pinned text; - next-keyboard/globe control; - tap →
`textDocumentProxy.insertText`.

Requirements: - useful offline; - useful without Full Access; - no
network; - no keystroke logging; - no unrelated launching.

Apple's HIG notes third-party keyboards are unavailable in some
protected fields such as secure text fields and phone-number fields.

**Go/no-go:** test shared-history access with Full Access OFF on
shipping iOS 26. If the desired experience requires Full Access, omit
keyboard from V1 rather than weakening the privacy/review story.

## 13. Search

Local-only, debounced, bounded results. Search normalized text/URL. If
SwiftData becomes slow at large scale, add a local index behind the
repository.

## 14. Retention service

`RetentionService`: - calculate expiry; - purge expired unpinned
clips; - delete associated files; - remove orphans; - optional
storage/count cap.

Run opportunistically on launch/foreground/after saves when cheap. No
perpetual background job.

## 15. Image pipeline

`ImagePayloadStore`: 1. inspect supported payload; 2. enforce maximum
size; 3. downsample thumbnail off main thread; 4. atomically write; 5.
store relative paths; 6. clean failed/orphaned files.

Never log image contents.

## 16. Security

Threats: - sensitive previews; - logs/crash breadcrumbs; - extension
leakage; - orphan files; - keyboard over-permission; - unintended
pasteboard reads; - SDK collection.

Controls: - Apple frameworks only where practical; - redacted OSLog; -
no clip content in logs; - least-privilege entitlements; - local
retention/delete-all; - optional LocalAuthentication; - no third-party
analytics in V1; - privacy review for every dependency.

## 17. Privacy manifests

Maintain `PrivacyInfo.xcprivacy` based on the actual Release binary.

Release procedure: 1. Archive Release. 2. Inspect privacy report. 3.
Inventory required-reason APIs per executable/framework. 4. Check
approved reason codes against current Apple docs. 5. Verify every SDK
manifest/signature if any. 6. Validate in current Xcode/App Store
Connect. 7. Resolve warnings before review.

Do not paste speculative reason codes into the project.

## 18. Logging policy

Allowed: - "Clip save succeeded." - "Unsupported share type." -
"Migration completed."

Forbidden: - actual clip text; - private copied URL; - image content; -
keystrokes; - sensitive filenames.

## 19. Dependency policy

Prefer Apple frameworks only in V1. Before adding a package, review: -
necessity; - maintenance/security; - privacy manifest; - data
collection/network behavior; - binary size; - App Store compatibility.

## 20. Testing

### Unit

Normalization, hashing, dedupe, retention, repository CRUD, migrations,
file cleanup.

### Integration

App Group, shared store, item providers, intent repository access,
clipboard service, concurrent extension/app operations.

### UI

Onboarding, history, search, pin/delete/delete-all, settings.

### Mandatory physical device

-   iOS 26.
-   supported Action Button iPhone.
-   App Shortcut discovery.
-   Action Button invocation.
-   snippet selection/copy.
-   Share Sheet from common Apple apps.
-   keyboard with Full Access OFF if included.
-   lock/unlock.
-   airplane mode.
-   low memory.
-   large images.

## 21. Migration strategy

Version schema from V1. Use SwiftData automatic migrations where safe
and `SchemaMigrationPlan` for larger changes. Never silently destroy
history during a migration.

## 22. Future iCloud

Do not enable in V1.

If validated later: - private CloudKit/iCloud only; - update privacy
policy/App Privacy; - stable IDs; - conflict resolution; -
delete/retention propagation; - offline behavior; - extension behavior
testing.

SwiftData `ModelContainer` can integrate with CloudKit when
appropriately configured, but validate the final shared-extension design
before committing.

## 23. New/current Apple APIs evaluated

### Use

-   `UIPasteboard`
-   App Intents / App Shortcuts
-   `SnippetIntent` / interactive snippets
-   App Groups
-   `NSItemProvider`
-   SwiftData
-   UniformTypeIdentifiers
-   LocalAuthentication if app lock ships

### Evaluate later

-   CloudKit
-   Spotlight/AppEntity indexing
-   2026 App Intents entity improvements
-   Foundation Models

iOS 26 exposes Apple's on-device Foundation Models framework, but V1 has
no justified AI requirement. Do not add AI simply because the API is
available.

## 24. Rejected approaches

-   Continuous background clipboard monitoring.
-   Background audio abuse.
-   PiP used only as keep-alive.
-   Location/background entitlement abuse.
-   Mandatory Full Access keyboard.
-   Remote clipboard processing in V1.

## 25. Technical spike acceptance criteria

### A --- App Group

Main app and Share Extension read/write same store safely.

### B --- Action Button

App Shortcut appears and runs on physical supported iPhone.

### C --- Interactive snippet

Recent summaries display; tapping one invokes `CopyClipIntent`; selected
content reaches `UIPasteboard.general`.

### D --- Keyboard

Keyboard appears where allowed, next-keyboard works, shared clips are
available under permitted sandbox rules, insertion works with Full
Access OFF.

If D fails, remove keyboard from V1.

## 26. Build order

1.  Shared domain.
2.  App Group.
3.  Repository/persistence.
4.  Main history UI.
5.  save/copy.
6.  retention/dedupe.
7.  App Intent spike.
8.  snippet.
9.  Action Button physical test.
10. Share Extension.
11. search/pins/settings.
12. privacy/delete-all.
13. keyboard spike.
14. accessibility.
15. privacy manifests.
16. App Store metadata/review notes.
17. TestFlight.
18. App Review.

## 27. Reviewer architecture statement

> The app does not monitor the clipboard continuously. Clipboard access
> occurs only after user-initiated actions. History is stored locally in
> a shared App Group container so the containing app and its extensions
> can provide requested functionality. V1 has no account, advertising,
> analytics SDK, tracking, or developer backend. The keyboard, if
> included, provides actual text input, operates offline, and does not
> require Full Access.

The shipping binary must keep this statement true.

## 28. Apple source-of-truth documentation

-   iOS 26 Release Notes:
    https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26-release-notes
-   App Intents updates:
    https://developer.apple.com/documentation/Updates/AppIntents
-   Interactive snippets:
    https://developer.apple.com/documentation/appintents/displaying-static-and-interactive-snippets
-   SnippetIntent:
    https://developer.apple.com/documentation/appintents/snippetintent
-   App Shortcuts:
    https://developer.apple.com/documentation/appintents/app-shortcuts
-   Hardware interactions:
    https://developer.apple.com/documentation/appintents/hardware-interactions
-   Action Button HIG:
    https://developer.apple.com/design/human-interface-guidelines/action-button
-   UIPasteboard:
    https://developer.apple.com/documentation/uikit/uipasteboard
-   App Groups:
    https://developer.apple.com/documentation/xcode/configuring-app-groups
-   SwiftData ModelContainer:
    https://developer.apple.com/documentation/swiftdata/modelcontainer
-   Custom keyboard:
    https://developer.apple.com/documentation/uikit/creating-a-custom-keyboard
-   Keyboard open access:
    https://developer.apple.com/documentation/uikit/configuring-open-access-for-a-custom-keyboard
-   Virtual keyboard HIG:
    https://developer.apple.com/design/human-interface-guidelines/virtual-keyboards
-   LocalAuthentication:
    https://developer.apple.com/documentation/localauthentication/logging-a-user-into-your-app-with-face-id-or-touch-id
-   Privacy manifests:
    https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
-   Required-reason APIs:
    https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
-   App Review Guidelines:
    https://developer.apple.com/app-store/review/guidelines/
-   App Privacy:
    https://developer.apple.com/app-store/app-privacy-details/
-   CloudKit: https://developer.apple.com/documentation/cloudkit
