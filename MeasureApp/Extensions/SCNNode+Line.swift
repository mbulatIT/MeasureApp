//
//  SCNNode+Line.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 14.03.21.
//

import SceneKit

extension SCNNode {
    static func createLineNode(fromNode: SCNNode, toNode: SCNNode, andColor color: UIColor) -> SCNNode {
        let line = lineFrom(vector: fromNode.position, toVector: toNode.position)
        let lineNode = SCNNode(geometry: line)
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = color
        line.materials = [planeMaterial]
        return lineNode
    }
    
    static func createLineNode(from startPosition: SCNVector3, to endPosition: SCNVector3, color: UIColor) -> SCNNode {
        let line = lineFrom(vector: startPosition, toVector: endPosition)
        let lineNode = SCNNode(geometry: line)
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = color
        line.materials = [planeMaterial]
        return lineNode
    }
    
    static func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}
