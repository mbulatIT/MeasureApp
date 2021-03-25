//
//  CGContext+DrawString.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 24.03.21.
//

import UIKit

extension CGContext {
    func drawStringWithBasePoint(_ string: String,
                                 basePoint: CGPoint,
                                 angle: CGFloat,
                                 attributes: [NSAttributedString.Key : Any] = [:],
                                 offset: Bool = true,
                                 backgroundColor: UIColor = #colorLiteral(red: 0, green: 0.6676149964, blue: 0.9526837468, alpha: 1),
                                 arrow: Bool = true) {
        let textSize: CGSize = string.size(withAttributes: attributes)
        let t: CGAffineTransform = CGAffineTransform(translationX: basePoint.x, y: basePoint.y)
        let r: CGAffineTransform = CGAffineTransform(rotationAngle: angle)
        self.concatenate(t)
        self.concatenate(r)
        
        var yOffset: CGFloat = -textSize.height / 2
        if offset {
            yOffset = -textSize.height * 1.75
        }
        let origin = CGPoint(x: -textSize.width / 2, y: yOffset)
        let borderOrigin = CGPoint(x: origin.x * 1.5, y: origin.y * 1.25)
        let borderSize = CGSize(width: textSize.width * 1.5, height: textSize.height * 1.85)
        let cornerRadius = textSize.height / 3
        let borderRect = CGRect(origin: borderOrigin, size: borderSize)
        self.addPath(CGPath(roundedRect: borderRect,
                               cornerWidth: cornerRadius,
                               cornerHeight: cornerRadius,
                               transform: nil))
        if arrow {
            self.move(to: CGPoint(x: borderRect.midX - borderRect.height / 4, y: borderRect.maxY))
            self.addLine(to: CGPoint(x: borderRect.midX + borderRect.height / 4, y: borderRect.maxY))
            self.addLine(to: CGPoint(x: borderRect.midX, y: borderRect.maxY + borderRect.height / 4))
            self.addLine(to: CGPoint(x: borderRect.midX - borderRect.height / 4, y: borderRect.maxY))
        }
        self.setFillColor(backgroundColor.cgColor)
        self.drawPath(using: .eoFill)
        string.draw(at: origin, withAttributes: attributes)
        self.concatenate(r.inverted())
        self.concatenate(t.inverted())
    }
}
