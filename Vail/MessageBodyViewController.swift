//
//  MessageBodyViewController.swift
//  Vail
//
//  Created by Steliyan Hadzhidenev on 9.12.22.
//

import UIKit

class MessageBodyViewController: UIViewController {
    
    // MARK: - Singleton properties
    
    // MARK: - Static properties
    
    // MARK: - Public properties
    
    // MARK: - Public methods
    
    // MARK: - Initialize/Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("shit!")
        setup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !messageBodyTextView.text.isEmpty {
            UserDefaults.standard.set(messageBodyTextView.text, forKey: "kVailNewMessageBody")
        }
    }
    
    // MARK: - Override methods
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        backButton.frame = CGRect(x: 16.0, y: 8.0, width: 44.0, height: 44.0)
        
        messageBodyTextView.frame = CGRect(x: 8.0, y: 8.0 + backButton.frame.maxY, width: view.bounds.width - 16.0, height: view.bounds.height * 0.25)
    }
    
    // MARK: - Private properties
    
    private var messageBodyTextView: UITextView! {
        didSet {
            messageBodyTextView.contentInset = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
            messageBodyTextView.layer.cornerRadius = 8.0
            messageBodyTextView.layer.borderColor = UIColor.label.cgColor
            messageBodyTextView.layer.borderWidth = 1.0
            messageBodyTextView.text = UserDefaults.standard.string(forKey: "kVailNewMessageBody") ?? ""
            messageBodyTextView.textColor = .label
            view.addSubview(messageBodyTextView)
        }
    }
    
    private var backButton: UIButton! {
        didSet {
            backButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
            backButton.tintColor = .label
            backButton.addTarget(self, action: #selector(dismiss(sender:)), for: .touchUpInside)
            
            view.addSubview(backButton)
        }
    }
    
    // MARK: - Private methods

    private func setup() {
        messageBodyTextView = UITextView()
        backButton = UIButton()
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
    
    @objc private func dismiss(sender: UIButton) {
        dismiss(animated: true)
    }

}
