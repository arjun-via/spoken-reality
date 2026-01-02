import Foundation
import AVFoundation
import Combine

// MARK: - Recording State

enum RecordingState {
    case idle
    case recording
    case paused
    case stopped
}

// MARK: - Audio Streaming Delegate

protocol AudioStreamingDelegate: AnyObject {
    func audioRecorder(didReceiveChunk data: Data)
}

// MARK: - Audio Recording Service

@MainActor
class AudioRecordingService: NSObject, ObservableObject {
    // Published properties
    @Published var recordingState: RecordingState = .idle
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0 // -160 to 0 dB
    @Published var permissionGranted: Bool = false
    @Published var errorMessage: String?

    // Private properties
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession = .sharedInstance()
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private var streamingTimer: Timer?
    private var recordingURL: URL?
    private var lastReadPosition: UInt64 = 0

    // Streaming delegate
    weak var streamingDelegate: AudioStreamingDelegate?

    // Mock mode for testing without microphone
    var useMockRecording: Bool = false // Set to false for real microphone

    // Singleton
    static let shared = AudioRecordingService()

    private override init() {
        super.init()
        checkPermission()
    }

    // MARK: - Permission Management

    func checkPermission() {
        switch audioSession.recordPermission {
        case .granted:
            permissionGranted = true
        case .denied:
            permissionGranted = false
        case .undetermined:
            permissionGranted = false
        @unknown default:
            permissionGranted = false
        }
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                Task { @MainActor in
                    self.permissionGranted = granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Recording Control

    func startRecording() async throws {
        if useMockRecording {
            // Mock recording mode - no microphone needed
            print("🎤 Starting MOCK recording (no microphone)")
            recordingState = .recording
            recordingDuration = 0
            startMockRecording()
            return
        }

        // Real recording mode
        // Request permission if needed
        if !permissionGranted {
            let granted = await requestPermission()
            if !granted {
                throw RecordingError.permissionDenied
            }
        }

        // Configure audio session
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)

        // Create recording URL (.caf for PCM format)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Date().timeIntervalSince1970
        recordingURL = documentsPath.appendingPathComponent("recording_\(timestamp).caf")

        guard let url = recordingURL else {
            throw RecordingError.invalidURL
        }

        // Configure recording settings for backend compatibility
        // Backend expects: PCM 16-bit, 16kHz, mono
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,  // 16kHz for backend
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,  // 16-bit
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        // Create and configure recorder
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()

        // Start recording
        let success = audioRecorder?.record() ?? false
        if !success {
            throw RecordingError.recordingFailed
        }

        recordingState = .recording
        recordingDuration = 0

        // Start timers
        startTimers()
    }

    func stopRecording() {
        if useMockRecording {
            print("🎤 Stopping MOCK recording")
            stopMockRecording()
            recordingState = .stopped
            return
        }

        audioRecorder?.stop()
        recordingState = .stopped

        // Stop timers
        stopTimers()

        // Deactivate audio session
        try? audioSession.setActive(false)
    }

    func pauseRecording() {
        audioRecorder?.pause()
        recordingState = .paused
        stopTimers()
    }

    func resumeRecording() {
        audioRecorder?.record()
        recordingState = .recording
        startTimers()
    }

    func cancelRecording() {
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        recordingState = .idle
        recordingDuration = 0
        audioLevel = 0

        stopTimers()

        // Delete the file
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil

        try? audioSession.setActive(false)
    }

    // MARK: - Timers

    private func startTimers() {
        lastReadPosition = 0

        // Duration timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.recordingDuration = self.audioRecorder?.currentTime ?? 0
            }
        }

        // Audio level timer
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.audioRecorder?.updateMeters()
                let level = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
                // Normalize from -160..0 to 0..1
                self.audioLevel = (level + 160) / 160
            }
        }

        // Streaming timer - read and send audio chunks every 100ms
        streamingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.readAndStreamAudioChunk()
            }
        }
    }

    private func stopTimers() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
        streamingTimer?.invalidate()
        streamingTimer = nil
    }

    // MARK: - Audio Streaming

    private func readAndStreamAudioChunk() {
        guard let url = recordingURL,
              let delegate = streamingDelegate,
              FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        do {
            let fileHandle = try FileHandle(forReadingFrom: url)
            defer { try? fileHandle.close() }

            // Seek to last read position
            if lastReadPosition > 0 {
                try fileHandle.seek(toOffset: lastReadPosition)
            }

            // Read available data (up to 16KB chunk)
            let chunkSize = 16 * 1024
            let data = fileHandle.readData(ofLength: chunkSize)

            if !data.isEmpty {
                lastReadPosition += UInt64(data.count)
                delegate.audioRecorder(didReceiveChunk: data)
            }
        } catch {
            print("Error reading audio chunk: \(error)")
        }
    }

    // MARK: - File Management

    func getRecordingURL() -> URL? {
        return recordingURL
    }

    func getRecordingData() -> Data? {
        guard let url = recordingURL else { return nil }
        return try? Data(contentsOf: url)
    }

    // MARK: - Cleanup

    func cleanup() {
        cancelRecording()
    }

    // MARK: - Mock Recording (for testing without microphone)

    private func startMockRecording() {
        // Duration timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.recordingDuration += 0.1
            }
        }

        // Audio level animation (fake waveform)
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                // Simulate audio level with random variation
                self.audioLevel = Float.random(in: 0.3...0.9)
            }
        }

        // Streaming timer - send fake audio chunks
        streamingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.sendMockAudioChunk()
            }
        }

        print("🎤 Mock recording started - sending fake audio chunks")
    }

    private func stopMockRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
        streamingTimer?.invalidate()
        streamingTimer = nil

        print("🎤 Mock recording stopped")
    }

    private func sendMockAudioChunk() {
        guard let delegate = streamingDelegate else { return }

        // Generate fake PCM audio data (16KB chunk)
        // In reality this would be silence or test tone
        let chunkSize = 16 * 1024
        var mockData = Data(count: chunkSize)
        mockData.withUnsafeMutableBytes { buffer in
            // Fill with random values to simulate audio
            if let baseAddress = buffer.baseAddress {
                for i in 0..<chunkSize {
                    baseAddress.storeBytes(of: UInt8.random(in: 0...255), toByteOffset: i, as: UInt8.self)
                }
            }
        }

        delegate.audioRecorder(didReceiveChunk: mockData)
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordingService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if flag {
                recordingState = .stopped
            } else {
                errorMessage = "Recording finished with errors"
                recordingState = .idle
            }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            errorMessage = error?.localizedDescription ?? "Unknown recording error"
            recordingState = .idle
        }
    }
}

// MARK: - Errors

enum RecordingError: LocalizedError {
    case permissionDenied
    case invalidURL
    case recordingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .invalidURL:
            return "Invalid recording URL"
        case .recordingFailed:
            return "Failed to start recording"
        }
    }
}
