//
//  PointNode.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 18.03.21.
//

import Foundation
import SceneKit

final class PointNode: SCNNode {

    /// Creates and returns a point node from the given position, radius and color.
    /// - Parameter  position: Position of point in real world.
    /// - Parameter  radius: Radius of point node in meters.
    /// - Parameter color: Color to fill point.
    init(position: SCNVector3, radius: CGFloat, color: UIColor = .white) {
        super.init()
        geometry = SCNSphere(color: color, radius: radius)
        self.position = position
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
