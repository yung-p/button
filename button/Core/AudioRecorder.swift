import AVFoundation // Apple's audio/video framework. No SwiftUI here: this is back end only.

// Handles everything about recording audio. The UI just calls its functions.
final class AudioRecorder { // "final" = no other class can inherit from it
    private(set) var hasPermission = false // Anyone can read it, only this class can change it

    func requestPermission() async -> Bool { // "async" = it can wait for the user's answer without freezing the app
        hasPermission = await AVAudioApplication.requestRecordPermission() // First time: shows the popup and waits. Later: returns the saved answer right away
        return hasPermission
    }

    private var recorder: AVAudioRecorder? // The active recorder. "?" = can be empty (nil) when nothing is recording

    func startRecording() throws { // "throws" = can fail with an error, and the caller decides what to do about it
        guard hasPermission else { return } // No mic permission: stop here and do nothing

        let session = AVAudioSession.sharedInstance() // The app's one connection to the iPhone's audio hardware
        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker]) // We want to record, and later play back through the speaker
        try session.setActive(true) // Switch audio on for our app

        let url = URL.documentsDirectory.appending(path: "recording.m4a") // Where to save: the app's private Documents folder. Each new recording replaces the last
        let settings: [String: Any] = [ // How to record: a dictionary of setting name -> value
            AVFormatIDKey: kAudioFormatMPEG4AAC, // AAC compression, the normal .m4a format
            AVSampleRateKey: 44_100, // 44,100 samples per second (CD quality)
            AVNumberOfChannelsKey: 1, // Mono: one channel is enough for a voice
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings) // Create a recorder that writes to that file
        recorder?.record() // Start recording. "?." = only do it if recorder isn't nil
    }

    func stopRecording() -> URL? { // Returns where the file was saved, or nil if nothing was recording
        recorder?.stop() // Stop and finish writing the file to disk
        let url = recorder?.url // Grab the file's location before we let go of the recorder
        recorder = nil // Empty it again: we're no longer recording
        return url
    }
}
