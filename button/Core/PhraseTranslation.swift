import Foundation
import SwiftData

// One translation attempt of one Phrase by one Translator. A second table in the database.
// (Not called "Translation": that name is taken by Apple's Translation framework.)
@Model
final class PhraseTranslation {
    var engine: String // Which candidate made it, e.g. "Apple Translation"
    var targetLanguage: String // e.g. "nl"
    var text: String // The translated text ("" if it failed)
    var error: String? // Why it failed, or nil if it worked. Failures are kept too, so we can compare candidates fairly
    var durationMs: Double // How long the translation took, in milliseconds
    var createdAt: Date
    var isCorrect: Bool? = nil // Your rating: nil = not rated yet, true = right, false = wrong. Optional, so existing rows simply start as nil
    var phrase: Phrase? // The phrase this belongs to. SwiftData links the two tables through this

    init(engine: String, targetLanguage: String, text: String, error: String?, durationMs: Double, createdAt: Date = .now) {
        self.engine = engine
        self.targetLanguage = targetLanguage
        self.text = text
        self.error = error
        self.durationMs = durationMs
        self.createdAt = createdAt
    }
}
