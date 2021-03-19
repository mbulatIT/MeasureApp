//
//  PolygonNode.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 15.03.21.
//

import Foundation
import ARKit

final class PolygonNode: SCNNode {

    private let points: [SCNNode]
    private let alignment: ARPlaneAnchor.Alignment
    private let color: UIColor
    private var textNode: TextNode?
    
    private var isRightDrawn: Bool {
        guard points.count >= 3 else {
            return false
        }
        switch alignment {
        case .horizontal:
            return points[1].position.z > points[2].position.z
        case .vertical:
            return points[1].position.y > points[2].position.y
        default:
            return false
        }
    }
    
    /** Calculate area of polygon*/
    public var area: CGFloat {
        var points2D: [CGPoint] = []
        switch alignment {
        case .horizontal:
            points2D = points.map{CGPoint(x: CGFloat($0.position.x), y: CGFloat($0.position.z))}
        case .vertical:
            points2D = points.map{CGPoint(x: CGFloat($0.position.x), y: CGFloat($0.position.y))}
        default:
            assertionFailure()
        }
        return calculateArea(points: points2D)
    }
    
    private var center: SCNVector3? {
        guard points.isEmpty == false else {
            return nil
        }
        var centerPosition = SCNVector3()
        switch alignment {
        case .horizontal:
            let points2D = points.map{CGPoint(x: CGFloat($0.position.x), y: CGFloat($0.position.z))}
            let center2D = calculateCenter(points: points2D)
            centerPosition = SCNVector3(center2D.x, CGFloat(points.first!.position.y), center2D.y)
        case .vertical:
            let points2D = points.map{CGPoint(x: CGFloat($0.position.x), y: CGFloat($0.position.y))}
            let center2D = calculateCenter(points: points2D)
            centerPosition = SCNVector3(center2D.x, center2D.y, CGFloat(points.first!.position.z))
        default:
            assertionFailure()
        }
        return centerPosition
    }
    

    /// Creates and returns a polygon node from the given points, alignment and color.
    /// - Parameter points: Points that contains points for polygon. Should contain at least 2 points
    /// - Parameter alignment: ARPlaneAnchor.Alignment that specify polygon orientation in real world.
    /// - Parameter color: Color to fill polygon.
    init(points: [SCNNode], alignment: ARPlaneAnchor.Alignment, color: UIColor) {
        self.points = points
        self.alignment = alignment
        self.color = color
        super.init()
        setupPolygon()
        setupAreaTextNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.points = []
        self.alignment = .horizontal
        self.color = .white
        super.init(coder: aDecoder)
    }

    private func calculateCenter(points: [CGPoint]) -> CGPoint {
        var x: CGFloat = 0
        var y: CGFloat = 0
        points.forEach({
            x += $0.x
            y += $0.y
        })
        x /= CGFloat(points.count)
        y /= CGFloat(points.count)
        return CGPoint(x: x, y: y)
    }
    
    private func calculateArea(points: [CGPoint]) -> CGFloat {
        var sum: CGFloat = 0
        for (index, point) in points.enumerated() {
            guard index < points.count - 1 else {
                break
            }
            sum += point.x * points[index + 1].y - points[index + 1].x * point.y
        }
        return abs(sum / 2)
    }
    
    private func setupPolygon() {
        var indices: [Int32] = []
        for index in 0...points.count - 1 {
            indices.append(Int32(index))
        }
        if isRightDrawn {
            indices.reverse()
        }
        indices.insert(Int32(points.count), at: 0)
        let indexData = Data(bytes: indices,
                             count: indices.count * MemoryLayout<Int32>.size)
        let source = SCNGeometrySource(vertices: points.map({$0.position}))
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .polygon,
                                         primitiveCount: 1,
                                         bytesPerIndex: MemoryLayout<Int32>.size)
        let polygon = SCNGeometry(sources: [source], elements: [element])
//        let planeMaterial = SCNMaterial()
//        planeMaterial.diffuse.contents = UIImage(named: "brick_wall_icon")
        polygon.materials = []
        geometry = polygon
    }
    
    
    private func setupAreaTextNode() {
        guard let center = center else {
            return
        }
        let textNode = TextNode(String(format: "%.3f m²", area), position: center, alignment: alignment)
        textNode.color = .purple
        textNode.font = .systemFont(ofSize: 30)
        addChildNode(textNode)
        self.textNode = textNode
    }
}
