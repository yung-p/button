import Foundation
import Translation // Apple's on-device translation framework (same engine as the Translate app)

// Candidate 1: Apple's built-in translation. Free, offline, no package needed.
struct AppleTranslator: Translator { // ": Translator" = promises to provide everything the Translator protocol asks for
    let name = "Apple Translation"

    func translate(_ text: String, audio: URL, from source: String, to target: String) async throws -> String { // Text-based: ignores `audio`
        let session = TranslationSession( // A translation "session" for one language pair
            installedSource: Locale.Language(identifier: source), // Turns "en" into Apple's language type
            target: Locale.Language(identifier: target)
        ) // "installed" = both languages must already be downloaded on the device (Settings > Apps > Translate)
        let response = try await session.translate(text) // Runs the translation; throws if e.g. the languages aren't installed
        return response.targetText // The translated text
    }
}
