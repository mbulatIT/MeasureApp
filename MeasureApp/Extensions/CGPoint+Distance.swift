//
//  CGPoint+Distance.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 24.03.21.
//

import CoreGraphics

extension CGPoint {

    func distance(to destination: CGPoint) -> CGFloat {
        let dx = destination.x - x
        let dy = destination.y - y
        return CGFloat(sqrt(dx*dx + dy*dy))
    }
}
