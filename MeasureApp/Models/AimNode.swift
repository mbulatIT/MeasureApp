//
//  File.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 18.03.21.
//

import Foundation
import ARKit

final class AimNode: SCNNode {
    
    private let aimImageName = "aim_icon"
    private let spinAnimationKey = "spin around"
    private let nodeZAlign: SCNNode
    
    /// Alignment in the real world
    public var alignment: ARPlaneAnchor.Alignment {
        willSet {
            if newValue != alignment {
                updateAlignment(newValue)
            }
        }
    }
    
    /// Create flat aim node at position with given size and alignment
    /// - Parameter position: Position of node
    /// - Parameter size: Size of node in meters
    /// - Parameter alignment: Alignment of node in the real world
    init(position: SCNVector3, size: CGFloat, alignment: ARPlaneAnchor.Alignment) {
        self.alignment = alignment
        nodeZAlign = SCNNode()
        super.init()

        self.position = position

        updateAlignment(alignment)
        
        let box = SCNBox(width: size, height: size, length: 0, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: aimImageName)
        box.materials = [material]
        
        let boxNode = SCNNode(geometry: box)
        nodeZAlign.addChildNode(boxNode)
        addChildNode(nodeZAlign)
    }
    
    /// Start rotating animation of the aim node
    public func startAnimation() {
        startAnimation(with: alignment)
    }
    
    /// Stop rotating animation of the aim node
    public func stopAnimation() {
        removeAnimation(forKey: spinAnimationKey)
    }
    
    private func startAnimation(with alignment: ARPlaneAnchor.Alignment) {
        let spin = CABasicAnimation(keyPath: "rotation")
        spin.duration = 4
        spin.repeatCount = .infinity
        switch alignment {
        case .horizontal:
            spin.fromValue = NSValue(scnVector4: SCNVector4(0, 1, 0, 0))
            spin.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, CGFloat(2) * .pi))
        case .vertical:
            spin.fromValue = NSValue(scnVector4: SCNVector4(0, 0, 1, 0))
            spin.toValue = NSValue(scnVector4: SCNVector4(0, 0, 1, CGFloat(2) * .pi))
        default:
            return
        }
        addAnimation(spin, forKey: spinAnimationKey)
    }
    
    private func updateAlignment(_ alignment: ARPlaneAnchor.Alignment) {
        if animationKeys.contains(spinAnimationKey) {
            startAnimation(with: alignment)
        }

        switch alignment {
        case .horizontal:
            nodeZAlign.eulerAngles.x = Float.pi/2
        case .vertical:
            nodeZAlign.eulerAngles.x = 0
        default:
            return
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
