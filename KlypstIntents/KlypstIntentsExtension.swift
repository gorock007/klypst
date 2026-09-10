import AppIntents
import ExtensionFoundation

/// App Intents extension. Intents here run in their own system-hosted process,
/// so the Action Button never has to launch or resume the Klypst app.
@main
struct KlypstIntentsExtension: AppIntentsExtension {}
