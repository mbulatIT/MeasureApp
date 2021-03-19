//
//  LineNode.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 15.03.21.
//

import Foundation
import ARKit

final class LineNode: SCNNode {

    public let startPoint: SCNNode
    public let endPoint: SCNNode
    public var color: UIColor
    private let alignment: ARPlaneAnchor.Alignment
    private let width: CGFloat
    
    /// Lenght of line in meters
    public var lenght: CGFloat {
        var startPoint2D = CGPoint()
        var endPoint2D = CGPoint()
        switch alignment {
        case .horizontal:
            startPoint2D = CGPoint(x: CGFloat(startPoint.position.x), y: CGFloat(startPoint.position.z))
            endPoint2D = CGPoint(x: CGFloat(endPoint.position.x), y: CGFloat(endPoint.position.z))
        case .vertical:
            startPoint2D = CGPoint(x: CGFloat(startPoint.position.x), y: CGFloat(startPoint.position.y))
            endPoint2D = CGPoint(x: CGFloat(endPoint.position.x), y: CGFloat(endPoint.position.y))
        default:
            assertionFailure()
        }
        return flatDistance(startPoint2D, endPoint2D)
    }
    
    /// Create a line point from startPoint to endPoint with given width, color and alignment
    /// - Parameter startPoint: Node for start point of line
    /// - Parameter endPoind: Node for end point of line
    /// - Parameter width: Width of line in meters
    /// - Parameter color: Color of line node
    /// - Parameter alignment: Alignment of node in the real world
    init(from startPoint: SCNNode, to endPoint: SCNNode, width: CGFloat, color: UIColor, alignment: ARPlaneAnchor.Alignment) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.color = color
        self.alignment = alignment
        self.width = width
        super.init()
        setupLine()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.startPoint = SCNNode()
        self.endPoint = SCNNode()
        self.color = .white
        self.alignment = .horizontal
        self.width = 1
        super.init(coder: aDecoder)
    }

    private func setupLine() {
                
        self.position = startPoint.position
        let nodeVector2 = SCNNode()
        nodeVector2.position = endPoint.position
        
        let nodeZAlign = SCNNode()
        nodeZAlign.eulerAngles.x = Float.pi/2
        
        let box = SCNBox(width: width, height: lenght, length: 0.001, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = color
        box.materials = [material]
        
        let nodeLine = SCNNode(geometry: box)
        nodeLine.position.y = Float(-lenght / 2) + 0.001
        nodeZAlign.addChildNode(nodeLine)
        
        self.addChildNode(nodeZAlign)
        
        self.constraints = [SCNLookAtConstraint(target: nodeVector2)]
//        setupLenghtText()
    }
    
    private func flatDistance(_ startPoint: CGPoint, _ endPoint: CGPoint) -> CGFloat {
        return sqrt(pow((startPoint.x - endPoint.x), 2) + pow(startPoint.y - endPoint.y, 2))
    }
    
//    private func setupLenghtText() {
//        let text = String(format: "%.2f cm", lenght * 100)
//        let textNode = TextNode(text, position: endPoint.position, alignment: alignment)
////        textNode.constraints = [SCNLookAtConstraint(target: endPoint)]
//        textNode.font = .systemFont(ofSize: 8)
//
//        addChildNode(textNode)
////        let action = SCNAction.move(to: startPoint.position, duration: 1.5)
////        action.timingMode = .easeInEaseOut
////        textNode.runAction(action)
//    }
}
