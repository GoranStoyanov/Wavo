//
//  MessageBodyViewController.swift
//  Vail
//
//  Created by Steliyan Hadzhidenev on 9.12.22.
//

import UIKit

class MessageBodyViewController: UIViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !messageBodyTextView.text.isEmpty {
            UserDefaults.standard.set(messageBodyTextView.text, forKey: "kVailNewMessageBody")
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let p = CGFloat(16)
        backButton.frame = CGRect(x: p, y: 8, width: 44, height: 44)
        titleLabel.frame = CGRect(x: p + 52, y: 8, width: view.bounds.width - (p + 52) * 2, height: 44)
        subtitleLabel.frame = CGRect(x: p, y: backButton.frame.maxY + 8, width: view.bounds.width - p * 2, height: 36)
        messageBodyTextView.frame = CGRect(x: p, y: subtitleLabel.frame.maxY + p, width: view.bounds.width - p * 2, height: view.bounds.height * 0.35)
    }

    // MARK: - Private properties

    private struct Palette {
        static let background = UIColor.systemBackground
        static let surface = UIColor.secondarySystemBackground
        static let primary = UIColor.label
        static let secondary = UIColor.secondaryLabel
    }

    private var titleLabel: UILabel! {
        didSet {
            titleLabel.text = "Message Body"
            titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            titleLabel.textColor = Palette.primary
            titleLabel.textAlignment = .center
            view.addSubview(titleLabel)
        }
    }

    private var subtitleLabel: UILabel! {
        didSet {
            subtitleLabel.text = "This text will be included in every email you send."
            subtitleLabel.font = .systemFont(ofSize: 13)
            subtitleLabel.textColor = Palette.secondary
            subtitleLabel.numberOfLines = 0
            view.addSubview(subtitleLabel)
        }
    }

    private var messageBodyTextView: UITextView! {
        didSet {
            messageBodyTextView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            messageBodyTextView.layer.cornerRadius = 12
            messageBodyTextView.backgroundColor = Palette.surface
            messageBodyTextView.text = UserDefaults.standard.string(forKey: "kVailNewMessageBody") ?? ""
            messageBodyTextView.textColor = Palette.primary
            messageBodyTextView.font = .systemFont(ofSize: 15)
            view.addSubview(messageBodyTextView)
        }
    }

    private var backButton: UIButton! {
        didSet {
            backButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
            backButton.tintColor = Palette.secondary
            backButton.addTarget(self, action: #selector(dismissAction), for: .touchUpInside)
            view.addSubview(backButton)
        }
    }

    // MARK: - Private methods

    private func setup() {
        view.backgroundColor = Palette.background
        titleLabel = UILabel()
        subtitleLabel = UILabel()
        messageBodyTextView = UITextView()
        backButton = UIButton()

        let spaceKeyCommand = UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spaceKeyPressed(_:)))
        addKeyCommand(spaceKeyCommand)
    }

    @objc func spaceKeyPressed(_ sender: UIKeyCommand) {}

    @objc private func dismissAction() {
        dismiss(animated: true)
    }
}
