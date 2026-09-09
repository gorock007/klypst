# PRD --- iPhone Clipboard Utility

**Status:** V1 implementation draft\
**Updated:** 9 September 2026\
**Target:** iPhone / iOS 26+\
**V1 price:** Free\
**Principle:** The fastest privacy-first way to save, find, and reuse
clipboard content on iPhone.

## 1. Product vision

Build a native iPhone utility for one high-frequency job:

> I copied or saved something before. Let me get it back immediately.

The end-state experience is **capture → remember → summon → select →
paste**.

The product must not pretend iOS supports unrestricted desktop-style
clipboard surveillance. V1 uses Apple-supported, user-initiated
surfaces: App Intents/App Shortcuts, Action Button, iOS 26 interactive
snippets, Share Extension, main app, and---only if it passes a
compliance/permission spike---an optional custom keyboard.

## 2. Problem

Existing iOS clipboard tools commonly require too many steps, rely on
confusing keep-alive workarounds, request broad keyboard permissions,
add accounts/cloud services to a sensitive data category, or become
feature-heavy libraries. We optimize for **time from "I need that
previous thing" to "it is ready to paste."**

## 3. V1 goals

V1 is free to maximize distribution and validate the interaction.

### Must ship

-   Native Swift/SwiftUI app.
-   Local-only clip history.
-   Text, URL, and image clips.
-   Recent history.
-   Local search.
-   Pin/unpin.
-   Delete one / delete all.
-   Configurable retention.
-   Deduplication.
-   Explicit Save Current Clipboard action.
-   Copy any stored clip back to `UIPasteboard.general`.
-   App Intents + App Shortcuts.
-   Action Button compatibility on supported iPhones.
-   iOS 26 interactive snippet where supported.
-   Share Extension.
-   Clear onboarding and setup/help.
-   Privacy policy in app and App Store metadata.
-   Accessibility.
-   Detailed App Review notes.
-   No login, backend, ads, tracking, third-party analytics, AI,
    subscription, or IAP.

### Keyboard

A clipboard keyboard is a V1 candidate, not a hard dependency. Ship it
only if the physical-device spike proves it provides useful text-input
functionality, works offline, and remains useful without Full Access,
consistent with App Review Guideline 4.4.1.

### Explicitly out of scope

-   Hidden continuous cross-app clipboard monitoring.
-   PiP/audio/location/background-mode keep-alive tricks.
-   "Records everything you copy" claims.
-   Accounts/cloud sync.
-   AI/OCR.
-   Collaboration.
-   Folders/tags beyond pinning.
-   Monetization.

## 4. Core user stories

### Capture

-   Save the current clipboard after an explicit action.
-   Share text, URLs, or images into the app from another app.
-   Know exactly when clipboard content is being read.

### Retrieve

-   Trigger a clipboard shortcut from the Action Button.
-   See a small recent/pinned set through a system snippet when
    supported.
-   Choose an item and make it the current clipboard.
-   Use the main app as the universal fallback.
-   If the keyboard ships, insert saved text directly into an active
    text field.

### Manage

-   Search.
-   Pin.
-   Delete.
-   Delete everything.
-   Choose retention.

### Trust

-   V1 data stays on device.
-   No account.
-   No tracking.
-   No unrelated permissions.

## 5. Core flows

### First launch

1.  Explain value.
2.  State that V1 clip data stays on device.
3.  Explain honestly that iOS does not allow this app to silently record
    every copy across every app.
4.  Demonstrate supported capture/retrieval.
5.  Offer Action Button setup on supported devices.
6.  Explain Share Extension.
7.  Treat keyboard setup as optional.
8.  Open history.

Do not front-load unrelated permission prompts.

### Save current clipboard

1.  User invokes Save Current Clipboard.
2.  Read only required pasteboard representation.
3.  Normalize.
4.  Hash/deduplicate.
5.  Persist locally.
6.  Return lightweight success feedback.

### Action Button retrieval

1.  User assigns the App Shortcut in system settings.
2.  Press Action Button.
3.  `ShowRecentClipsIntent` runs.
4.  On supported iOS 26 invocation contexts, return an interactive
    snippet with a small recent/pinned set.
5.  Selection invokes `CopyClipIntent`.
6.  Selected clip is written to general pasteboard.
7.  User pastes in the original app.

Apple currently documents that Control Center controls cannot display
snippets, so never promise identical behavior from every invocation
surface.

### Share Extension

1.  Share from host app.
2.  Extension receives `NSItemProvider`.
3.  Load only the best supported representation.
4.  Normalize/store in App Group.
5.  Complete promptly.
6.  No ads, marketing, or purchases inside extension.

### Keyboard, if shipped

-   Real text-input functionality.
-   Visible next-keyboard/globe control.
-   Recent/pinned text.
-   `textDocumentProxy.insertText`.
-   Useful offline.
-   Useful without Full Access.
-   No keystroke logging/network transmission.
-   Explain that third-party keyboards are unavailable in some protected
    fields.

## 6. Data model

Each clip: - UUID. - kind: text / URL / image. - normalized text or
URL. - image payload path + thumbnail path. - content hash. - created
timestamp. - last-used timestamp. - capture method. - pinned flag. -
expiration. - byte size. - schema version.

Store image binaries as files, not large database blobs.

Do not retain source-app identity unless a later feature genuinely needs
it and privacy/review implications are re-evaluated.

## 7. Retention and deduplication

Default proposal: 30 days for ordinary clips; pinned clips do not
auto-expire. Options: 1/7/30/90 days/never. User can erase everything
immediately.

Identical clips should update recency rather than create uncontrolled
duplicates.

## 8. Privacy and security

Clipboard data can contain credentials, OTPs, private messages,
addresses, financial or work data. Treat every clip as sensitive.

V1: - local processing only; - no developer server; - no analytics/ad
SDK; - no tracking; - no remote clip hashes; - no keystroke
collection; - no network dependency for core features; - no Full Access
requirement; - user-controlled retention/deletion; - never expose
clipboard contents in notifications; - never log clip bodies.

Apple states that iOS notifies users when an app reads general
pasteboard content from another app without recognized user intent. Read
`UIPasteboard.general` only on explicit user-initiated paths. Use
pattern-detection APIs where only a pattern is needed.

Optional app lock can use LocalAuthentication. If Face ID is used, add a
clear `NSFaceIDUsageDescription` and support appropriate
device-owner/passcode fallback behavior.

## 9. Accessibility

Treat accessibility as a release requirement. iOS 26 App Store pages can
show Accessibility Nutrition Labels.

Test: - VoiceOver. - Dynamic Type. - contrast. - Reduce Motion. - Reduce
Transparency where relevant. - non-color-only states. - touch targets. -
logical focus order. - large-text layouts. - accessible custom controls.

Only claim Accessibility Nutrition Label features actually tested.

## 10. Apple App Review compliance

### Completeness

-   No placeholders/dead controls/crashes.
-   Privacy/support URLs live.
-   All extensions testable.
-   Reviewer notes explain non-obvious features.
-   Test on physical supported iPhone.
-   Containing app has meaningful
    history/search/pin/delete/settings/help functionality.

### Extensions --- Guideline 4.4

-   Follow App Extension rules.
-   Clearly disclose extensions in marketing.
-   No marketing, advertising, or IAP inside extensions.

### Keyboard --- Guideline 4.4.1

Must: - provide keyboard input; - provide next-keyboard method; - remain
functional without network; - remain functional without Full Access; -
collect activity only for keyboard functionality.

Must not: - launch arbitrary apps; - repurpose normal keyboard controls
for unrelated actions; - transmit/store keystrokes for unrelated
purposes.

If this cannot be met, exclude keyboard from V1.

### Privacy --- Guideline 5.1

Before submission: - Public privacy policy. - Link in App Store Connect
and in app. - Explain data processed/stored, purposes,
retention/deletion. - State V1 clip data stays on device. - Accurate App
Privacy Nutrition Label. - Audit every dependency.

Apple's App Privacy guidance says data processed only on device is
generally not "collected" for the label's definition; still disclose
local behavior clearly in the privacy policy.

### Privacy manifest

Maintain valid `PrivacyInfo.xcprivacy` files where required. Audit the
app, extensions, internal frameworks and any SDK. Declare only
required-reason APIs actually used, using Apple's current approved
reasons. Validate the Release archive with current Xcode/App Store
tooling. Apple can reject invalid manifests.

### Permissions

Avoid permissions unless feature-essential: - Photos: avoid if Share
Extension/item providers suffice. - Camera: no. - Microphone: no. -
Contacts: no. - Location: no. - Notifications: no. - ATT: no. - Face ID:
only if app lock ships.

Every usage description must explain the specific benefit.

### Accounts/payments

V1 has no account and no payment. If either is added later, re-review
then-current sign-in, account deletion, Sign in with Apple, and payment
rules before implementation.

### Metadata

Never claim "automatic systemwide monitoring," "records everything you
copy," or "runs continuously in background." Describe actual
user-initiated behavior.

## 11. App Store release checklist

### Product

-   [ ] Offline core works
-   [ ] History/search/pin/delete/delete-all work
-   [ ] Retention and dedupe work
-   [ ] Unsupported content handled
-   [ ] Empty/error states complete

### Action Button / intents

-   [ ] App Shortcut discoverable
-   [ ] Physical Action Button test
-   [ ] Snippet tested from supported surface
-   [ ] Control Center limitation handled
-   [ ] Locked-device/privacy behavior tested
-   [ ] Intent errors localized

### Share Extension

-   [ ] Text/URL/image tested
-   [ ] Unsupported payload/cancel tested
-   [ ] Large-image/memory test
-   [ ] Shared-store concurrency test
-   [ ] No marketing/IAP

### Keyboard if included

-   [ ] Inserts text
-   [ ] Next-keyboard control
-   [ ] Full Access OFF test
-   [ ] Offline test
-   [ ] Secure-field behavior documented
-   [ ] No network/keystroke logging
-   [ ] Guideline 4.4.1 audit passed

### Privacy

-   [ ] Privacy policy live/in-app
-   [ ] App Privacy answers accurate
-   [ ] `PrivacyInfo.xcprivacy` valid
-   [ ] Required-reason APIs audited
-   [ ] Dependencies audited
-   [ ] Delete-all removes DB + files

### Accessibility

-   [ ] VoiceOver
-   [ ] Dynamic Type
-   [ ] Contrast
-   [ ] Reduce Motion
-   [ ] Touch targets
-   [ ] Accessibility label answers verified

### App Store Connect

-   [ ] Accurate name/subtitle/description/screenshots
-   [ ] Support URL
-   [ ] Privacy URL
-   [ ] Age rating
-   [ ] Copyright
-   [ ] Export compliance answered
-   [ ] Detailed review notes
-   [ ] Current SDK/submission requirements rechecked on submission day

## 12. Technical spike before full build

Prove on physical iOS 26 hardware: 1. Main app + Share Extension safely
share App Group storage. 2. App Shortcut appears for Action Button. 3.
Action Button runs intent without unnecessary app launch. 4. Interactive
snippet can display recent clip summaries in intended context. 5.
Selecting a snippet action can copy a chosen clip. 6. Keyboard can
read/use required shared data and insert text with Full Access OFF.

If #6 fails, ship V1 without the keyboard.

## 13. Roadmap

### Phase 1 --- free V1

Everything above.

### Phase 2 --- only after demand

-   Private iCloud/CloudKit sync.
-   App lock.
-   Richer filters/image handling.
-   Additional native system integrations.
-   macOS companion.
-   Potential one-time Pro tier.

### End state

A polished Apple-platform clipboard utility with the fastest
user-initiated retrieval path, private sync, strong search, and native
system integrations.

## 14. Non-negotiable constraints

1.  No hidden continuous cross-app clipboard surveillance.
2.  No background-mode/PiP/audio/location abuse.
3.  No Full Access dependency for a shipped keyboard.
4.  No V1 remote clipboard/keyboard processing.
5.  No misleading Action Button/snippet claims.
6.  No sensitive lock-screen exposure by default.
7.  No SDK without privacy/data-flow review.
8.  No competitor branding/trade-dress copying.

## 15. Apple source-of-truth documentation

-   App Review Guidelines:
    https://developer.apple.com/app-store/review/guidelines/
-   App Privacy:
    https://developer.apple.com/app-store/app-privacy-details/
-   UIPasteboard:
    https://developer.apple.com/documentation/uikit/uipasteboard
-   App Shortcuts:
    https://developer.apple.com/documentation/appintents/app-shortcuts
-   Hardware interactions:
    https://developer.apple.com/documentation/appintents/hardware-interactions
-   Action Button HIG:
    https://developer.apple.com/design/human-interface-guidelines/action-button
-   Interactive snippets:
    https://developer.apple.com/documentation/appintents/displaying-static-and-interactive-snippets
-   SnippetIntent:
    https://developer.apple.com/documentation/appintents/snippetintent
-   Custom keyboard:
    https://developer.apple.com/documentation/uikit/creating-a-custom-keyboard
-   Keyboard open access:
    https://developer.apple.com/documentation/uikit/configuring-open-access-for-a-custom-keyboard
-   Virtual keyboard HIG:
    https://developer.apple.com/design/human-interface-guidelines/virtual-keyboards
-   App Groups:
    https://developer.apple.com/documentation/xcode/configuring-app-groups
-   Privacy manifests:
    https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
-   Required-reason APIs:
    https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
-   iOS 26 Release Notes:
    https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-26-release-notes
