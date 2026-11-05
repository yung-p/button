import Foundation

// Candidate 2: Whisper's built-in translate mode. Works from the audio (not the text), and can only translate INTO English.
struct WhisperTranslator: Translator {
    let name = "Whisper translate"
    let transcriber: Transcriber // Reuses the Whisper model that's already loaded, instead of loading a second copy

    func translate(_ text: String, audio: URL, from source: String, to target: String) async throws -> String { // Audio-based: ignores `text`
        guard target == "en" else { throw OnlyEnglishError() } // Whisper can't translate into other languages: fail clearly instead of returning nonsense
        return try await transcriber.translateToEnglish(url: audio)
    }
}

// The error thrown above. LocalizedError lets us choose the message that ends up in the red line in the UI.
struct OnlyEnglishError: LocalizedError {
    var errorDescription: String? { "Whisper can only translate into English" }
}
