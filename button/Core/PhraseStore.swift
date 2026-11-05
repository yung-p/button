import Foundation
import SwiftData

// Saves and loads Phrases (and their translations) from the on-device database. The UI just calls its functions.
@MainActor // All database work happens on the main thread, so the workspace is never used from two threads at once
final class PhraseStore {
    private let container: ModelContainer // The database itself: the SQLite file on disk plus the table layout
    private let context: ModelContext // Our "workspace" for that database: we add/change rows here, then save

    init() throws { // "throws" = opening the database can fail; the caller decides what to do
        container = try ModelContainer(for: Phrase.self, PhraseTranslation.self) // Opens (or creates) a database with both tables
        context = ModelContext(container)
    }

    @discardableResult // Callers may ignore the returned Phrase without a warning
    func save(text: String, language: String) throws -> Phrase? { // Returns the saved phrase, or nil if there was nothing to save
        guard !text.isEmpty else { return nil } // Nothing was said (e.g. silence): don't save an empty row

        let phrase = Phrase(text: text, language: language)
        context.insert(phrase) // Adds the row to our workspace. Not on disk yet
        try context.save() // Writes everything in the workspace to the SQLite file
        return phrase
    }

    func fetchAll() throws -> [Phrase] { // Returns every saved phrase as a list ("[Phrase]" = array of Phrase)
        let descriptor = FetchDescriptor<Phrase>( // Describes what to read: like a SQL SELECT, but in Swift
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)] // Sort by createdAt, newest first. "\.createdAt" = "the createdAt property"
        )
        return try context.fetch(descriptor) // Runs the query against the database and returns the rows
    }

    // Runs every candidate on one phrase, times each, saves all results.
    // "[any Translator]" = a list of any types that follow the Translator protocol
    func translate(_ phrase: Phrase, audio: URL, with translators: [any Translator], to target: String) async throws {
        for translator in translators { // One at a time, so the timings don't affect each other
            let start = Date() // Start the stopwatch
            var text = ""
            var errorMessage: String? = nil
            do {
                text = try await translator.translate(phrase.text, audio: audio, from: phrase.language, to: target)
            } catch {
                errorMessage = error.localizedDescription // Keep failures too, so they show up in the comparison
            }
            let durationMs = Date().timeIntervalSince(start) * 1000 // Stop the stopwatch. timeIntervalSince gives seconds, so x1000 for ms

            let result = PhraseTranslation(engine: translator.name, targetLanguage: target, text: text, error: errorMessage, durationMs: durationMs)
            phrase.translations.append(result) // Link it to the phrase (this also adds it to the database workspace)
        }
        try context.save() // Write all results to disk at once
    }

    func rate(_ translation: PhraseTranslation, isCorrect: Bool) throws { // Saves your right/wrong answer for one translation
        translation.isCorrect = isCorrect // The row is already in the database, so changing it is enough; SwiftData notices
        try context.save()
    }
}
