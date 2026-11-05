import Foundation

// The shared "shape" every translation candidate must have.
// A protocol lists what a type must provide, without saying how. Each model (Apple, Whisper, ...) is its own type that follows it,
// so the rest of the app can treat them all the same and we can compare them.
protocol Translator {
    var name: String { get } // Shown in the UI and saved with each result, e.g. "Apple Translation". "{ get }" = must be readable

    // Gets both the text and the original recording: text-based models use `text`, audio-based ones (Whisper) use `audio`.
    // source/target are language codes like "en", "nl"
    func translate(_ text: String, audio: URL, from source: String, to target: String) async throws -> String
}
