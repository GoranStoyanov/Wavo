//
//  Wafevorm.swift
//  Vial
//
//  Created by Steliyan Hadzhidenev on 24.11.22.
//

import Foundation
import UIKit

protocol WaveformRenderer {
    func render(samples: [Float], on context: CGContext, with configuration: Waveform.Configuration, lastOffset: Int)
    
    func style(context: CGContext, with configuration: Waveform.Configuration)
}

enum Waveform {
    
    /// Position of the drawn waveform
    enum Position: Equatable {
        /// Draws the waveform at the top of the image, such that only the bottom 50% are visible.
        case top
        
        /// Draws the waveform in the middle the image, such that the entire waveform is visible.
        case middle
        
        /// Draws the waveform at the bottom of the image, such that only the top 50% are visible.
        case bottom
        
        /// Draws the waveform at the specified point of the image. `x` and `y` must be within `(0...1)`!
        case origin(CGPoint)
        
        func origin() -> CGPoint {
            switch self {
            case .top:
                return CGPoint(x: 0.5, y: 0.0)
            case .middle:
                return CGPoint(x: 0.5, y: 0.5)
            case .bottom:
                return CGPoint(x: 0.5, y: 1.0)
            case let .origin(point):
                return point
            }
        }
    }
    
    enum Style: Equatable {
        
        struct StripeConfig: Equatable {
            /// Color of the waveform stripes. Default is clear.
            let color: UIColor
            
            /// Width of stripes drawn. Default is `1`
            let width: CGFloat
            
            /// Space between stripes. Default is `5`
            let spacing: CGFloat
            
            /// Line cap style. Default is `.round`.
            let lineCap: CGLineCap
            
            
            init(color: UIColor = .clear, width: CGFloat = 1.0, spacing: CGFloat = 5.0, lineCap: CGLineCap = .round) {
                self.color = color
                self.width = width
                self.spacing = spacing
                self.lineCap = lineCap
            }
        }
        
        case filled(UIColor)
        case outlined(UIColor, CGFloat)
        case gradient([UIColor])
        case gradientOutlined([UIColor], CGFloat)
        case striped(StripeConfig)
    }
    
    
    /// Defines the dampening attributes of the waveform.
    struct Dampening: Equatable {
        enum Sides: Equatable {
            case left
            case right
            case both
        }
        
        /// Determines the percentage of the resulting graph to be dampened.
        ///
        /// Must be within `(0..<0.5)` to leave an undapmened area.
        /// Default is `0.125`
        let percentage: Float
        
        /// Determines which sides of the graph to dampen.
        /// Default is `.both`
        let sides: Sides
        
        /// Easing function to be used. Default is `pow(x, 2)`.
        let easing: (Float) -> Float
        
        init(percentage: Float = 0.125, sides: Sides = .both, easing: @escaping (Float) -> Float = { x in pow(x, 2) }) {
            guard (0...0.5).contains(percentage) else {
                preconditionFailure("dampeningPercentage must be within (0..<0.5)")
            }
            
            self.percentage = percentage
            self.sides = sides
            self.easing = easing
        }
        
        /// Build a new `Waveform.Dampening` with only the given parameters replaced.
        func with(percentage: Float? = nil, sides: Sides? = nil, easing: ((Float) -> Float)? = nil) -> Dampening {
            .init(percentage: percentage ?? self.percentage, sides: sides ?? self.sides, easing: easing ?? self.easing)
        }
        
        static func == (lhs: Waveform.Dampening, rhs: Waveform.Dampening) -> Bool {
            // poor-man's way to make two closures Equatable w/o too much hassle
            let randomEqualitySample = Float.random(in: (0..<Float.greatestFiniteMagnitude))
            return lhs.percentage == rhs.percentage && lhs.sides == rhs.sides && lhs.easing(randomEqualitySample) == rhs.easing(randomEqualitySample)
        }
    }
    
    /// Allows customization of the waveform output image.
    struct Configuration: Equatable {
        static func == (lhs: Waveform.Configuration, rhs: Waveform.Configuration) -> Bool {
            return lhs.size == rhs.size && lhs.backgroundColor == rhs.backgroundColor && lhs.style == rhs.style && lhs.dampening == rhs.dampening && lhs.position == rhs.position && lhs.scale == rhs.scale && lhs.verticalScalingFactor == rhs.verticalScalingFactor && lhs.shouldAntialias == rhs.shouldAntialias
        }
        
        /// Desired output size of the waveform image, works together with scale. Default is `.zero`.
        let size: CGSize
        
        /// Background color of the waveform, defaults to `clear`.
        let backgroundColor: UIColor
        
        /// Waveform drawing style, defaults to `.gradient`.
        let style: Style
        
        /// *Optional* Waveform dampening, defaults to `nil`.
        let dampening: Dampening?
        
        /// Waveform drawing position, defaults to `.middle`.
        let position: Position
        
        /// Scale (@2x, @3x, etc.) to be applied to the image, defaults to `UIScreen.main.scale`.
        let scale: CGFloat
        
        /**
         Vertical scaling factor. Default is `0.95`, leaving a small vertical padding.
         The `verticalScalingFactor` describes the maximum vertical amplitude
         of the envelope being drawn in relation to its view's (image's) size.
         * `0`: the waveform has no vertical amplitude and is just a line.
         * `1`: the waveform uses the full available vertical space.
         * `> 1`: louder waveform samples will extend out of the view boundaries and clip.
         */
        let verticalScalingFactor: CGFloat
        
        /// Waveform antialiasing. If enabled, may reduce overall opacity. Default is `false`.
        let shouldAntialias: Bool
        
        var shouldDampen: Bool {
            dampening != nil
        }
        
        init(size: CGSize = .zero,
             backgroundColor: UIColor = UIColor.clear,
             style: Style = .gradient([UIColor.black, UIColor.gray]),
             dampening: Dampening? = nil,
             position: Position = .middle,
             scale: CGFloat = UIScreen.main.scale,
             verticalScalingFactor: CGFloat = 0.95,
             shouldAntialias: Bool = false) {
            guard verticalScalingFactor > 0 else {
                preconditionFailure("verticalScalingFactor must be greater 0")
            }
            
            self.backgroundColor = backgroundColor
            self.style = style
            self.dampening = dampening
            self.position = position
            self.size = size
            self.scale = scale
            self.verticalScalingFactor = verticalScalingFactor
            self.shouldAntialias = shouldAntialias
        }
        
        /// Build a new `Waveform.Configuration` with only the given parameters replaced.
        func with(size: CGSize? = nil,
                  backgroundColor: UIColor? = nil,
                  style: Style? = nil,
                  dampening: Dampening? = nil,
                  position: Position? = nil,
                  scale: CGFloat? = nil,
                  verticalScalingFactor: CGFloat? = nil,
                  shouldAntialias: Bool? = nil
        ) -> Configuration {
            Configuration(
                size: size ?? self.size,
                backgroundColor: backgroundColor ?? self.backgroundColor,
                style: style ?? self.style,
                dampening: dampening ?? self.dampening,
                position: position ?? self.position,
                scale: scale ?? self.scale,
                verticalScalingFactor: verticalScalingFactor ?? self.verticalScalingFactor,
                shouldAntialias: shouldAntialias ?? self.shouldAntialias
            )
        }
    }
}
