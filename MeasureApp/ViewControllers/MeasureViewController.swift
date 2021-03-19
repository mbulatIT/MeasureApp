//
//  MeasureShoeViewController.swift
//  MeasureApp
//
//  Created by Maksim Bulat on 14.03.21.
//

import UIKit
import SceneKit
import ARKit

final class MeasureViewController: UIViewController {
    
    @IBOutlet private weak var sceneView: ARSCNView!
    @IBOutlet private weak var clearButton: UIButton!

    // MARK: Constants
    
    private let pointColor: UIColor = .purple
    private let pointRadius: CGFloat = 0.025
    private let lineWidth: CGFloat = 0.025
    private let aimNodeSize: CGFloat = 0.3
    private let minimumPointsDistance: CGFloat = 0.05
    private let surfaceSearchImageSize: CGFloat = 60
    private let arTextFontSize: CGFloat = 30
    private let frameRate: Double = 20
    private let surfaceSearchImageView = UIImageView()
    private let surfaceSearchAnimationKey = "surfaceSearchAnimation"
    private let surfaceSearchAnimationKeyPath =  "position"
    private let searchSurfaceImageName = "search_icon"
    private let defaultAnimationDuration: Double = 4
    private let polygonColor = #colorLiteral(red: 0.994084537, green: 1, blue: 0.4055556059, alpha: 0.7)
    private let minimumPointsCount = 3
    private var lastPoint: PointNode?
    private var trackedLine: SCNNode?
    private var trackedLineLenghtText: TextNode?
    private var trackedAim:AimNode?
    private var points: [PointNode] = []
    private var lines: [SCNNode] = []
    private var polygons: [PolygonNode] = []
    private var isDrawingFinished = false
    private var raycastTrackerTimer: Timer?
    private var queryAlignment: ARRaycastQuery.TargetAlignment?
    private var alignment: ARPlaneAnchor.Alignment = .horizontal
    private var trackLineTimer: Timer?
    private var needShowPlaneAim = false {
        didSet {
            surfaceSearchImageView.isHidden = !needShowPlaneAim
        }
    }
    
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupSurfaceSearchImageView()
        setupClearButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        needShowPlaneAim = true
        setupARSession()
        setupRaycastTracker()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        trackLineTimer?.invalidate()
    }
    
}


// MARK: Raycasting

extension MeasureViewController {

    private func setupRaycastTracker() {
        guard raycastTrackerTimer == nil else {
            return
        }
        raycastTrackerTimer = Timer.scheduledTimer(withTimeInterval: 1 / frameRate, repeats: true) { [weak self] timer in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async {
                if self.isDrawingFinished {
                    timer.invalidate()
                    self.raycastTrackerTimer = nil
                    self.removeTrackedNodes()
                    self.surfaceSearchImageView.isHidden = true
                } else {
                    guard let result = self.raycast(),
                          let planeAnchor = result.anchor as? ARPlaneAnchor else {
                        self.removeTrackedNodes()
                        self.needShowPlaneAim = true
                        return
                    }
                    self.needShowPlaneAim = false
                    let position = SCNVector3.positionFrom(matrix: result.worldTransform)
                    
                    self.updateTrackedAimNode(position: position, alignment: planeAnchor.alignment)
                    self.updateTrackedLineNode(aimPosition: position)
                }
            }
        }
    }
    
    private func raycast() -> ARRaycastResult? {
        guard let query = self.sceneView.raycastQuery(from: self.sceneView.center, allowing: .estimatedPlane, alignment: self.queryAlignment ?? .any) else {
            print("No surface found")
            return nil
        }
        guard let result = self.sceneView.session.raycast(query).first else {
            print("No raycast found for query \(query)")
            return nil
        }
        return result
    }
}


// MARK: Setup UI Elements

extension MeasureViewController {
    
    private func setupClearButton() {
        clearButton.layer.borderWidth = 5
        clearButton.layer.borderColor = UIColor.white.cgColor
        clearButton.layer.cornerRadius = clearButton.frame.height / 4
        clearButton.layer.masksToBounds = true
    }
    
    private func setupScene() {
        let scene = SCNScene()
        self.sceneView.delegate = self
        self.sceneView.automaticallyUpdatesLighting = true
        self.sceneView.debugOptions = [.showFeaturePoints]
        self.sceneView.scene = scene
        addTapGesture()
    }
    
    private func setupSurfaceSearchImageView() {
        surfaceSearchImageView.image = UIImage(named: searchSurfaceImageName)
        surfaceSearchImageView.contentMode = .scaleToFill
        surfaceSearchImageView.backgroundColor = .clear
        surfaceSearchImageView.frame.size = CGSize(width: surfaceSearchImageSize, height: surfaceSearchImageSize)
        surfaceSearchImageView.center = sceneView.center
        surfaceSearchImageView.layer.masksToBounds = true
        sceneView.addSubview(surfaceSearchImageView)
        startSurfaceSearchAnimation()
    }
    
    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    private func setupARSession() {
        let configauration = ARWorldTrackingConfiguration()
        configauration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configauration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    private func startSurfaceSearchAnimation() {
        guard surfaceSearchImageView.layer.animation(forKey: surfaceSearchAnimationKey) == nil else {
            return
        }
        let orbit = CAKeyframeAnimation(keyPath: surfaceSearchAnimationKeyPath)
        let size = surfaceSearchImageSize
        let circlePath = UIBezierPath(arcCenter: CGPoint(),
                                      radius: CGFloat(size),
                                      startAngle: CGFloat(0),
                                      endAngle: 2 * .pi,
                                      clockwise: true)
        orbit.path = circlePath.cgPath
        orbit.duration = 4
        orbit.isAdditive = true
        orbit.repeatCount = .infinity
        orbit.calculationMode = .paced
        surfaceSearchImageView.layer.add(orbit, forKey: surfaceSearchAnimationKey)
    }
}


// MARK: Nodes

extension MeasureViewController {
    
    private func removeTrackedNodes() {
        trackedLine?.removeFromParentNode()
        trackedLineLenghtText?.removeFromParentNode()
        removeTrackedAimNode()
    }

    private func addPointNode(position: SCNVector3) {
        var point = PointNode(position: position, radius: pointRadius, color: pointColor)
        
        var isLastPoint = false
        
        if let firstPoint = points.first,
           points.count >= minimumPointsCount,
           point.position.distance(to: firstPoint.position) < minimumPointsDistance {
            point = firstPoint
            isLastPoint = true
        }
        if let lastPoint = points.last {
            addLineNode(from: lastPoint, to: point)
        }
        if isLastPoint {
            lastPoint = nil
            isDrawingFinished = true
            addPolygonNode()
        } else {
            sceneView.scene.rootNode.addChildNode(point)
            points.append(point)
            lastPoint = point
        }
    }
    
    private func addPolygonNode() {
        let polygon = PolygonNode(points: points, alignment: alignment, color: polygonColor)
        sceneView.scene.rootNode.addChildNode(polygon)
        polygons.append(polygon)
        print(polygon.area)
    }
    
    private func addLineNode(from startPoint: SCNNode, to endPoint: SCNNode) {
        let lineNode = LineNode(from: startPoint, to: endPoint, width: lineWidth, color: .white, alignment: alignment)
        lines.append(lineNode)
        sceneView.scene.rootNode.addChildNode(lineNode)
        print( String(format: "Distance between nodes:  %.2f cm", lineNode.lenght * 100))
    }
    
    private func updateTrackedAimNode(position: SCNVector3, alignment: ARPlaneAnchor.Alignment) {
        if let aimNode = trackedAim {
            aimNode.position = position
            aimNode.alignment = alignment
        } else {
            let aimNode = AimNode(position: position, size: aimNodeSize, alignment: alignment)
            aimNode.startAnimation()
            sceneView.scene.rootNode.addChildNode(aimNode)
            trackedAim = aimNode
        }
    }
    
    private func updateTrackedLineNode(aimPosition: SCNVector3) {
        self.trackedLine?.removeFromParentNode()
        
        guard let lastPoint = lastPoint else {
            return
        }
        
        let line = SCNNode.createLineNode(from: lastPoint.position, to: aimPosition, color: .white)
        self.trackedLine = line
        
        self.sceneView.scene.rootNode.addChildNode(line)
        
        updateTrackeLineLenghtText(aimPosition: aimPosition, lenght: lastPoint.position.distance(to: aimPosition))
    }
    
    private func updateTrackeLineLenghtText(aimPosition: SCNVector3, lenght: CGFloat) {
        trackedLineLenghtText?.removeFromParentNode()
        let text = String(format: "%.2f cm", lenght * 100)
        let textPosition = SCNVector3(CGFloat(aimPosition.x), CGFloat(aimPosition.y), CGFloat(aimPosition.z) - aimNodeSize / 2)
        let textNode = TextNode(text, position: textPosition, alignment: alignment)
        trackedLineLenghtText = textNode
        textNode.color = .white
        textNode.font = .systemFont(ofSize: arTextFontSize)
        sceneView.scene.rootNode.addChildNode(textNode)
    }
    
    private func removeTrackedAimNode() {
        self.trackedAim?.removeFromParentNode()
        self.trackedAim = nil
    }
}

// MARK: User Interactions

extension MeasureViewController {
    
    @objc private func handleTap(sender: UITapGestureRecognizer) {
        
        guard isDrawingFinished == false else {
            print("Polygon is already drawn")
            return
        }

        guard let result = raycast() else {
            return
        }
        
        let position = SCNVector3.positionFrom(matrix: result.worldTransform)
        if points.isEmpty {
            if let planeAnchor = result.anchor as? ARPlaneAnchor {
                alignment = planeAnchor.alignment
                switch alignment {
                case .horizontal:
                    queryAlignment = .horizontal
                case .vertical:
                    queryAlignment = .vertical
                default:
                    queryAlignment = .any
                }
            }
        }
        addPointNode(position: position)
    }

    @IBAction func clearButtonPressed(_ sender: Any) {
        points.forEach({
            $0.removeFromParentNode()
        })
        lines.forEach({
            $0.removeFromParentNode()
        })
        polygons.forEach({
            $0.removeFromParentNode()
        })
        points.removeAll()
        lines.removeAll()
        polygons.removeAll()
        isDrawingFinished = false
        setupRaycastTracker()
        surfaceSearchImageView.isHidden = false
        lastPoint = nil
        queryAlignment = nil
    }
}

extension MeasureViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("Camera State: \(camera.trackingState)")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        setupRaycastTracker()
    }
}
