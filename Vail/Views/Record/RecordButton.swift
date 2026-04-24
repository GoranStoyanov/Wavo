//
//  RecordView.swift
//  Vial
//
//  Created by Steliyan Hadzhidenev on 25.11.22.
//

import Foundation
import UIKit

protocol RecordButtonDelegate: NSObjectProtocol {
    func tapButton(isRecording: Bool)
}

class RecordButton: UIView {
    
    // MARK: - Singleton properties
    
    // MARK: - Static properties
    
    // MARK: - Public properties
    
    weak var delegate: RecordButtonDelegate?
    
    // MARK: - Public methods
    
    func endRecording() {
        roundView.layer.add(recordButtonAnimation(), forKey: "")
        isRecording.toggle()
    }
    
    // MARK: - Initialize/Lifecycle methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    // MARK: - Override methods
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let shapeLayerRadius = min(bounds.width, bounds.height) / 2
        let lineWidth = externalCircleFactor * shapeLayerRadius
        
        shapeLayer.path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY), radius: shapeLayerRadius - lineWidth / 2, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true).cgPath
        shapeLayer.lineWidth = lineWidth
        
        squareSide = roundViewSideFactor * min(bounds.width, bounds.height)
        
        roundView.frame = CGRect(x: bounds.midX - squareSide / 2, y: bounds.midY - squareSide / 2, width: squareSide, height: squareSide)
        roundView.layer.cornerRadius = squareSide / 2
    }
    
    // MARK: - Private properties
    
    private var roundView: UIView! {
        didSet {
            roundView.backgroundColor = .red
            addSubview(roundView)
        }
    }
    
    private var shapeLayer: CAShapeLayer! {
        didSet {
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor = UIColor.red.cgColor
            shapeLayer.opacity = 1.0
            
            layer.addSublayer(shapeLayer)
        }
    }
    
    private let externalCircleFactor: CGFloat = 0.1
    
    private let roundViewSideFactor: CGFloat = 0.8
    
    private var squareSide = CGFloat(0.0)
    
    private(set) var isRecording = false
    
    // MARK: - Private methods
    
    private func setup() {
        roundView = UIView()
        shapeLayer = CAShapeLayer()
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureHandler(sender: ))))
    }
    
    private func recordButtonAnimation() -> CAAnimationGroup {
        
        let transformToStopButton = CABasicAnimation(keyPath: "cornerRadius")
        
        transformToStopButton.fromValue = !isRecording ? squareSide / 2 : 10
        transformToStopButton.toValue = !isRecording ? 10 : squareSide / 2
        
        let toSmallCircle = CABasicAnimation(keyPath: "transform.scale")
        
        toSmallCircle.fromValue = !isRecording ? 1 : 0.65
        toSmallCircle.toValue = !isRecording ? 0.65 : 1
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [transformToStopButton, toSmallCircle]
        animationGroup.duration = 0.25
        animationGroup.fillMode = .both
        animationGroup.isRemovedOnCompletion = false
        
        return animationGroup
        
    }
    
    @objc private func tapGestureHandler(sender: UITapGestureRecognizer) {
        roundView.layer.add(recordButtonAnimation(), forKey: "")
        
        isRecording.toggle()
        
        delegate?.tapButton(isRecording: isRecording)
        
    }
    
}
