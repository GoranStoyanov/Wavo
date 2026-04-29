//
//  ViewController.swift
//  Vial
//
//  Created by Steliyan Hadzhidenev on 12.11.22.
//

import UIKit
import AVFoundation
import MessageUI
import PlayButton

class RecordingViewController: UIViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0
        let p = Dimensions.Padding

        titleLabel.frame = CGRect(x: p, y: statusBarHeight + p, width: view.bounds.width - p * 2, height: 34)
        subtitleLabel.frame = CGRect(x: p, y: titleLabel.frame.maxY + 4, width: view.bounds.width - p * 2, height: 18)
        mailContentButton.frame = CGRect(x: view.bounds.width - p - 150, y: statusBarHeight + p, width: 150, height: 36)

        let containerWidth = view.bounds.width - p * 2
        waveformContainer.frame = CGRect(x: p, y: subtitleLabel.frame.maxY + p * 2, width: containerWidth, height: Dimensions.WaveformHeight + p * 2)
        waveformView.frame = CGRect(x: 0, y: p, width: containerWidth, height: Dimensions.WaveformHeight)
        waveformImageView.frame = waveformView.frame
        waveformImageViewMask.frame = waveformView.frame
        let containerHeight = Dimensions.WaveformHeight + p * 2
        emptyStateLabel.frame = CGRect(x: p, y: containerHeight / 2 - 22, width: containerWidth - p * 2, height: 44)

        timeLabel.frame = CGRect(x: p, y: waveformContainer.frame.maxY + p, width: view.bounds.width - p * 2, height: 28)

        let controlsWidth = buttonSize.width * 2 + p * 4
        playButton.frame = CGRect(x: view.bounds.midX - controlsWidth / 2, y: timeLabel.frame.maxY + p, width: buttonSize.width, height: buttonSize.height)
        recordButton.frame = CGRect(x: playButton.frame.maxX + p * 2, y: playButton.frame.minY, width: buttonSize.width, height: buttonSize.height)
        recordButton.layer.cornerRadius = buttonSize.height / 2

        recordingNameField.frame = CGRect(x: p, y: recordButton.frame.maxY + p, width: view.bounds.width - p * 2, height: 46)
        copyButton.frame = CGRect(x: p, y: recordingNameField.frame.maxY + p, width: view.bounds.width - p * 2, height: Dimensions.ActionButtonHeight)
        sendEmailButton.frame = CGRect(x: p, y: copyButton.frame.maxY + p, width: view.bounds.width - p * 2, height: Dimensions.ActionButtonHeight)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }

    // MARK: - Private properties

    private struct Palette {
        static let background = UIColor.systemBackground
        static let surface = UIColor.secondarySystemBackground
        static let accent = UIColor.systemRed
        static let playback = UIColor.systemTeal
        static let primary = UIColor.label
        static let secondary = UIColor.secondaryLabel
    }

    private struct Dimensions {
        static let Padding = CGFloat(16.0)
        static let WaveformHeight = CGFloat(160.0)
        static let ActionButtonHeight = CGFloat(50.0)
    }

    private var buttonSize: CGSize {
        UIDevice.current.userInterfaceIdiom == .pad
            ? CGSize(width: 80.0, height: 80.0)
            : CGSize(width: 52.0, height: 52.0)
    }

    private var titleLabel: UILabel! {
        didSet {
            titleLabel.text = "Wavo Voice"
            titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
            titleLabel.textColor = Palette.primary
            view.addSubview(titleLabel)
        }
    }

    private var subtitleLabel: UILabel! {
        didSet {
            subtitleLabel.text = "Say it. Send it."
            subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
            subtitleLabel.textColor = Palette.secondary
            view.addSubview(subtitleLabel)
        }
    }

    private var waveformContainer: UIView! {
        didSet {
            waveformContainer.backgroundColor = Palette.surface
            waveformContainer.layer.cornerRadius = 16
            waveformContainer.clipsToBounds = true
            view.addSubview(waveformContainer)
        }
    }

    private var waveformView: WaveformLiveView! {
        didSet {
            waveformView.configuration = waveformView.configuration.with(
                style: .striped(.init(color: Palette.accent, width: 3, spacing: 3)),
                verticalScalingFactor: 2.0
            )
            waveformView.shouldDrawSilencePadding = false
            waveformView.backgroundColor = .clear
            waveformContainer.addSubview(waveformView)
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
            recordButton.backgroundColor = Palette.surface
            recordButton.layer.cornerRadius = buttonSize.height / 2
            view.addSubview(recordButton)
        }
    }

    private var playButton: PlayButton! {
        didSet {
            playButton.isEnabled = false
            playButton.tintColor = Palette.primary
            playButton.setMode(.play, animated: false)
            playButton.addTarget(self, action: #selector(playButtonTapHandler(sender:)), for: .touchUpInside)
            view.addSubview(playButton)
        }
    }

    private var stopButton: PlayButton! {
        didSet {
            stopButton.isEnabled = false
            stopButton.tintColor = Palette.primary
            stopButton.setMode(.stop, animated: false)
            stopButton.addTarget(self, action: #selector(stopButtonTapHandler(sender:)), for: .touchUpInside)
            view.addSubview(stopButton)
        }
    }

    private var waveformImageView: WaveformImageView! {
        didSet {
            waveformImageView.configuration = Waveform.Configuration(
                backgroundColor: .clear,
                style: .striped(.init(color: Palette.accent, width: 3, spacing: 3)),
                verticalScalingFactor: 0.5
            )
            waveformImageView.alpha = 0.0
            waveformContainer.addSubview(waveformImageView)
        }
    }

    private var waveformImageViewMask: WaveformImageView! {
        didSet {
            waveformImageViewMask.configuration = Waveform.Configuration(
                backgroundColor: .clear,
                style: .striped(.init(color: Palette.playback, width: 3, spacing: 3)),
                verticalScalingFactor: 0.5
            )
            waveformImageViewMask.alpha = 0.0
            let mask = CAShapeLayer()
            mask.path = CGPath(rect: .zero, transform: nil)
            waveformImageViewMask.layer.mask = mask
            waveformContainer.addSubview(waveformImageViewMask)
        }
    }

    private var emptyStateLabel: UILabel! {
        didSet {
            emptyStateLabel.text = "Tap ● to record your message"
            emptyStateLabel.font = .systemFont(ofSize: 14)
            emptyStateLabel.textColor = Palette.secondary
            emptyStateLabel.textAlignment = .center
            emptyStateLabel.numberOfLines = 0
            emptyStateLabel.isUserInteractionEnabled = false
            waveformContainer.addSubview(emptyStateLabel)
        }
    }

    private var recordingNameField: RecordNameView! {
        didSet {
            recordingNameField.textColor = Palette.primary
            recordingNameField.attributedPlaceholder = NSAttributedString(
                string: "Recording name...",
                attributes: [.foregroundColor: Palette.secondary]
            )
            recordingNameField.isEnabled = false
            recordingNameField.alpha = 0.0
            recordingNameField.backgroundColor = Palette.surface
            recordingNameField.layer.borderWidth = 0
            recordingNameField.layer.cornerRadius = 10
            view.addSubview(recordingNameField)
        }
    }

    private var copyButton: UIButton! {
        didSet {
            var config = UIButton.Configuration.filled()
            config.title = "Copy to Clipboard"
            config.image = UIImage(systemName: "doc.on.clipboard")
            config.imagePadding = 8
            config.cornerStyle = .large
            config.baseBackgroundColor = Palette.surface
            config.baseForegroundColor = Palette.primary
            copyButton.configuration = config
            copyButton.addTarget(self, action: #selector(copyButtonTapHandler(sender:)), for: .touchUpInside)
            copyButton.isEnabled = false
            copyButton.alpha = 0.0
            view.addSubview(copyButton)
        }
    }

    private var sendEmailButton: UIButton! {
        didSet {
            var config = UIButton.Configuration.filled()
            config.title = "Send as Email"
            config.image = UIImage(systemName: "envelope.fill")
            config.imagePadding = 8
            config.cornerStyle = .large
            config.baseBackgroundColor = Palette.accent
            config.baseForegroundColor = .white
            sendEmailButton.configuration = config
            sendEmailButton.addTarget(self, action: #selector(sendEmailButtonTapHandler(sender:)), for: .touchUpInside)
            sendEmailButton.isEnabled = false
            sendEmailButton.alpha = 0.0
            view.addSubview(sendEmailButton)
        }
    }

    private var timeLabel: UILabel! {
        didSet {
            timeLabel.textAlignment = .center
            timeLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .medium)
            timeLabel.textColor = Palette.secondary
            view.addSubview(timeLabel)
        }
    }

    private var mailContentButton: UIButton! {
        didSet {
            var config = UIButton.Configuration.plain()
            config.title = "Message Body"
            config.image = UIImage(systemName: "square.and.pencil")
            config.imagePadding = 6
            config.baseForegroundColor = Palette.secondary
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
                var attrs = attrs
                attrs.font = UIFont.systemFont(ofSize: 13)
                return attrs
            }
            mailContentButton.configuration = config
            mailContentButton.addTarget(self, action: #selector(showMailContentHandler(sender:)), for: .touchUpInside)
            view.addSubview(mailContentButton)
        }
    }

    private var recordTimer: Timer!
    private var recordSeconds = TimeInterval(0)
    private var audioFileDuration = TimeInterval(0)

    // MARK: - Private methods

    private func setup() {
        view.backgroundColor = Palette.background

        titleLabel = UILabel()
        subtitleLabel = UILabel()
        waveformContainer = UIView()
        waveformView = WaveformLiveView()
        timeLabel = UILabel()
        recordButton = RecordButton()
        playButton = PlayButton()
        audioManager = AudioManager()
        mailContentButton = UIButton()
        waveformImageView = WaveformImageView(frame: .zero)
        waveformImageViewMask = WaveformImageView(frame: .zero)
        emptyStateLabel = UILabel()
        recordingNameField = RecordNameView()
        copyButton = UIButton()
        sendEmailButton = UIButton()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        let spaceKeyCommand = UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spaceKeyPressed(_:)))
        addKeyCommand(spaceKeyCommand)
    }

    @objc func spaceKeyPressed(_ sender: UIKeyCommand) {}

    @objc private func showMailContentHandler(sender: UIButton) {
        let vc = MessageBodyViewController()
        present(vc, animated: true)
    }

    @objc func playButtonTapHandler(sender: PlayButton) {
        if playButton.mode == .play {
            play()
        } else {
            playButton.setMode(.play)
            audioManager.pausePlaying()
            recordTimer.invalidate()
        }
    }

    @objc func stopButtonTapHandler(sender: PlayButton) {
        if audioManager.playing {
            playButton.setMode(.play)
            audioManager.stopPlaying()
            (waveformImageViewMask.layer.mask as? CAShapeLayer)?.path = CGPath(rect: .zero, transform: nil)
            timeLabel.text = "00:00 / \(timeString(time: audioFileDuration))"
            recordSeconds = 0
            recordTimer.invalidate()
        }
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let visibleRectHeight = view.bounds.height - keyboardSize.height
            guard recordingNameField.frame.maxY > visibleRectHeight else { return }
            UIView.animate(withDuration: 0.1) { [weak self] in
                guard let self else { return }
                self.view.frame.origin.y -= (self.recordingNameField.frame.maxY - visibleRectHeight) + Dimensions.Padding * 2
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.view.frame.origin.y = 0.0
            self?.view.layoutIfNeeded()
        }
    }

    @objc private func copyButtonTapHandler(sender: UIButton) {
        if let attachmentUrl = audioManager.lastRecordedAudioPath,
           let attachment = NSItemProvider(contentsOf: attachmentUrl) {
            attachment.suggestedName = recordingNameField.text
            let stringProvider = NSItemProvider(object: (UserDefaults.standard.string(forKey: "kWavoNewMessageBody") ?? "") as NSItemProviderWriting)
            UIPasteboard.general.itemProviders = [stringProvider, attachment]
            showToast(message: "Copied to clipboard", seconds: 1.5)
        }
    }

    @objc private func sendEmailButtonTapHandler(sender: UIButton) {
        guard MFMailComposeViewController.canSendMail() else {
            showAlert(message: "Mail is not configured on this device.")
            return
        }
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setMessageBody(UserDefaults.standard.string(forKey: "kWavoNewMessageBody") ?? "", isHTML: false)
        if let audioUrl = audioManager.lastRecordedAudioPath,
           let audioData = try? Data(contentsOf: audioUrl) {
            let fileName = recordingNameField.text ?? audioUrl.lastPathComponent
            composer.addAttachmentData(audioData, mimeType: "audio/x-m4a", fileName: fileName)
        }
        present(composer, animated: true)
    }

    private func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }

    private func play() {
        do {
            playButton.setMode(.pause)
            try audioManager.playLastRecord()
            recordSeconds = 0.0
            timeLabel.text = "00:00 / \(timeString(time: audioFileDuration))"
            recordTimer.invalidate()
            recordTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self else { return }
                self.recordSeconds += 1
                self.timeLabel.text = "\(self.timeString(time: self.recordSeconds)) / \(self.timeString(time: self.audioFileDuration))"
            }
        } catch {
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

        guard let audioUrl = audioManager.lastRecordedAudioPath else { return }

        let audioAsset = AVURLAsset(url: audioUrl, options: nil)
        audioAsset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            guard let self else { return }

            var error: NSError?
            let status = audioAsset.statusOfValue(forKey: "duration", error: &error)
            guard status == .loaded else { return }

            let duration = audioAsset.duration
            self.audioFileDuration = CMTimeGetSeconds(duration)

            DispatchQueue.main.async {
                self.timeLabel.text = "00:00 / \(self.timeString(time: self.audioFileDuration))"

                self.waveformView.fadeOut(0.5) { [weak self] finished in
                    guard finished, let self else { return }

                    self.waveformView.reset()
                    self.waveformImageView.fadeIn(0.5) { _ in
                        self.waveformImageView.waveformAudioURL = self.audioManager.lastRecordedAudioPath
                    }

                    (self.waveformImageViewMask.layer.mask as? CAShapeLayer)?.path = CGPath(rect: .zero, transform: nil)
                    self.waveformImageViewMask.fadeIn(0.5) { _ in
                        self.waveformImageViewMask.waveformAudioURL = self.audioManager.lastRecordedAudioPath
                    }

                    self.recordingNameField.fadeIn(0.5) { _ in
                        self.recordingNameField.isEnabled = true
                        self.recordingNameField.text = self.audioManager.lastRecordedAudioPath?.lastPathComponent
                    }

                    self.copyButton.fadeIn(0.5) { _ in
                        self.copyButton.isEnabled = true
                    }

                    self.sendEmailButton.fadeIn(0.5) { _ in
                        self.sendEmailButton.isEnabled = true
                    }
                }
            }
        }
    }

    func didAllowRecording(manager: AudioManager, flag: Bool) {
        if !flag {
            recordButton.endRecording()
            showAlert(message: "Access to microphone is denied. To enable it again go to Settings → Wavo.")
        }
    }

    func didUpdateRecordingProgress(manager: AudioManager, progress: Double) {
        let linear = 1 - pow(10, manager.lastAveragePower / 20)
        waveformView.add(samples: [linear, linear])
    }
}

extension RecordingViewController: AudioManagerPlaybackDelegate {
    func didFinishPlayingSuccessfully(manager: AudioManager, flag: Bool) {
        if flag { playButton.setMode(.play) }
        recordTimer.invalidate()
    }

    func didUpdatePlayingProgress(manager: AudioManager, progress: Double) {
        guard progress > 0 else { return }
        let newWidth = Double(waveformImageView.frame.width) * progress
        let maskRect = CGRect(x: 0, y: 0, width: newWidth, height: Double(waveformImageView.frame.height))
        (waveformImageViewMask.layer.mask as? CAShapeLayer)?.path = CGPath(rect: maskRect, transform: nil)
    }
}

extension RecordingViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension RecordingViewController: RecordButtonDelegate {
    func tapButton(isRecording: Bool) {
        do {
            if isRecording {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                playButton.isEnabled = false
                stopButton?.isEnabled = false
                recordTimer?.invalidate()
                audioFileDuration = 0.0
                recordSeconds = 0.0
                timeLabel.text = "00:00"

                emptyStateLabel.fadeOut(0.3)

                waveformImageView.fadeOut(0.5) { [weak waveformImageView] _ in
                    waveformImageView?.reset()
                }

                waveformImageViewMask.fadeOut(0.5) { [weak self] finished in
                    guard finished, let self else { return }
                    self.waveformImageViewMask.reset()
                    self.waveformView.fadeIn(0.5)
                }

                recordingNameField.fadeOut(0.5) { [weak recordingNameField] finished in
                    guard finished, let recordingNameField else { return }
                    recordingNameField.text = nil
                    recordingNameField.isEnabled = false
                }

                copyButton.fadeOut(0.5) { [weak copyButton] finished in
                    guard finished, let copyButton else { return }
                    copyButton.isEnabled = false
                }

                sendEmailButton.fadeOut(0.5) { [weak sendEmailButton] finished in
                    guard finished, let sendEmailButton else { return }
                    sendEmailButton.isEnabled = false
                }

                if audioManager.playing {
                    playButton.setMode(.play)
                    audioManager.stopPlaying()
                }

                audioManager.startRecording { [weak self] error in
                    self?.recordTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                        guard let self else { return }
                        self.recordSeconds += 1
                        self.timeLabel.text = self.timeString(time: self.recordSeconds)
                    }

                    guard let self, let error else { return }
                    self.recordButton.endRecording()
                    self.recordTimer.invalidate()
                    self.showAlert(message: error.localizedDescription)
                }
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                try audioManager.stopRecording()
            }
        } catch {
            showAlert(message: error.localizedDescription)
        }
    }
}
