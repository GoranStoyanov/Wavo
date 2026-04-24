//
//  AudioManager.swift
//  Vial
//
//  Created by Steliyan Hadzhidenev on 19.11.22.
//

import AVFoundation
import Foundation

protocol AudioManagerRecordingDelegate: NSObjectProtocol {
    
    /// Delegate method to notify if recording for the given manager is allowed
    /// - Parameters:
    ///   - manager: `AudioManager` instance
    ///   - flag: `true` or `false` depending if the recording is allowed
    func didAllowRecording(manager: AudioManager, flag: Bool)
    
    /// Delegate method to notify if recording finished successfully for the given manager
    /// - Parameters:
    ///   - manager: `AudioManager` instance
    ///   - flag: `true` or `false` depending if the recording finished successfully
    func didFinishRecordingSuccessfully(manager: AudioManager, flag: Bool)
    
    /// Delegate method to provide recording progress updates for the given manager
    /// - Parameters:
    ///   - manager: `AudioManager` instance
    ///   - progress: recording progress
    func didUpdateRecordingProgress(manager: AudioManager, progress: Double)
    
}

protocol AudioManagerPlaybackDelegate: NSObjectProtocol {
    
    /// Deleagte method to notify if playing finished successfully for the given manager
    /// - Parameters:
    ///   - manager: `AudioManager` instance
    ///   - flag: `true` or `false` depending if the playing finished successfully
    func didFinishPlayingSuccessfully(manager: AudioManager, flag: Bool)
    
    
    /// Delegate method to provide playing updates for the given manager
    /// - Parameters:
    ///   - manager: `AudioManager` instance
    ///   - progress: playing progress
    func didUpdatePlayingProgress(manager: AudioManager, progress: Double)
    
}

final class AudioManager: NSObject {
    
    // MARK: - Singleton properties
    
    static let shared = AudioManager()
    
    // MARK: - Static properties
    
    // MARK: - Public properties
    
    /// Property to store a delegate instance for recording
    weak var recordingDelegate: AudioManagerRecordingDelegate?
    
    /// Property to store a delegate instance for playback
    weak var playbackDelegate: AudioManagerPlaybackDelegate?
    
    /// Property to store teh last recorded audio path
    var lastRecordedAudioPath: URL?
    
    /// Property to store the maximum recording length (By default it is set to 10 minutes)
    var maxRecordingTime = TimeInterval(600)
    
    /// Property to return the last average power
    var lastAveragePower: Float {
        recorder?.averagePower(forChannel: 0) ?? 0.0
    }
    
    /// Property to indicate if the recorder is recording
    var recording: Bool {
        recorder?.isRecording ?? false
    }
    
    var playing: Bool {
        player?.isPlaying ?? false
    }
    
    // MARK: - Public methods
    
    /// Public methd to start recording
    func startRecording(completion: @escaping ((Error?) -> Void)) {
        if recorder?.isRecording == false || recorder == nil {
            
            if player?.isPlaying == true {
                player?.stop()
                progressIndicatorTimer?.invalidate()
            }
            
            askForRecordingPermissions { [weak self] granted in
                guard let self = self else {
                    return completion(AudioManagerError.internalError)
                }
                
                self.recordingDelegate?.didAllowRecording(manager: self, flag: granted)
                
                if granted {
                    do {
                        try self.prepareRecorder()
                        self.recorder?.record()
                        self.progressIndicatorTimer?.invalidate()
                        self.progressIndicatorTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.progressIndicatorTimerUpdates(timer:)), userInfo: nil, repeats: true)
                        completion(nil)
                    } catch let error {
                        completion(error)
                    }
                }
               
            }
        }
    }
    
    /// Public method to stop recording
    func stopRecording() throws {
        if recorder?.isRecording == true {
            progressIndicatorTimer?.invalidate()
            
            recorder?.stop()
            try AVAudioSession.sharedInstance().setActive(false)
        }
    }
    
    
    /// Public method to play last recorded file
    func playLastRecord() throws {
        
        if isPlaybackPause {
            player?.play()
            isPlaybackPause.toggle()
            
            return
        }
        
        guard let lastRecordedAudioPath else {
            throw AudioManagerError.noAudioFileRecorded
        }
        
        try playAudioFile(from: lastRecordedAudioPath)
    }
    
    /// Public method to pause playing
    func pausePlaying() {
        isPlaybackPause.toggle()
        player?.pause()
    }
    
    /// Public method to stop playing
    func stopPlaying() {
        if player?.isPlaying == true {
            player?.stop()
            progressIndicatorTimer.invalidate()
        }
    }
    
    // MARK: - Initialize/Lifecycle methods
    
    override init() {
        super.init()
    }
    
    // MARK: - Override methods
    
    // MARK: - Private properties
    
    /// Private property to store `AVAudioPlayer` instance
    private var player: AVAudioPlayer? {
        didSet {
            player?.delegate = self
        }
    }
    
    /// Private property to store `AVAudioRecorder` instance
    private var recorder: AVAudioRecorder? {
        didSet {
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
        }
    }
    
    /// Private property to store progress indicator timer
    private var progressIndicatorTimer: Timer!
    
    
    /// Private property to store encoder bit rate
    private let encoderBitRate = 320000
    
    /// Private property to store the number of channels
    private let numberOfChannels = 1
    
    /// Private property to store the sample rate
    private let sampleRate = Double(44100)
    
    /// Private property to store the recording's file name prefix
    private let recordingFileNamePrefix = "Recording_"
    
    /// Private property to store the current recording time
    private var currentRecordingTime = TimeInterval(0)
    
    /// Private property to indicate if the playback was paused
    private var isPlaybackPause = false
    
    /// Private lazy initialised date formatter
    private lazy var dateTimeFormatter: DateFormatter = {
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.timeZone = TimeZone.current
        dateTimeFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        
        return dateTimeFormatter
    }()
    
    // MARK: - Private methods
    
    /// Private method to ask for recording permissions
    /// - Parameter completion: Completion handler to return if recording permissions are granted
    private func askForRecordingPermissions(completion: @escaping ((Bool) -> Void)) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    /// Private method to prepare the recorder for recording
    private func prepareRecorder() throws {
        if recorder?.isRecording == true {
            throw AudioManagerError.alreadyRecording
        }
        
        let recordSettings = [
            AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey: numberOfChannels,
            AVSampleRateKey : sampleRate
        ] as [String: Any]
        
        var temporaryFilePath = FileManager.default.temporaryDirectory
        if #available(iOS 16.0, *) {
            temporaryFilePath.append(path: recordingFileNamePrefix + dateTimeFormatter.string(from: .now) + ".m4a")
        } else {
            temporaryFilePath.appendPathComponent(recordingFileNamePrefix + dateTimeFormatter.string(from: Date()) + ".m4a")
        }
        
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try AVAudioSession.sharedInstance().setActive(true)
        
        recorder = try AVAudioRecorder(url: temporaryFilePath, settings: recordSettings)
        
        if recorder?.prepareToRecord() == false {
            throw AudioManagerError.recordFailed
        }
        
        lastRecordedAudioPath = temporaryFilePath
    }
    
    /// Private method to play an audio file
    /// - Parameter url: URL of the file to be played
    private func playAudioFile(from url: URL) throws {
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try AVAudioSession.sharedInstance().setActive(true)
        
        if recorder?.isRecording == false {
            progressIndicatorTimer?.invalidate()
            player = try AVAudioPlayer(contentsOf: url)
            if player?.prepareToPlay() == false {
                throw AudioManagerError.playFailed
            }
            
            progressIndicatorTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(playbackStatusTimerUpdates(timer:)), userInfo: nil, repeats: true)
            
            player?.play()
        }
        
    }
    
    /// Private method to handle updates on the progress indicator timer
    @objc private func progressIndicatorTimerUpdates(timer: Timer) {
        currentRecordingTime = recorder?.currentTime ?? 0
        let progress = max(0, min(1, currentRecordingTime / maxRecordingTime))
        
        recorder?.updateMeters()
        recordingDelegate?.didUpdateRecordingProgress(manager: self, progress: progress)
        
        if progress >= 1.0 {
            try? stopRecording()
        }
    }
    
    /// Private method to handle updates on the playback status indicator timer
    @objc private func playbackStatusTimerUpdates(timer: Timer) {
        let currentPlayTime = (player?.currentTime ?? 0.0) / (player?.duration ?? 0.0)
        let progress = max(0, min(1, currentPlayTime))
        
        playbackDelegate?.didUpdatePlayingProgress(manager: self, progress: progress)
    }
}

// MARK: AVAudioPlayerDelegate methods
extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressIndicatorTimer?.invalidate()
        playbackDelegate?.didFinishPlayingSuccessfully(manager: self, flag: flag)
    }
}

// MARK: AVAudioRecorderDelegate methods
extension AudioManager: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        progressIndicatorTimer?.invalidate()
        recordingDelegate?.didFinishRecordingSuccessfully(manager: self, flag: flag)
    }
    
}
