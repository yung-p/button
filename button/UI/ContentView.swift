import SwiftUI

struct ContentView: View {
    @State private var recorder = AudioRecorder() // One recorder (from Core/) that lives as long as this screen
    @State private var transcriber = Transcriber() // One transcriber (from Core/), so the model only loads once
    @State private var isHolding = false // True while a finger is on the circle; changing it redraws the screen
    @State private var transcript = "" // The text shown under the circle
    @State private var isReady = false // False while loading (show the pill). True = morph into the circle
    @State private var store = try? PhraseStore() // The phrase database (from Core/). "try?" = if opening fails we get nil instead of a crash
    @State private var phrases: [Phrase] = [] // The saved phrases shown in the list, newest first
    private let targetLanguage = "en" // Language to translate into. Spoken language comes from transcriber.language

    var body: some View {
        VStack(spacing: 30) { // Circle on top, text below, 30 points apart
            Capsule() // A capsule that's as wide as it is tall is a circle, so one shape can be both pill and circle
                .fill(isHolding ? Color.red.mix(with: .black, by: 0.25) : Color.red) // Held: red mixed with 25% black. Not held: plain red
                .opacity(isReady ? 1 : 0) // Hidden while loading; the LoadingPill below is shown instead
                .overlay { // Draws on top of the capsule, at the same size
                    if !isReady {
                        LoadingPill(progress: transcriber.loadProgress) // Fills up as Whisper loads. Redraws by itself because Transcriber is @Observable
                    }
                }
                .frame(width: isReady ? 200 : 140, height: isReady ? 200 : 28) // Pill size while loading, circle size when ready (same 140x28 as LoadingPill)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isReady) // When isReady flips, animate size/opacity with a bouncy spring. Lower damping = more bounce
                .gesture( // Attach our own touch handling to the circle
                    DragGesture(minimumDistance: 0) // A "drag" of 0 points = any touch counts, so we hear about finger down and finger up
                        .onChanged { _ in // Runs on finger down, and again every time the finger moves
                            guard isReady, !isHolding else { return } // Still loading, or already holding: do nothing
                            isHolding = true
                            do {
                                try recorder.startRecording()
                            } catch {
                                print("Could not start recording:", error) // Shows up in Xcode's console
                            }
                        }
                        .onEnded { _ in // Runs once, when the finger lifts
                            isHolding = false
                            if let url = recorder.stopRecording() { // "if let" = only run the next lines if we got a URL back (not nil)
                                print("Saved recording to:", url)
                                transcribe(url)
                            }
                        }
                )

            Text(transcript)
                .multilineTextAlignment(.center)
                .padding(.horizontal) // Keep long text away from the screen edges

            List(phrases) { phrase in // A scrollable list with one row per saved phrase
                VStack(alignment: .leading, spacing: 4) {
                    Text(phrase.text)
                    ForEach(phrase.translations.filter { $0.error == nil }) { translation in // One line per successful result. Failures stay in the database but aren't shown
                        HStack {
                            Text("\(translation.engine) (\(Int(translation.durationMs)) ms): \(translation.text)") // e.g. "Whisper translate (120 ms): hello"
                                .font(.callout)
                                .foregroundStyle(.blue)
                            Spacer() // Pushes the buttons to the right edge
                            Button {
                                try? store?.rate(translation, isCorrect: true)
                            } label: {
                                Image(systemName: translation.isCorrect == true ? "checkmark.circle.fill" : "checkmark.circle") // Filled when this is the chosen answer
                                    .foregroundStyle(translation.isCorrect == true ? .green : .secondary)
                            }
                            Button {
                                try? store?.rate(translation, isCorrect: false)
                            } label: {
                                Image(systemName: translation.isCorrect == false ? "xmark.circle.fill" : "xmark.circle")
                                    .foregroundStyle(translation.isCorrect == false ? .red : .secondary)
                            }
                        }
                        .buttonStyle(.borderless) // Without this, a List row turns into one big button and both taps hit the same action
                        .font(.title3) // Makes the icons big enough to tap easily
                    }
                    Text(phrase.createdAt, style: .time) // Shows just the time, e.g. "14:32"
                        .font(.caption)
                        .foregroundStyle(.secondary) // Grey, less important than the phrase itself
                }
            }
        }
        .task { // Runs once when the screen appears; can wait for async work
            phrases = (try? store?.fetchAll()) ?? [] // Load saved phrases. "?? []" = if anything failed, use an empty list
            try? await transcriber.loadModel() // Load Whisper while the pill fills up. "try?" = ignore errors here; transcribe() will retry and show them
            try? await Task.sleep(for: .seconds(0.4)) // Short pause so you see the pill reach 100% before it morphs
            isReady = true // Triggers the morph from pill to circle
            _ = await recorder.requestPermission() // Mic popup (first time only), after loading so it doesn't hold up the pill. "_ =" = we don't need the returned Bool
        }
    }

    private func transcribe(_ url: URL) {
        transcript = "Transcribing…"
        Task { // Starts async work from a normal (non-async) place, like a gesture
            do {
                transcript = try await transcriber.transcribe(url: url)
                if let phrase = try store?.save(text: transcript, language: transcriber.language) { // Save the phrase. nil = nothing saved (silence, or no database)
                    phrases = try store?.fetchAll() ?? [] // Reload the list so the new phrase shows up at the top
                    let translators: [any Translator] = [WhisperTranslator(transcriber: transcriber)] // The candidates to compare. Add new ones here (AppleTranslator() is off for now)
                    try await store?.translate(phrase, audio: url, with: translators, to: targetLanguage) // Run all candidates; the row updates by itself when results are added
                }
            } catch {
                transcript = "Error: \(error.localizedDescription)" // Show what went wrong instead of crashing
            }
        }
    }
}

#Preview { // Live preview in Xcode's canvas, no simulator needed
    ContentView()
}
