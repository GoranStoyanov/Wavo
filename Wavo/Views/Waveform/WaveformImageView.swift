//
//  WaveformImageView.swift
//  Vial
//
//  Created by Steliyan Hadzhidenev on 27.11.22.
//

import UIKit

class WaveformImageView: UIImageView {
    
    private let waveformImageDrawer = WaveformImageDrawer()

    var configuration: Waveform.Configuration! {
        didSet {
            updateWaveform()
        }
    }

    public var waveformAudioURL: URL? {
        didSet {
            updateWaveform()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configuration = Waveform.Configuration(size: frame.size)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configuration = Waveform.Configuration()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateWaveform()
    }

    /// Clears the audio data, emptying the waveform view.
    func reset() {
        waveformAudioURL = nil
        image = nil
    }
}

private extension WaveformImageView {
    func updateWaveform() {
        guard let audioURL = waveformAudioURL else { return }
        waveformImageDrawer.waveformImage(
            fromAudioAt: audioURL,
            with: configuration.with(size: bounds.size),
            qos: .userInteractive
        ) { image in
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
}
