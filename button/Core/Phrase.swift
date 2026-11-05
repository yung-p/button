import Foundation // Gives us Date
import SwiftData // Apple's database framework (stores everything in SQLite under the hood)

// One spoken phrase. SwiftData turns this class into a database table: each property is a column, each Phrase is a row.
@Model // Marks this class as something SwiftData can save and load
final class Phrase {
    var text: String // What was said
    var createdAt: Date // When it was said
    var language: String // Language code, e.g. "en" or "nl"
    @Relationship(deleteRule: .cascade, inverse: \PhraseTranslation.phrase) // Links to the other table. cascade = deleting a phrase also deletes its translations
    var translations: [PhraseTranslation] = [] // All translation attempts for this phrase (one per candidate)

    init(text: String, language: String, createdAt: Date = .now) { // Creates a new phrase. createdAt defaults to the current time if you don't pass one
        self.text = text // "self.text" = this object's property; plain "text" = the value passed in
        self.language = language
        self.createdAt = createdAt
    }
}
