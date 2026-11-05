import Foundation // Apple's basic types, like URL
import Observation // Gives us @Observable (without pulling SwiftUI into the back end)
import WhisperKit // The Swift package we added: runs OpenAI's Whisper model on Apple chips

// Turns recorded audio into text, fully on the device. The UI just calls its functions.
@Observable // SwiftUI automatically redraws any view that reads a property of this class when it changes
final class Transcriber {
    private(set) var loadProgress = 0.0 // 0 = nothing loaded, 1 = ready. The UI reads this to fill the loading pill
    let language = "it" // Language Whisper listens for ("en" = English, "nl" = Dutch, ...). One place to change it, and the UI can read it to save with each phrase
    @ObservationIgnored private var whisper: WhisperKit? // The loaded model. nil until loading has finished. Ignored = the UI doesn't need to watch it
    @ObservationIgnored private var loadingTask: Task<Void, Error>? // The one running (or finished) load. Lets everyone wait on the same load instead of starting a new one

    func loadModel() async throws { // Safe to call many times: it only ever loads once
        if loadingTask == nil { // Nobody has started loading yet: start it now
            loadingTask = Task { // A piece of async work we can keep a handle on and wait for later
                // Part 1 (0 -> 0.8): download. First run fetches "base" (~99 languages) from Hugging Face; later runs find the saved copy
                let folder = try await WhisperKit.download(variant: "small") { progress in // This closure is called again and again while downloading
                    Task { @MainActor in self.loadProgress = progress.fractionCompleted * 0.8 } // fractionCompleted goes 0 -> 1. UI values must change on the main thread
                }

                // Part 2 (0.8 -> 1): load the downloaded model into memory. WhisperKit gives no percentage here, only "done"
                let config = WhisperKitConfig(modelFolder: folder.path, load: true) // Use the folder we just downloaded. load: true = put it in memory right away
                whisper = try await WhisperKit(config)
                await MainActor.run { loadProgress = 1.0 } // Fully ready
            }
        }
        do {
            try await loadingTask?.value // Wait for that load to finish. Returns instantly if it already has
        } catch {
            loadingTask = nil // Loading failed (e.g. no internet): forget it, so the next call can try again
            throw error // Pass the error on to the caller
        }
    }

    func transcribe(url: URL) async throws -> String { // Give it an audio file, get back the spoken text
        try await loadModel() // Already loaded: returns at once. Still loading: waits for it. Never loaded: loads now
        guard let whisper else { return "" } // "guard let" = unwrap the optional; if it's still nil, give back empty text

        let options = DecodingOptions(language: language) // Tell Whisper which language the audio is in (see `language` above)
        let results = try await whisper.transcribe(audioPath: url.path, decodeOptions: options) // Whisper splits long audio into pieces, so we get a list of results
        let text = results.map { $0.text }.joined(separator: " ") // Take the text from each piece and glue them together with spaces
        return text.trimmingCharacters(in: .whitespaces) // Remove spaces at the start/end (Whisper often adds a leading space)
    }

    func translateToEnglish(url: URL) async throws -> String { // Same as transcribe, but Whisper writes English text straight from the audio
        try await loadModel()
        guard let whisper else { return "" }

        let options = DecodingOptions(task: .translate, language: language) // task: .translate = output English. language = what's spoken in the audio
        let results = try await whisper.transcribe(audioPath: url.path, decodeOptions: options)
        let text = results.map { $0.text }.joined(separator: " ")
        return text.trimmingCharacters(in: .whitespaces)
    }
}
