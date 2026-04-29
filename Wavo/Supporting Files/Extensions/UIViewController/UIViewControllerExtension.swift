//
//  UIViewControllerExtension.swift
//  Vial
//
//  Created by Steliyan Hadzhidenev on 26.11.22.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showAlert(withTitle title: String? = nil, message: String, dismissButtonTitle: String = "Ok", additionalAction: UIAlertAction? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: dismissButtonTitle, style: .default)
        alert.addAction(dismissAction)
        
        if let additionalAction {
            alert.addAction(additionalAction)
        }
        
        present(alert, animated: true)
    }
    
    func showToast(message: String, seconds: Double) {
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = .clear
        alert.view.alpha = 0.5
        alert.view.layer.cornerRadius = 15
        
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)
        }
    }
}
