import AppIntents
import Foundation

/// Localized, user-facing intent failures. Never includes clip content.
enum KlypstIntentError: Error, CustomLocalizedStringResourceConvertible {
    case storeUnavailable
    case clipNotFound
    case copyFailed
    case nothingToSave
    case saveRejected(String)
    case imageNotText

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .storeUnavailable: "Klypst couldn’t open its storage. Open the app and try again."
        case .clipNotFound: "That clip is no longer in Klypst."
        case .copyFailed: "Klypst couldn’t copy that clip."
        case .nothingToSave: "There’s nothing on the clipboard to save."
        case .saveRejected(let message): "\(message)"
        case .imageNotText: "That clip is an image, so it can’t be returned as text. Copy it from the Klypst app instead."
        }
    }
}
