//
//  CanvasView.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 21.03.21.
//

import UIKit

class CanvasView: UIView {
    
    private var polygonsDrawData: [PolygonDrawData] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    var pointRadius: CGFloat = 3 {
        didSet {
            setNeedsDisplay()
        }
    }
    var lineWidth: CGFloat = 3 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var textColor: UIColor = .white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var textSize: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private let textAnimationSpeed: CGFloat = 250
    private let textAnimationAcceleration: CGFloat = -75

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(lineWidth)
        context.setFillColor(UIColor.white.cgColor)

        polygonsDrawData.forEach({
            self.drawPoints(context, polygonDrawData: $0)
            self.drawLines(context, polygonDrawData: $0)
            self.drawPolygon($0, context: context)
        })
    }
    
    // Temporary work only wwith one polygon
    func setPolygonDrawData(_ drawData: PolygonDrawData) {
        if let polygon = polygonsDrawData.first(where: { $0.id == drawData.id }) {
            polygon.update(with: drawData)
            setNeedsDisplay()
        } else {
            polygonsDrawData.append(drawData)
        }
    }

    func clear() {
        polygonsDrawData.removeAll()
    }
    
    
    
    private func setupContext(_ context: CGContext) {
        context.setLineWidth(lineWidth)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setFillColor(UIColor.white.cgColor)
    }

}


// MARK: - Draw methods

extension CanvasView {
    
    private func drawLines(_ context: CGContext, polygonDrawData: PolygonDrawData) {

        polygonDrawData.lines.forEach({
            context.move(to: $0.startPoint)
            context.addLine(to:$0.endPoint)
            context.drawPath(using: .stroke)
            if polygonDrawData.isPolygonFinished == false {
                let center = smartCenter(startPoint: $0.startPoint, endPoint: $0.endPoint)
                var point = center
                if $0.isAnimationFinished == false {
                    point = textAnimationPoint(line: $0, center: center)
                }
                drawText(text: String(format: "%.2f cm", $0.worldLenght * 100),
                         point: point,
                         angle: $0.angle, offset: true,
                         context: context)
            }
        })
        if let aimLine = polygonDrawData.aimLine {
            context.move(to: aimLine.startPoint)
            context.addLine(to: aimLine.endPoint)
            context.drawPath(using: .stroke)
            drawText(text: String(format: "%.2f cm", aimLine.worldLenght * 100),
                     point: aimLine.endPoint, angle: 0, offset: true,
                     context: context)
        }
    }

    
    private func drawPoints(_ context: CGContext, polygonDrawData: PolygonDrawData) {
        if let firstPoint = polygonDrawData.firstPoint {
            let circleCenter = CGPoint(x: firstPoint.x - pointRadius, y: firstPoint.y - pointRadius)
            context.addEllipse(in: rectForCircle(point: circleCenter, pointRadius: pointRadius))
        }
        var lines = polygonDrawData.lines
        if polygonDrawData.isPolygonFinished {
            lines = polygonDrawData.lines.dropLast()
        }
        lines.map({ line -> CGRect in
            let point = CGPoint(x: line.endPoint.x - pointRadius, y: line.endPoint.y - pointRadius)
            return rectForCircle(point: point, pointRadius: pointRadius)
        }).forEach({
            context.addEllipse(in: $0)
        })

        context.drawPath(using: .eoFillStroke)
    }
    
    private func drawPolygon(_ polygon: PolygonDrawData, context: CGContext) {
        if polygon.isPolygonFinished,
           let area = polygon.area,
           let center = polygon.center {
            drawText(text: String(format: "%.3f m²", area), point: center, angle: 0, offset: true, context: context, arrow: false)
        }
    }

    private func drawText(text: String, point: CGPoint, angle: CGFloat, offset: Bool, context: CGContext, arrow: Bool = true) {
        let attributes: [NSAttributedString.Key : Any] = [.foregroundColor: textColor,
                                                          .font: UIFont.systemFont(ofSize: textSize)]
        context.drawStringWithBasePoint(text, basePoint: point, angle: angle, attributes: attributes, offset: offset, arrow: arrow)
        setupContext(context)
    }
}


// MARK: - Calculation methods

extension CanvasView {
    
    private func textAnimationPoint(line: LineDrawData, center: CGPoint) -> CGPoint {
        let time = CGFloat(Date().timeIntervalSince(line.createdDate))
        let animationLenght = textAnimationSpeed * time + textAnimationAcceleration * time * time / 2
        let maxLenght = line.endPoint.distance(to: center)
        if animationLenght > maxLenght {
            line.isAnimationFinished = true
            return center
        } else {
            var dy = sin(line.angle) * animationLenght
            var dx = cos(line.angle) * animationLenght
            if line.startPoint.x > line.endPoint.x {
                dx *= -1
                dy *= -1
            }
            return CGPoint(x: line.endPoint.x - dx, y: line.endPoint.y - dy)
        }
    }

    private func smartCenter(startPoint: CGPoint, endPoint: CGPoint) -> CGPoint {
        let leftPoint = startPoint.x < endPoint.x ? startPoint : endPoint
        let rightPoint = startPoint.x > endPoint.x ? startPoint : endPoint
        let upPoint = startPoint.y < endPoint.y ? startPoint : endPoint
        let downPoint = startPoint.y > endPoint.y ? startPoint : endPoint
        var newStartPoint = startPoint
        var newEndPoint = endPoint
        if let leftIntersection = linesIntersection(start1: startPoint,
                                                    end1: endPoint,
                                                    start2: .zero,
                                                    end2: CGPoint(x: 0, y: frame.height)) {
            if leftPoint == startPoint {
                newStartPoint = leftIntersection
            } else {
                newEndPoint = leftIntersection
            }
        }
        if let rightIntersection = linesIntersection(start1: startPoint,
                                                    end1: endPoint,
                                                    start2: CGPoint(x: frame.width, y: 0),
                                                    end2: CGPoint(x: frame.width, y: frame.height)) {
            if rightPoint == startPoint {
                newStartPoint = rightIntersection
            } else {
                newEndPoint = rightIntersection
            }
        }
        if let upIntersection = linesIntersection(start1: startPoint,
                                                    end1: endPoint,
                                                    start2: .zero,
                                                    end2: CGPoint(x: frame.width, y: 0)) {
            if upPoint == startPoint {
                newStartPoint = upIntersection
            } else {
                newEndPoint = upIntersection
            }
        }
        if let downIntersection = linesIntersection(start1: startPoint,
                                                    end1: endPoint,
                                                    start2: CGPoint(x: 0, y: frame.height),
                                                    end2: CGPoint(x: frame.width, y: frame.height)) {
            if downPoint == startPoint {
                newStartPoint = downIntersection
            } else {
                newEndPoint = downIntersection
            }
        }
        return centerBetween(firstPoint: newStartPoint, lastPoint: newEndPoint)
    }

    private func linesIntersection(start1: CGPoint, end1: CGPoint, start2: CGPoint, end2: CGPoint) -> CGPoint? {
        let delta1x = end1.x - start1.x
        let delta1y = end1.y - start1.y
        let delta2x = end2.x - start2.x
        let delta2y = end2.y - start2.y
        let determinant = delta1x * delta2y - delta2x * delta1y
        
        if abs(determinant) < 0.0001 {
            return nil
        }
        

        let ab = ((start1.y - start2.y) * delta2x - (start1.x - start2.x) * delta2y) / determinant
        
        if ab > 0 && ab < 1 {
            let cd = ((start1.y - start2.y) * delta1x - (start1.x - start2.x) * delta1y) / determinant
            
            if cd > 0 && cd < 1 {
                let intersectX = start1.x + ab * delta1x
                let intersectY = start1.y + ab * delta1y
                return CGPoint(x: intersectX, y: intersectY)
            }
        }

        return nil
    }
    
    private func rectForCircle(point: CGPoint, pointRadius: CGFloat) -> CGRect {
        let size = CGSize(width: pointRadius * 2, height: pointRadius * 2)
        return CGRect(origin: point, size: size)
    }
    
    private func centerBetween(firstPoint: CGPoint, lastPoint: CGPoint) -> CGPoint {
        return CGPoint(x: (firstPoint.x + lastPoint.x) / 2, y: (firstPoint.y + lastPoint.y) / 2)
    }
    
}
