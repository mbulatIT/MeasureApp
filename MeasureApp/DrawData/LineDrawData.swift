//
//  FlatLine.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 21.03.21.
//

import UIKit

class LineDrawData {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var center: CGPoint
    var worldLenght: CGFloat
    var isAnimationFinished: Bool
    var createdDate: Date
    let id: String
    
    var angle: CGFloat {
        let dx = startPoint.x - endPoint.x
        let dy = startPoint.y - endPoint.y
        return atan(dy / dx)
    }
    
    init(id: String, startPoint: CGPoint, endPoint: CGPoint, center: CGPoint, worldLenght: CGFloat) {
        self.id = id
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.center = center
        self.worldLenght = worldLenght
        self.isAnimationFinished = false
        self.createdDate = Date()
    }
    
    func merge(with line: LineDrawData) {
        guard id == line.id else {
            return
        }
        
        self.startPoint = line.startPoint
        self.endPoint = line.endPoint
        self.center = line.center
        self.worldLenght = line.worldLenght
    }
}
