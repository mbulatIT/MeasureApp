//
//  Line.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 22.03.21.
//

import SceneKit

class Line {
    let startPoint: SCNVector3
    let endPoint: SCNVector3
    let id: String
    
    var center: SCNVector3 {
        SCNVector3((startPoint.x + endPoint.x) / 2,
                   (startPoint.y + endPoint.y) / 2,
                   (startPoint.z + endPoint.z) / 2)
    }
    
    var lenght: CGFloat {
        startPoint.distance(to: endPoint)
    }
    
    init(startPoint: SCNVector3, endPoint: SCNVector3) {
        self.id = UUID().uuidString
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
    
}
