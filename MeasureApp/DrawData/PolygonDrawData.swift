//
//  FlatPolygon.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 22.03.21.
//

import UIKit

class PolygonDrawData {
    var isPolygonFinished: Bool
    var lines: [LineDrawData]
    var center: CGPoint?
    var area: CGFloat?
    var firstPoint: CGPoint?
    var aimLine: LineDrawData?
    let id: String
    
    init(id: String, lines: [LineDrawData], firstPoint: CGPoint?, isPolygonFinished: Bool, center: CGPoint?, area: CGFloat?, aimLine: LineDrawData?) {
        self.id = id
        self.isPolygonFinished = isPolygonFinished
        self.lines = lines
        self.center = center
        self.area = area
        self.firstPoint = firstPoint
        self.aimLine = aimLine;
    }
    
    func update(with polygon: PolygonDrawData) {
        self.isPolygonFinished = polygon.isPolygonFinished
        self.center = polygon.center
        self.area = polygon.area
        self.firstPoint = polygon.firstPoint
        self.aimLine = polygon.aimLine
        for line in polygon.lines {
            if let oldLine = self.lines.first(where: { $0.id == line.id }) {
                line.isAnimationFinished = oldLine.isAnimationFinished
                line.createdDate = oldLine.createdDate
            }
        }
        self.lines = polygon.lines
    }
}
