//
//  RecordNameView.swift
//  Vial
//
//  Created by Steliyan Hadzhidenev on 27.11.22.
//

import UIKit.UITextField

class RecordNameView: UITextField {
    
    // MARK: - Singleton properties
    
    // MARK: - Static properties
    
    // MARK: - Public properties
    
    // MARK: - Public methods
    
    // MARK: - Initialize/Lifecycle methods
    
    // MARK: - Override methods
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    // MARK: - Private properties
    
    private let padding = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
    
    // MARK: - Private methods
}
