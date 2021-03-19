//
//  SCNSphere+Init.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 14.03.21.
//

import Foundation
import UIKit
import SceneKit

extension SCNSphere {
    convenience init(color: UIColor, radius: CGFloat) {
        self.init(radius: radius)
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        materials = [material]
    }
}
