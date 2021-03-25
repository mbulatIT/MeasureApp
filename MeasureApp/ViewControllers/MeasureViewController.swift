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
    @IBOutlet weak var textureButton: UIButton!

    // MARK: Constants
    
    private let pointColor: UIColor = .purple
    private let pointRadius: CGFloat = 5
    private let lineWidth: CGFloat = 4
    private let aimNodeSize: CGFloat = 0.3
    private let minimumPointsDistance: CGFloat = 0.05
    private let surfaceSearchImageSize: CGFloat = 60
    private let arTextFontSize: CGFloat = 30
    private let frameRate: Double = 60
    private let surfaceSearchImageView = UIImageView()
    private let surfaceSearchAnimationKey = "surfaceSearchAnimation"
    private let surfaceSearchAnimationKeyPath =  "position"
    private let searchSurfaceImageName = "search_icon"
    private let tempId = "0123"
    private let defaultAnimationDuration: Double = 4
    private let polygonColor = #colorLiteral(red: 0.994084537, green: 1, blue: 0.4055556059, alpha: 0.7)
    private let minimumPointsCount = 3
    private var lastPoint: SCNVector3?
    private var trackedLine: SCNNode?
    private var trackedAim: AimNode?
    private var points: [SCNVector3] = []
    private var lines: [Line] = []
    private var polygon: Polygon? {
        didSet {
            textureButton.isHidden = polygon == nil
        }
    }
    private var currentPolygonDrawData: PolygonDrawData?
    private var isDrawingFinished = false
    private var raycastTrackerTimer: Timer?
    private var queryAlignment: ARRaycastQuery.TargetAlignment?
    private var alignment: ARPlaneAnchor.Alignment = .horizontal
    private var trackLineTimer: Timer?
    private var needShowSurfaceSearchImage = false {
        didSet {
            surfaceSearchImageView.isHidden = !needShowSurfaceSearchImage
        }
    }
    private var textureNames = ["grass_icon", "brick_wall_icon", "metal_icon"]
    private var canvasView: CanvasView!

    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupSurfaceSearchImageView()
        setupClearButton()
        setupTextureButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        needShowSurfaceSearchImage = true
        setupARSession()
        setupRaycastTracker()
        setupCanvasView()
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
                self.redrawCanvas()
                if self.isDrawingFinished {
                    self.removeTrackedNodes()
                    self.surfaceSearchImageView.isHidden = true
                } else {
                    guard let result = self.raycast(),
                          let planeAnchor = result.anchor as? ARPlaneAnchor else {
                        self.removeTrackedNodes()
                        self.needShowSurfaceSearchImage = true
                        return
                    }
                    self.needShowSurfaceSearchImage = false
                    let position = SCNVector3.positionFrom(matrix: result.worldTransform)
                    
                    self.updateTrackedAimNode(position: position, alignment: planeAnchor.alignment)
                }
            }
        }
    }
    
    private func redrawCanvas() {
        guard let firstPoint = points.first else {
            return
        }
        
        canvasView.lineWidth = lineWidth
        canvasView.pointRadius = pointRadius

        let linesDrawData = lines.map({LineDrawData(id: $0.id,
                                                    startPoint: mapPoint(point: $0.startPoint),
                                                    endPoint: mapPoint(point: $0.endPoint),
                                                    center: mapPoint(point: $0.center),
                                                    worldLenght: $0.lenght)})
        let firstPoint2D = mapPoint(point: firstPoint)
        var polygonCenter: CGPoint?
        if let polygonCenter3D = polygon?.center {
            polygonCenter = mapPoint(point: polygonCenter3D)
        }
        var aimLine: LineDrawData?
        if let aimPosition = trackedAim?.position,
           let lastPoint = lastPoint {
            let line = Line(startPoint: lastPoint, endPoint: aimPosition)
            let aimPoint = mapPoint(point: aimPosition)
            let lastPoint2D = mapPoint(point: lastPoint)
            aimLine = LineDrawData(id: line.id,
                                   startPoint: lastPoint2D,
                                   endPoint: aimPoint,
                                   center: mapPoint(point: line.center),
                                   worldLenght: line.lenght)
        }
        let polygonDrawData = PolygonDrawData(id: tempId, lines: linesDrawData,
                                                firstPoint: firstPoint2D,
                                                isPolygonFinished: isDrawingFinished,
                                                center: polygonCenter, area: polygon?.area,
                                                aimLine: aimLine)
        canvasView.setPolygonDrawData(polygonDrawData)
        
    }
    
    private func mapPoint(point: SCNVector3) -> CGPoint {
        let point3 = sceneView.projectPoint(point)
        return CGPoint(x: CGFloat(point3.x), y: CGFloat(point3.y))
    }
    
    private func raycast() -> ARRaycastResult? {
        guard let query = self.sceneView.raycastQuery(from: self.sceneView.center, allowing: .existingPlaneInfinite, alignment: self.queryAlignment ?? .any) else {
//            print("No surface found")
            return nil
        }
        guard let result = self.sceneView.session.raycast(query).first else {
//            print("No raycast found for query \(query)")
            return nil
        }
        return result
    }
}


// MARK: Setup UI Elements

extension MeasureViewController {
    
    private func setupCanvasView() {
        canvasView = CanvasView()
        canvasView.frame = sceneView.frame
        canvasView.isUserInteractionEnabled = false
        canvasView.backgroundColor = .clear
        view.addSubview(canvasView)
    }
    
    private func setupClearButton() {
        clearButton.layer.borderWidth = 5
        clearButton.layer.borderColor = UIColor.white.cgColor
        clearButton.layer.cornerRadius = clearButton.frame.height / 4
        clearButton.layer.masksToBounds = true
    }
    
    private func setupTextureButton() {
        textureButton.layer.borderWidth = 5
        textureButton.layer.borderColor = UIColor.white.cgColor
        textureButton.layer.cornerRadius = clearButton.frame.height / 4
        textureButton.layer.masksToBounds = true
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


// MARK: Save points

extension MeasureViewController {
    
    private func removeTrackedNodes() {
        removeTrackedAimNode()
    }

    private func addPoint(position: SCNVector3) {
        
        var isLastPoint = false
        
        if let firstPoint = points.first,
           points.count >= minimumPointsCount,
           position.distance(to: firstPoint) < minimumPointsDistance,
           let lastPoint = points.last {
            isLastPoint = true
            addLine(from: lastPoint, to: firstPoint)
        }
        if let lastPoint = points.last, isLastPoint == false {
            addLine(from: lastPoint, to: position)
        }
        if isLastPoint {
            lastPoint = nil
            isDrawingFinished = true
            addPolygon()
        } else {
            points.append(position)
            lastPoint = position
        }
    }
    
    private func addPolygon() {
        let polygon = Polygon(points: points, alignment: alignment)
        sceneView.scene.rootNode.addChildNode(polygon)
        self.polygon = polygon
    }
    
    private func addLine(from startPoint: SCNVector3, to endPoint: SCNVector3) {
        let line = Line(startPoint: startPoint, endPoint: endPoint)
        lines.append(line)
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
        addPoint(position: position)
    }

    @IBAction func clearButtonPressed(_ sender: Any) {
        points.removeAll()
        lines.removeAll()
        polygon?.removeFromParentNode()
        polygon = nil
        canvasView.clear()
        isDrawingFinished = false
        setupRaycastTracker()
        surfaceSearchImageView.isHidden = false
        lastPoint = nil
        queryAlignment = nil
    }
    
    
    @IBAction func textureButtonPressed(_ sender: Any) {
        if let imageName = textureNames.randomElement() {
            polygon?.applyTexture(image: UIImage(named: imageName))
        }
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
