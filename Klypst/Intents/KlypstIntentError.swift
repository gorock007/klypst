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
    case noClips
    case noImageClips
    case notAnImage

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .storeUnavailable: "Klypst couldn’t open its storage. Open the app and try again."
        case .clipNotFound: "That clip is no longer in Klypst."
        case .copyFailed: "Klypst couldn’t copy that clip."
        case .nothingToSave: "There’s nothing on the clipboard to save."
        case .saveRejected(let message): "\(message)"
        case .imageNotText: "That clip is an image, so it can’t be returned as text. Use Pick an Image Clip or Get Clip Image instead."
        case .noClips: "There are no text or link clips in Klypst yet."
        case .noImageClips: "There are no image clips in Klypst yet."
        case .notAnImage: "That clip isn’t an image. Use Pick a Clip or Get Clip Text instead."
        }
    }
}
