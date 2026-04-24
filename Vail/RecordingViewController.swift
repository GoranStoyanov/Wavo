//
//  ViewController.swift
//  Vial
//
//  Created by Steliyan Hadzhidenev on 12.11.22.
//

import UIKit
import AVFoundation
import PlayButton

class RecordingViewController: UIViewController {
    
    // MARK: - Singleton properties
    
    // MARK: - Static properties
    
    // MARK: - Public properties
    
    // MARK: - Public methods
    
    // MARK: - Initialize/Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Override methods
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0
        
        mailContentButton.frame = CGRect(x: 16.0, y: statusBarHeight + 8.0, width: 44.0, height: 44.0)
        
        waveformView.frame = CGRect(x: Dimensions.Offset, y: view.bounds.midY - Dimensions.WaveformHeight / 2, width: view.bounds.width - Dimensions.Offset * 2, height: Dimensions.WaveformHeight)
        
        timeLabel.frame = CGRect(x: waveformView.frame.minX, y: waveformView.frame.maxY + Dimensions.Offset, width: waveformView.frame.width, height: buttonSize.height)
        
        let buttonControlsWidth = buttonSize.width * 2 + Dimensions.Offset * 4
        
        playButton.frame = CGRect(x: view.bounds.midX - buttonControlsWidth / 2, y: timeLabel.frame.maxY + Dimensions.Offset, width: buttonSize.width, height: buttonSize.height)
        recordButton.frame = CGRect(x: playButton.frame.maxX + Dimensions.Offset * 2, y: playButton.frame.minY, width: buttonSize.width, height: buttonSize.height)
//        stopButton.frame = CGRect(x: recordButton.frame.maxX + Dimensions.Offset * 2, y: playButton.frame.minY, width: buttonSize.width, height: buttonSize.height)
        
        waveformImageView.frame = waveformView.frame
        waveformImageViewMask.frame = waveformView.frame
        
        recordingNameField.frame = CGRect(x: waveformView.frame.minX, y: recordButton.frame.maxY + Dimensions.Offset * 2, width: waveformView.frame.width, height: buttonSize.height)
        copyButton.frame = CGRect(x: view.bounds.midX - buttonSize.width, y: recordingNameField.frame.maxY + Dimensions.Offset * 2, width: buttonSize.width * 2, height: buttonSize.height)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        view.endEditing(true)
    }
    
    // MARK: - Private properties
    
    private var waveformView: WaveformLiveView! {
        didSet {
            waveformView.configuration = waveformView.configuration.with(style: .striped(.init(color: .red, width: 3, spacing: 3)), verticalScalingFactor: 2.0)
            waveformView.shouldDrawSilencePadding = true
            waveformView.backgroundColor = .clear
            view.addSubview(waveformView)
        }
    }
    
    private var audioManager: AudioManager! {
        didSet {
            audioManager.recordingDelegate = self
            audioManager.playbackDelegate = self
        }
    }
    
    private var recordButton: RecordButton! {
        didSet {
            recordButton.delegate = self
            recordButton.backgroundColor = .lightGray
            recordButton.layer.cornerRadius = buttonSize.height / 2
            view.addSubview(recordButton)
        }
    }
    
    private var playButton: PlayButton! {
        didSet {
            playButton.isEnabled = false
            playButton.setMode(.play, animated: false)
            playButton.addTarget(self, action: #selector(playButtonTapHandler(sender:)), for: .touchUpInside)
            view.addSubview(playButton)
        }
    }
    
    private var stopButton: PlayButton! {
        didSet {
            stopButton.isEnabled = false
            stopButton.setMode(.stop, animated: false)
            stopButton.addTarget(self, action: #selector(stopButtonTapHandler(sender:)), for: .touchUpInside)
            view.addSubview(stopButton)
        }
    }
    
    private var waveformImageView: WaveformImageView! {
        didSet {
            waveformImageView.configuration = Waveform.Configuration(
                backgroundColor: .clear,
                style: .striped(.init(color: .red, width: 3, spacing: 3)),
                verticalScalingFactor: 0.5
            )
            waveformImageView.alpha = 0.0
            
            view.addSubview(waveformImageView)
        }
    }
    
    private var waveformImageViewMask: WaveformImageView! {
        didSet {
            waveformImageViewMask.configuration = Waveform.Configuration(
                backgroundColor: .clear,
                style: .striped(.init(color: .green, width: 3, spacing: 3)),
                verticalScalingFactor: 0.5
            )
            waveformImageViewMask.alpha = 0.0
            let mask = CAShapeLayer()
            mask.path = CGPath(rect: .zero, transform: nil)
            
            waveformImageViewMask.layer.mask = mask
            
            view.addSubview(waveformImageViewMask)
        }
    }
    
    private var recordingNameField: RecordNameView! {
        didSet {
            recordingNameField.textColor = .label
            recordingNameField.isEnabled = false
            recordingNameField.alpha = 0.0
            recordingNameField.layer.borderColor = UIColor.label.cgColor
            recordingNameField.layer.borderWidth = 1.0
            recordingNameField.layer.cornerRadius = Dimensions.Offset
            
            view.addSubview(recordingNameField)
        }
    }
    
    private var copyButton: UIButton! {
        didSet {
            copyButton.setTitleColor(.label, for: .normal)
            copyButton.setTitle("Copy", for: .normal)
            copyButton.addTarget(self, action: #selector(copyButtonTapHandler(sender:)), for: .touchUpInside)
            copyButton.isEnabled = false
            copyButton.alpha = 0.0
            
            view.addSubview(copyButton)
        }
    }
    
    private var timeLabel: UILabel! {
        didSet {
            timeLabel.textAlignment = .center
            
            view.addSubview(timeLabel)
        }
    }
    
    private var mailContentButton: UIButton! {
        didSet {
            mailContentButton.setImage(UIImage(systemName: "mail.and.text.magnifyingglass.rtl"), for: .normal)
            mailContentButton.tintColor = .label
            mailContentButton.addTarget(self, action: #selector(showMailContentHandler(sender:)), for: .touchUpInside)
            
            view.addSubview(mailContentButton)
        }
    }
    
    private var recordTimer: Timer!
    
    private var recordSeconds = TimeInterval(0)
    
    private var audioFileDuration = TimeInterval(0)
    
    private let buttonSize = CGSize(width: 44.0, height: 44.0)
    
    private struct Dimensions {
        static let Offset = CGFloat(8.0)
        static let WaveformHeight = CGFloat(175.0)
    }
    
    // MARK: - Private methods
    
    
    /// Private method for basic configurations
    private func setup() {
        waveformView = WaveformLiveView()
        timeLabel = UILabel()
        recordButton = RecordButton()
        playButton = PlayButton()
//        stopButton = PlayButton()
        audioManager = AudioManager()
        
        mailContentButton = UIButton()
        
        waveformImageView = WaveformImageView(frame: .zero)
        waveformImageViewMask = WaveformImageView(frame: .zero)
        
        recordingNameField = RecordNameView()
        copyButton = UIButton()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        let spaceKeyCommand = UIKeyCommand(input: " ",
                                                   modifierFlags: [],
                                                   action: #selector(spaceKeyPressed(_:)))
                
                // Register the keyboard shortcut
                addKeyCommand(spaceKeyCommand)
    }
    
    @objc func spaceKeyPressed(_ sender: UIKeyCommand) {
            // Handle the action when space key is pressed
            print("Space key pressed!")
        }
    
    @objc private func showMailContentHandler(sender: UIButton) {
        let messageBodyViewController = MessageBodyViewController()
        messageBodyViewController.view.backgroundColor = view.backgroundColor
        
        
        present(messageBodyViewController, animated: true)
    }
    
    /// Private method to handle taps on the play button
    /// - Parameter sender: A  `PlayButton` instance
    @objc func playButtonTapHandler(sender: PlayButton) {
        
        if playButton.mode == .play {
           play()
        } else {
            playButton.setMode(.play)
            audioManager.pausePlaying()
            recordTimer.invalidate()
            print("stopped!")
        }
    }
    
    /// Private method to handle taps on the stop button
    /// - Parameter sender: A `PlayButton` instance
    @objc func stopButtonTapHandler(sender: PlayButton) {
        if audioManager.playing {
            playButton.setMode(.play)
            audioManager.stopPlaying()
            (waveformImageViewMask.layer.mask as? CAShapeLayer)?.path = CGPath(rect: .zero, transform: nil)
            timeLabel.text = "00:00/\(timeString(time: audioFileDuration))"
            recordSeconds = 0
            recordTimer.invalidate()
        }
    }
    
    /// Handles keyboard show event
    /// - Parameter notification: A notification object
    @objc private func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let visibleRectHeight = view.bounds.height - keyboardSize.height
            
            guard recordingNameField.frame.maxY > visibleRectHeight else {
                return
            }
            
            UIView.animate(withDuration: 0.1, animations: { [weak self] in
                if let self {
                    self.view.frame.origin.y -= (self.recordingNameField.frame.maxY - visibleRectHeight) + Dimensions.Offset * 2
                    self.view.layoutIfNeeded()
                }
            })
        }
    }
    
    /// Handles keyboard hide event
    /// - Parameter notification: A notification object
    @objc private func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.view.frame.origin.y = 0.0
            self?.view.layoutIfNeeded()
        })
    }
    
    /// Handles taps on the copy button
    /// - Parameter sender: A `UIButton` sender object
    @objc private func copyButtonTapHandler(sender: UIButton) {
        if let attachmentUrl = audioManager.lastRecordedAudioPath {
            if let attachment = NSItemProvider(contentsOf: attachmentUrl) {
                attachment.suggestedName = recordingNameField.text
                
                let stringProvider = NSItemProvider(object: (UserDefaults.standard.string(forKey: "kVailNewMessageBody") ?? "") as NSItemProviderWriting)
                    
                UIPasteboard.general.itemProviders = [stringProvider, attachment]
                    
                showToast(message: "File copied to clipboard", seconds: 1.5)
            }
        }
    }
    
    /// Return a `TimeInterval` in a formated string
    /// - Parameter time: Value to be formated
    /// - Returns: String in the format `mm:ss`
    private func timeString(time: TimeInterval) -> String {
        
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i", minutes, seconds)
    }
    
    private func play() {
        do {
            playButton.setMode(.pause)
            try audioManager.playLastRecord()
            recordSeconds = 0.0
            
            timeLabel.text = "00:00/\(timeString(time: audioFileDuration))"
            
            recordTimer.invalidate()
            recordTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] timer in
                guard let self else {
                    return
                }
                
                self.recordSeconds += 1
                
                self.timeLabel.text = "\(self.timeString(time: self.recordSeconds))/\(self.timeString(time: self.audioFileDuration))"
            })
        } catch let error {
            showAlert(message: error.localizedDescription)
        }
    }
}

extension RecordingViewController: AudioManagerRecordingDelegate {
    
    func didFinishRecordingSuccessfully(manager: AudioManager, flag: Bool) {
        playButton.isEnabled = flag
        stopButton?.isEnabled = flag
        
        if recordButton.isRecording {
            recordButton.endRecording()
        }
        
        recordTimer.invalidate()
        recordSeconds = 0.0
        
        guard let audioUrl = audioManager.lastRecordedAudioPath else {
            return
        }
        
        let audioAsset = AVURLAsset(url: audioUrl, options: nil)
        
        audioAsset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            guard let self else {
                return
            }
            
            var error: NSError? = nil
            let status = audioAsset.statusOfValue(forKey: "duration", error: &error)
            switch status {
            case .loaded:
                let duration = audioAsset.duration
                self.audioFileDuration = CMTimeGetSeconds(duration)
                
                DispatchQueue.main.async {
                    self.timeLabel.text = "00:00/\(self.timeString(time: self.audioFileDuration))"
                    
                    self.waveformView.fadeOut(0.5) { [weak self] finished in
                        if finished, let self {
                            
                            self.waveformView.reset()
                            self.waveformImageView.fadeIn(0.5) { finished in
                                self.waveformImageView.waveformAudioURL = self.audioManager.lastRecordedAudioPath
                            }
                            
                            (self.waveformImageViewMask.layer.mask as? CAShapeLayer)?.path = CGPath(rect: .zero, transform: nil)
                            self.waveformImageViewMask.fadeIn(0.5) { finsihed in
                                self.waveformImageViewMask.waveformAudioURL = self.audioManager.lastRecordedAudioPath
                            }
                            
                            self.recordingNameField.fadeIn(0.5) { finished in
                                self.recordingNameField.isEnabled = true
                                
                                self.recordingNameField.text = self.audioManager.lastRecordedAudioPath?.lastPathComponent
                            }
                            
                            self.copyButton.fadeIn(0.5) { finished in
                                self.copyButton.isEnabled = true
                            }
                        }
                    }
                }
                
                break
            default:
                break
            }
        }
    }
    
    func didAllowRecording(manager: AudioManager, flag: Bool) {
        if !flag {
            recordButton.endRecording()
            showAlert(message: "Access to microphone is denied. To enable it again go to Settings -> Vail!")
        }
    }
    
    func didUpdateRecordingProgress(manager: AudioManager, progress: Double) {
        let linear = 1 - pow(10, manager.lastAveragePower / 20)
        
        waveformView.add(samples: [linear, linear])
    }
}

extension RecordingViewController: AudioManagerPlaybackDelegate {
    func didFinishPlayingSuccessfully(manager: AudioManager, flag: Bool) {
        if flag {
            playButton.setMode(.play)
        }
        
        recordTimer.invalidate()
    }
    
    func didUpdatePlayingProgress(manager: AudioManager, progress: Double) {
        guard progress > 0 else {
            return
        }
        
        let newWidth = Double(waveformImageView.frame.width) * progress
        let maskRect = CGRect(x: 0.0, y: 0.0, width: newWidth, height: Double(waveformImageView.frame.height))
        
        let path = CGPath(rect: maskRect, transform: nil)
        (waveformImageViewMask.layer.mask as? CAShapeLayer)?.path = path
    }
}

extension RecordingViewController: RecordButtonDelegate {
    func tapButton(isRecording: Bool) {
        do {
            if isRecording {
                playButton.isEnabled = false
                stopButton?.isEnabled = false
                
                recordTimer?.invalidate()
                
                audioFileDuration = 0.0
                
                if recordSeconds > 0.0 {
                    recordSeconds = 0.0
                }
                
                timeLabel.text = "00:00"
                
                waveformImageView.fadeOut(0.5) { [weak waveformImageView] finished in
                    if let waveformImageView {
                        waveformImageView.reset()
                    }
                }
                
                waveformImageViewMask.fadeOut(0.5) { [weak self] finished in
                    if finished, let self {
                        self.waveformImageViewMask.reset()
                        self.waveformView.fadeIn(0.5)
                    }
                }
                
                recordingNameField.fadeOut(0.5) { [weak recordingNameField] finished in
                    if finished, let recordingNameField {
                        recordingNameField.text = nil
                        recordingNameField.isEnabled = false
                    }
                }
                
                copyButton.fadeOut(0.5) { [weak copyButton] finished in
                    if finished, let copyButton {
                        copyButton.isEnabled = false
                    }
                }
                
                if audioManager.playing {
                    playButton.setMode(.play)
                    audioManager.stopPlaying()
                }
                
                audioManager.startRecording { [weak self] error in
                    
                    self?.recordTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
                        guard let self else {
                            return
                        }
                        
                        self.recordSeconds += 1
                        
                        self.timeLabel.text = self.timeString(time: self.recordSeconds)
                    })
                    
                    
                    guard let self, let error else {
                        return
                    }
                    
                    self.recordButton.endRecording()
                    
                    self.recordTimer.invalidate()
                    
                    self.showAlert(message: error.localizedDescription)
                }
            } else {
                try audioManager.stopRecording()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.copyButtonTapHandler(sender: UIButton())
                }
                print("Stop recording!");
            }
        } catch let error {
            showAlert(message:error.localizedDescription)
        }
    }
}

