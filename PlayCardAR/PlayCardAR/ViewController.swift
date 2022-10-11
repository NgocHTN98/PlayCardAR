//
//  ViewController.swift
//  PlayCardAR
//
//  Created by NgocHTN6 on 27/09/2022.
//

import UIKit
import SceneKit
import ARKit
class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var hoopAddred = false
    var node: SCNNode?
    var audioSource: SCNAudioSource!
    
    var soundAction = SCNAction()
    var soundNode = SCNNode()
    var scene = SCNScene()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
    
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = false
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
        self.setUpAudio()
        if let scene = SCNScene(named: "art.scnassets/Fox/max.scn") {
            let model = scene.rootNode.childNode(withName: "Max_rootNode", recursively: true)!
            model.scale = SCNVector3(1.5, 1.5, 1.5)
            node = model
            self.pauseSpin(model)
            sceneView.scene = scene
        }
        
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
//        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
//        let node = SCNNode()
//        let size = imageAnchor.referenceImage.physicalSize
//        let plane = SCNPlane(width: size.width, height: size.height)
//        plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.4)
//        plane.cornerRadius = 0.005
//        let planeNode = SCNNode(geometry: plane)
//        planeNode.eulerAngles.x = -.pi / 2
//        node.addChildNode(planeNode)
//        if imageAnchor.referenceImage.name == "card1" {
//            if let _scene = SCNScene(named: "art.scnassets/foxTest.scn"){
//                if let _node = _scene.rootNode.childNodes.first {
//
//                    _node.eulerAngles.x = .pi/3
//                    planeNode.addChildNode(_node)
//                    let soundNode = SCNNode(geometry: plane)
//                    planeNode.addChildNode(soundNode)
//                    self.node = planeNode
//                }
//
//            }
//
//        }
//        return node
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return nil }
        let node = SCNNode()
        let plane = SCNPlane(width: 100, height: 100)
        plane.firstMaterial?.diffuse.contents = UIColor.red
        plane.cornerRadius = 0.005
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        node.addChildNode(planeNode)
        return node
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        self.resetTracking()
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        self.resetTracking()
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        self.resetTracking()
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
        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "PlayGame", bundle: nil) else {  return  }
        config.trackingImages = trackingImages
        //        config.planeDetection = .horizontal
        //        config.environmentTexturing = .automatic
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        
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
        let _pokemon = SCNScene(named: "art.scnassets/foxTest.scn")!
        sceneView.scene = _pokemon
    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let _nodePokemon = self.node else {
            return
        }
        _nodePokemon.removeFromParentNode()
        _nodePokemon.addAudioPlayer(SCNAudioPlayer(source: audioSource))
        // Place object node on top of the plane's node
        node.addChildNode(_nodePokemon)
        
//        self.setConfig()
    }
   
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        let results = sceneView.hitTest(location, options: [SCNHitTestOption.searchMode : 1])
        for _ in results.filter( { $0.node.name == "Max" }) {  /// See if the beam hit the cube
            self.playSound()
        }
      
    }
    var PCoordx: Float = 0.0
    var PCoordz: Float = 0.0
    var PCoordy: Float = 0.0
    private var lastDragResult: ARHitTestResult?
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let terrain = self.node else {
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
  
    private func playSound() {
        // Ensure there is only one audio player
        self.node?.removeAllAudioPlayers()
        // Create a player from the source and add it to `objectNode`
        self.node?.addAudioPlayer(SCNAudioPlayer(source: audioSource))
    }
    
    private func resetTracking() {
        let config = ARImageTrackingConfiguration()
        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "PlayGame", bundle: nil) else {   fatalError("Couldn't load tracking images.") }
        config.trackingImages = trackingImages
        //        config.planeDetection = .horizontal
        //        config.environmentTexturing = .automatic
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        // Reset preview state.
        self.node = nil
    }
    
    private func setUpAudio() {
        // Instantiate the audio source
        audioSource = SCNAudioSource(fileNamed: "sample.mp3")!
        // As an environmental sound layer, audio should play indefinitely
        audioSource.loops = true
        // Decode the audio from disk ahead of time to prevent a delay in playback
        audioSource.load()
    }
    
    func pauseSpin(_ node: SCNNode) {
        node.animationPlayer(forKey: "idle")?.play()
        node.position = SCNVector3(0, 0, -1.5)

//        let pause = SCNAction.wait(duration: 1.5)
//        node.runAction(pause) {
//            node.animationPlayer(forKey: "spin")?.play()
//            node.runAction(pause) {
//                self.circleRight(node)
//            }
//        }
    }
}

