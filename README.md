# button

A small iOS app (Swift + SwiftUI) for practicing speaking a language.

Hold the big red button and speak. Let go, and the app:

1. saves the recording,
2. transcribes it on the device with **Whisper** (via WhisperKit),
3. stores the phrase in an on-device **SwiftData** (SQLite) database,
4. translates it with several **candidate translation models**, times each one and saves every result, so the models can be compared.

When the app starts, a small pill fills up while the Whisper model loads, then springs into the red button.

Built as a learning project: my first iOS app.

## Running it

- Open `button.xcodeproj` in Xcode.
- Pick the **iPhone 17** simulator (or a real iPhone) and press **⌘R**.
- On the first launch the Whisper model (`small`, ~480 MB) is downloaded from Hugging Face, so you need internet once.
- Allow microphone access when asked. In the Simulator the Mac's microphone is used.

Current settings:

| Setting | Value | Where |
|---|---|---|
| Spoken language | Italian (`"it"`) | `Transcriber.language` |
| Translate into | English (`"en"`) | `ContentView.targetLanguage` |
| Whisper model | `small` | `Transcriber.loadModel()` |

## Structure

Front end and back end are kept apart:

- **`UI/`**: SwiftUI views. No real logic; they only call into `Core/`.
- **`Core/`**: plain Swift logic (no SwiftUI): recording, transcription, translation, storage.

```
button/
├── buttonApp.swift
├── UI/
│   ├── ContentView.swift
│   └── LoadingPill.swift
└── Core/
    ├── AudioRecorder.swift
    ├── Transcriber.swift
    ├── Phrase.swift
    ├── PhraseTranslation.swift
    ├── PhraseStore.swift
    ├── Translator.swift
    ├── AppleTranslator.swift
    └── WhisperTranslator.swift
```

Dependencies:

- **[WhisperKit](https://github.com/argmaxinc/WhisperKit)** (Swift package, 1.x) runs Whisper on Apple chips.
- Everything else is built into iOS: AVFoundation, SwiftData, Translation and Observation.

---

## Files

### `buttonApp.swift`
The app's starting point (`@main`). It opens one window that shows `ContentView`.

### UI

#### `UI/ContentView.swift`
The only screen.

- **Pill → circle:** a single `Capsule` is a 140×28 pill while loading and becomes a 200×200 circle when ready. A capsule as wide as it is tall *is* a circle, and the change animates with a spring.
- **Loading:** while loading, it shows `LoadingPill` with `transcriber.loadProgress`.
- **Hold to record:** a `DragGesture(minimumDistance: 0)` gives "finger down" (start recording, darker red) and "finger up" (stop recording, transcribe).
- **After a recording:** shows the transcript, saves it as a `Phrase`, runs all translation candidates, and lists every saved phrase with its successful translations and their timing. Failed translations are kept in the database but not shown. Each translation has ✓ / ✗ buttons to rate it right or wrong.
- **At startup (`.task`):** loads saved phrases, loads Whisper, triggers the morph, then asks for mic permission.

#### `UI/LoadingPill.swift`
A pill-shaped progress bar: a grey track with a red fill that grows left to right with `progress` (0 to 1). It only displays the value it's given and loads nothing itself.

### Core: recording and transcription

#### `Core/AudioRecorder.swift`
Records the microphone with `AVAudioRecorder`.

- `requestPermission()` shows the mic popup (first time only).
- `startRecording()` sets up the audio session and records to `Documents/recording.m4a` (AAC, 44.1 kHz, mono). Each recording replaces the previous one.
- `stopRecording()` stops, finishes the file, and returns its URL.

The microphone text shown to the user is set in the project's build settings (`NSMicrophoneUsageDescription`).

#### `Core/Transcriber.swift`
Turns audio into text with Whisper (WhisperKit), fully on the device. It is `@Observable`, so the UI follows `loadProgress`.

- `loadModel()` loads the model only once, even if called many times: everyone waits on the same `Task`. Downloading fills progress 0 → 0.8, and loading into memory takes it to 1.0.
- `transcribe(url:)` transcribes in `language`.
- `translateToEnglish(url:)` uses Whisper's translate mode, writing English text straight from the audio.

### Core: storage (SwiftData)

#### `Core/Phrase.swift`
The `Phrase` table: `text`, `createdAt`, `language`, plus `translations`, which links to `PhraseTranslation`. Deleting a phrase also deletes its translations.

#### `Core/PhraseTranslation.swift`
The `PhraseTranslation` table: one translation attempt of one phrase by one model.

- Fields: `engine`, `targetLanguage`, `text`, `error`, `durationMs`, `createdAt`, `isCorrect` (your rating: `nil` = not rated), `phrase`.
- Failures are stored too, so the comparison is fair.

#### `Core/PhraseStore.swift`
Opens the database and reads and writes it. It runs on the main thread (`@MainActor`).

- `save(text:language:)` saves a phrase (skips empty text) and returns it.
- `fetchAll()` returns all phrases, newest first.
- `translate(_:audio:with:to:)` runs each candidate in turn, times it, and saves a `PhraseTranslation` per candidate.
- `rate(_:isCorrect:)` saves your right/wrong rating for one translation.

### Core: translation candidates

#### `Core/Translator.swift`
The `Translator` protocol that every candidate follows: a `name` and `translate(_:audio:from:to:)`. Candidates get both the text and the recording, so text-based and audio-based models fit the same shape.

#### `Core/AppleTranslator.swift`
Candidate: **Apple Translation** (`TranslationSession`), free and on-device. **Currently switched off** (not in the candidate list in `ContentView`).

- Both languages must be downloaded on the device: Settings → Apps → Translate.
- **It doesn't work in the Simulator** ("translation isn't supported on the current device"), so test it on a real iPhone.

#### `Core/WhisperTranslator.swift`
Candidate: **Whisper translate**.

- Translates from the audio, reusing the already loaded Whisper model.
- It can only translate **into English**. For any other target it throws `OnlyEnglishError`.

---

## License

[MIT](LICENSE)

## Ideas / next steps

- Turn saved phrases into a TabularData `DataFrame` to compare candidates (speed, failures, outputs side by side).
- More candidates: Apple Foundation Models (on-device LLM), Claude API.
- Keep each recording as its own file instead of overwriting `recording.m4a`.
