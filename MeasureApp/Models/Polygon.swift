//
//  PolygonNode.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 15.03.21.
//

import Foundation
import ARKit

final class Polygon: SCNNode {

    let id: String
    private let points: [SCNVector3]
    private let alignment: ARPlaneAnchor.Alignment
    
    private var isRightDrawn: Bool {
        guard points.count >= 3 else {
            return false
        }
        switch alignment {
        case .horizontal:
            return points[1].z > points[2].z
        case .vertical:
            return points[1].y > points[2].y
        default:
            return false
        }
    }
    
    private var textureCoordinates: [CGPoint] {
        var points2D: [CGPoint] = []
        switch alignment {
        case .horizontal:
            points2D = points.map{CGPoint(x: CGFloat($0.x), y: CGFloat($0.z))}
        case .vertical:
            points2D = points.map{CGPoint(x: CGFloat($0.x), y: CGFloat($0.y))}
        default:
            assertionFailure()
        }
        return calculatetextureCoordinates(points: points2D)
    }
    
    /** Calculate area of polygon*/
    public var area: CGFloat {
        var points2D: [CGPoint] = []
        switch alignment {
        case .horizontal:
            points2D = points.map{CGPoint(x: CGFloat($0.x), y: CGFloat($0.z))}
        case .vertical:
            points2D = points.map{CGPoint(x: CGFloat($0.x), y: CGFloat($0.y))}
        default:
            assertionFailure()
        }
        return calculateArea(points: points2D)
    }
    
    var center: SCNVector3? {
        guard points.isEmpty == false else {
            return nil
        }
        var centerPosition = SCNVector3()
        switch alignment {
        case .horizontal:
            let points2D = points.map{CGPoint(x: CGFloat($0.x), y: CGFloat($0.z))}
            let center2D = calculateCenter(points: points2D)
            centerPosition = SCNVector3(center2D.x, CGFloat(points.first!.y), center2D.y)
        case .vertical:
            let points2D = points.map{CGPoint(x: CGFloat($0.x), y: CGFloat($0.y))}
            let center2D = calculateCenter(points: points2D)
            centerPosition = SCNVector3(center2D.x, center2D.y, CGFloat(points.first!.z))
        default:
            assertionFailure()
        }
        return centerPosition
    }
    

    /// Creates and returns a polygon node from the given points, alignment and color.
    /// - Parameter points: Points that contains points for polygon. Should contain at least 2 points
    /// - Parameter alignment: ARPlaneAnchor.Alignment that specify polygon orientation in real world.
    /// - Parameter color: Color to fill polygon.
    init(points: [SCNVector3], alignment: ARPlaneAnchor.Alignment) {
        self.id = UUID().uuidString
        self.points = points
        self.alignment = alignment
        
        let normalsPerFace = 1

        var indices: [Int32] = [Int32(points.count)]
        points.enumerated().forEach({indices.append(Int32($0.offset))})
        let source = SCNGeometrySource(vertices: points)

        let normals: [SCNVector3] = points.map { [SCNVector3](repeating: $0, count: normalsPerFace) }.flatMap{ $0 }
        let normalSource = SCNGeometrySource(normals: normals)
        let texCoord = SCNGeometrySource(textureCoordinates: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 1), CGPoint(x: 1, y: 1), CGPoint(x: 1, y: 0), CGPoint(x: 0.5, y: 0.5)])

        let data = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)

        let element = SCNGeometryElement(data: data,
                                primitiveType: .polygon,
                               primitiveCount: 1,
                                bytesPerIndex: MemoryLayout<Int32>.size)

        let geometry = SCNGeometry(sources: [source, normalSource, texCoord],
                                  elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear
        material.isDoubleSided = true
            geometry.materials = [material]
        super.init()
        self.geometry = geometry
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyTexture(image: UIImage?) {
        geometry?.firstMaterial?.diffuse.contents = image
    }
    
    private func polygonGeometry() -> SCNGeometry {

        let normalsPerFace = 1

        var indices: [Int32] = [Int32(points.count)]
        points.enumerated().forEach({indices.append(Int32($0.offset))})
        let source = SCNGeometrySource(vertices: points)

        let normals: [SCNVector3] = points.map { [SCNVector3](repeating: $0, count: normalsPerFace) }.flatMap{ $0 }
        let normalSource = SCNGeometrySource(normals: normals)

        let texCoord = SCNGeometrySource(textureCoordinates: textureCoordinates)

        let data = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)

        let element = SCNGeometryElement(data: data,
                                primitiveType: .polygon,
                               primitiveCount: 1,
                                bytesPerIndex: MemoryLayout<Int32>.size)

        let geometry = SCNGeometry(sources: [source, normalSource, texCoord],
                                  elements: [element])

        return geometry
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
    
    private func calculatetextureCoordinates(points: [CGPoint]) -> [CGPoint] {
        guard points.count > 1 else {
            return []
        }
        let pointsSortedByX = points.sorted(by: {$0.x < $1.x})
        let pointsSortedByY = points.sorted(by: {$0.y < $1.y})
        let leftPoint = pointsSortedByX.first!
        let rightPoint = pointsSortedByX.last!
        let downPoint = pointsSortedByY.first!
        let upPoint = pointsSortedByY.last!
        let width = rightPoint.x - leftPoint.x
        let height = upPoint.y - downPoint.y
        return points.map({CGPoint(x: ($0.x - leftPoint.x) / width, y: ($0.y - downPoint.y) / height)})
    }
}
