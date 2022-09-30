//
//  ViewController.swift
//  PlayCardAR
//
//  Created by NgocHTN6 on 27/09/2022.
//

import UIKit
import SceneKit
import ARKit
class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var hoopAddred = false
    var pokemonNode: SCNNode?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        print("Hello Nhung")
        sceneView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setConfig()
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    

     //Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        if let imageAnchor = anchor as? ARImageAnchor {
            let size = imageAnchor.referenceImage.physicalSize
            let plane = SCNPlane(width: size.width, height: size.height)
            plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.0)
            plane.cornerRadius = 0.005
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            node.addChildNode(planeNode)
            if imageAnchor.referenceImage.name == "card1" {
                if let _scene = SCNScene(named: "art.scnassets/ball.scn"){
                    if let _node = _scene.rootNode.childNodes.first {
                        self.pokemonNode = _node
                        _node.eulerAngles.x = .pi/3
                       planeNode.addChildNode(_node)
                    }
                   
               }
               
            }
           
        }
        return node
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
    func showScene() {
        ///option 1
//        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
//        // Set the scene to the view
//        sceneView.scene = scene
        
        ///option 2
//        let scene = SCNScene(named: "art.scnassets/box.scn")!
//        let plane = SCNPlane(width: 0.1, height: 0.1)
//        plane.firstMaterial?.diffuse.contents = UIColor.red.withAlphaComponent(0.5)
//        plane.cornerRadius = 0.005
//        let planeNode = SCNNode(geometry: plane)
//        scene.rootNode.addChildNode(planeNode)
//        sceneView.scene = scene
//        self.pokemonNode = sceneView.scene.rootNode.childNode(withName: "box", recursively: false)
//        sceneView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
//        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
    }
    
    func setConfig() {
        //config 1
        // Create a session configuration
//        let configuration = ARWorldTrackingConfiguration()
//
//        // Run the view's session
//        sceneView.session.run(configuration)
        //config 2
        let config = ARImageTrackingConfiguration()
        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "Play game", bundle: .main) else {   fatalError("Couldn't load tracking images.") }
        config.trackingImages = trackingImages
        config.maximumNumberOfTrackedImages = 2
        sceneView.session.run(config)
        
        //config 3
        //        // Create a session configuration
        //        let configuration = ARWorldTrackingConfiguration()
        //        configuration.planeDetection = .vertical
        //        // Run the view's session
        //        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        ////        sceneView.session.run(configuration)
        //        sceneView.session.run(configuration, options: options)
        //        if let node = sceneView.scene.rootNode.childNode(withName: "Sphere_None", recursively: false) {
        //            node.runAction(SCNAction.rotateBy(x: 1, y: 0, z: 0, duration: 1))
        //            node.runAction(SCNAction.moveBy(x: 10, y: 10, z: 10, duration: 1))
        //        }
    }
    
    @objc func screenTapped(_ sender: UITapGestureRecognizer) {
        
        if !hoopAddred {
            let tapLocation = sender.location(in: sceneView)
            let hitTestResults = sceneView.hitTest(tapLocation)
            guard (hitTestResults.first?.node) != nil else {
                let hitTestResultsWithFeaturePoints = sceneView.hitTest(tapLocation, types: .featurePoint)
                if let hitTestResultWithFeaturePoints = hitTestResultsWithFeaturePoints.first {
                    addHoop(result: hitTestResultWithFeaturePoints)
                }
                return
            }
            hoopAddred = true
        }else {
            self.createBasketball()
        }
    }
    
    func addHoop(result: ARHitTestResult) {
        let hoop = SCNScene(named: "art.scnassets/basketball.scn")!
        guard let nodeHoop = hoop.rootNode.childNode(withName: "game", recursively: false) else { return }
        
        let position = result.worldTransform.columns.3
        nodeHoop.position = SCNVector3(position.x, position.y, position.z)
        nodeHoop.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: nodeHoop, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        sceneView.scene.rootNode.addChildNode(nodeHoop)
    }
    
    func createBasketball() {
        guard let currentFrame = sceneView.session.currentFrame else { return }
        let ball = SCNNode(geometry: SCNSphere(radius: 0.05))
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        
        let camera = SCNMatrix4(currentFrame.camera.transform)
        ball.transform = camera
        
        let physicBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
        ball.physicsBody = physicBody
        let power = Float(10.0)
        let force = SCNVector3(-camera.m31 * power, -camera.m32 * power, -camera.m33 * power)
        ball.physicsBody?.applyForce(force, asImpulse: true)
        sceneView.scene.rootNode.addChildNode(ball)
    }
    
    func addBallPokemon() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        let _pokemon = SCNScene(named: "art.scnassets/pokemon.scn")!
        sceneView.scene = _pokemon
        //        guard let node = _pokemon.rootNode.childNode(withName: "ball", recursively: false) else { return }
        //
        //        let scaleFactor = 0.5
        //                node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        //                node.eulerAngles.x = -.pi / 2
        //        sceneView.scene.rootNode.addChildNode(node)
    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //        DispatchQueue.main.async {
        //            let _pokemon = SCNScene(named: "art.scnassets/pokemon.scn")!
        //            let node = _pokemon.rootNode.childNode(withName: "ball", recursively: false)
        //            let overlayNode = node
        //            overlayNode?.opacity = 1
        //            overlayNode?.position.y = 0.2
        //            if let _overLay = overlayNode {
        //                node?.addChildNode(_overLay)
        //            }
        //
        //
        //        }
    }
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let terrain = self.pokemonNode else {
                   return
               }

       let point = sender.location(in: sceneView)
        if let _music = SCNAudioSource(named: "music1") {
            let action = SCNAction.playAudio( _music, waitForCompletion: true)
            terrain.runAction(action)
        }
      
            
    }
    var PCoordx: Float = 0.0
    var PCoordz: Float = 0.0
    var PCoordy: Float = 0.0
    private var lastDragResult: ARHitTestResult?
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let terrain = self.pokemonNode else {
                   return
       }

       let point = sender.location(in: sceneView)
       if let result = sceneView?.smartHitTest(point, infinitePlane: true) {
           if let lastDragResult = lastDragResult {
               let vector: SCNVector3 = SCNVector3(result.worldTransform.columns.3.x - lastDragResult.worldTransform.columns.3.x,
                                                   result.worldTransform.columns.3.y - lastDragResult.worldTransform.columns.3.y,
                                                   result.worldTransform.columns.3.z - lastDragResult.worldTransform.columns.3.z)
               terrain.position.x += vector.x
               terrain.position.y += vector.y
               terrain.position.z = vector.z
           }
           lastDragResult = result
       }

       if sender.state == .ended {
           self.lastDragResult = nil
       }
                
    }
    @objc func upLongPressed(_ sender: UILongPressGestureRecognizer) {

        let action = SCNAction.moveBy(x: 0, y: 0.5, z: 0, duration: 0.2)

           execute(action: action, sender: sender)

       }

    func execute(action: SCNAction, sender: UILongPressGestureRecognizer) {

           let loopAction = SCNAction.repeatForever(action)
           if sender.state == .began {
               
               sceneView.scene.rootNode.runAction(loopAction)

           } else if sender.state == .ended {

               sceneView.scene.rootNode.removeAllActions()

           }

       }

}
fileprivate extension ARSCNView {
    func smartHitTest(_ point: CGPoint,
                      infinitePlane: Bool = false,
                      objectPosition: float3? = nil,
                      allowedAlignments: [ARPlaneAnchor.Alignment] = [.horizontal]) -> ARHitTestResult? {

        // Perform the hit test.
        let results: [ARHitTestResult]!
        if #available(iOS 11.3, *) {
            results = hitTest(point, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
        } else {
            results = hitTest(point, types: [.estimatedHorizontalPlane])
        }

        // 1. Check for a result on an existing plane using geometry.
        if #available(iOS 11.3, *) {
            if let existingPlaneUsingGeometryResult = results.first(where: { $0.type == .existingPlaneUsingGeometry }),
                let planeAnchor = existingPlaneUsingGeometryResult.anchor as? ARPlaneAnchor, allowedAlignments.contains(planeAnchor.alignment) {
                return existingPlaneUsingGeometryResult
            }
        }

        if infinitePlane {
            // 2. Check for a result on an existing plane, assuming its dimensions are infinite.
            //    Loop through all hits against infinite existing planes and either return the
            //    nearest one (vertical planes) or return the nearest one which is within 5 cm
            //    of the object's position.
            let infinitePlaneResults = hitTest(point, types: .existingPlane)

            for infinitePlaneResult in infinitePlaneResults {
                if let planeAnchor = infinitePlaneResult.anchor as? ARPlaneAnchor, allowedAlignments.contains(planeAnchor.alignment) {
                    // For horizontal planes we only want to return a hit test result
                    // if it is close to the current object's position.
                    if let objectY = objectPosition?.y {
                        let planeY = infinitePlaneResult.worldTransform.translation.y
                        if objectY > planeY - 0.05 && objectY < planeY + 0.05 {
                            return infinitePlaneResult
                        }
                    } else {
                        return infinitePlaneResult
                    }
                }
            }
        }

        // 3. As a final fallback, check for a result on estimated planes.
        return results.first(where: { $0.type == .estimatedHorizontalPlane })
    }
}

fileprivate extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
     */
    var translation: float3 {
        get {
            let translation = columns.3
            return float3(translation.x, translation.y, translation.z)
        }
        set(newValue) {
            columns.3 = float4(newValue.x, newValue.y, newValue.z, columns.3.w)
        }
    }

    /**
     Factors out the orientation component of the transform.
     */
    var orientation: simd_quatf {
        return simd_quaternion(self)
    }

    /**
     Creates a transform matrix with a uniform scale factor in all directions.
     */
    init(uniformScale scale: Float) {
        self = matrix_identity_float4x4
        columns.0.x = scale
        columns.1.y = scale
        columns.2.z = scale
    }
}
