//
//  TextNode.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 15.03.21.
//

import Foundation
import ARKit

final class TextNode: SCNNode {
    private let extrusionDepth: CGFloat = 0.01                  // Text depth
    private let textNodeScale = SCNVector3Make(0.2, 0.2, 0.2)   // Scale applied to node
    private var text: SCNText
    private let nodeZAlign: SCNNode
    
    /// Alignment of text node in real world
    public var alignment: ARPlaneAnchor.Alignment {
        willSet {
            if newValue != alignment {
                updateAlignment(newValue)
            }
        }
    }
    
    /// Text color
    public var color = UIColor.black {
        didSet {
            text.firstMaterial?.diffuse.contents = color
        }
    }
    
    /// Text font
    public var font: UIFont? = UIFont.systemFont(ofSize: 10) {
        didSet {
            text.font = font
        }
    }
    
    /// Create a text node with given string, position and alignment
    /// - Parameter string: Text for text node
    /// - Parameter position: Node position in the real world
    /// - Parameter alignment: Alignment of the node in real world
    init(_ string: String, position: SCNVector3, alignment: ARPlaneAnchor.Alignment) {
        nodeZAlign = SCNNode()
        self.alignment = alignment
        text = SCNText(string: string, extrusionDepth: extrusionDepth)
        super.init()
        self.position = position
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.magenta
        text.materials = [material]
        let textNode = SCNNode()
        textNode.geometry = text
        textNode.simdPivot.columns.3.x = Float((text.boundingBox.min.x +
                                             text.boundingBox.max.x) / 2)

        textNode.simdPivot.columns.3.y = Float((text.boundingBox.min.y +
                                             text.boundingBox.max.y) / 2)
//        if let parentNode = parent {
//            textNode.constraints = [SCNLookAtConstraint(target: parentNode)]
//        }
        let constraint = SCNBillboardConstraint()
        textNode.constraints = [constraint]
        nodeZAlign.addChildNode(textNode)
        updateAlignment(alignment)
//        let max = text!.boundingBox.max
//        let min = text!.boundingBox.min
//        let tx = (max.x - min.x) / 2.0
//        textNode.position = SCNVector3(-tx, 0, 0)
        scale = SCNVector3(0.002, 0.002, 0.002)
        
        self.addChildNode(nodeZAlign)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateAlignment(_ alignment: ARPlaneAnchor.Alignment) {
        switch alignment {
        case .horizontal:
            nodeZAlign.eulerAngles.x = -(Float.pi / 2)
        case .vertical:
            nodeZAlign.eulerAngles.x = 0
        default:
            return
        }
    }
}
