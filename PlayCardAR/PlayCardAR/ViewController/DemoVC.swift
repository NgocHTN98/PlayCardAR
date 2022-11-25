//
//  DemoVC.swift
//  PlayCardAR
//
//  Created by NgocHTN6 on 22/11/2022.
//

import Foundation
import UIKit
import ARKit
import SceneKit

class DemoVC: UIViewController {
    lazy var sceneView: ARSCNView = {
        let scene = ARSCNView()
        scene.scene = SCNScene()
        return scene
    }()
    lazy var button: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "arrow.clockwise"), for: .normal)
        return btn
    }()
    lazy var visionRequests = [VNRequest]()
    private let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
    private var latestPrediction : String = "…" // a variable containing the latest CoreML prediction
    private var mascotNode: SCNNode?
    var hoopAddred = false
    var audioSource: SCNAudioSource!
    var soundAction = SCNAction()
    var soundNode = SCNNode()
    private var isPlaySound: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareUI()
        self.setUpAudio()

        self.setupVisionModel()
        // Begin Loop to Update CoreML
        self.loopCoreMLUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    // MARK: - Status Bar: Hide
    override var prefersStatusBarHidden : Bool {
        return true
    }
    func prepareUI() {
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        // Enable Default Lighting - makes the 3D text a bit poppier.
        sceneView.autoenablesDefaultLighting = true
        self.sceneView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(sceneView)
        sceneView.addSubview(self.button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .yellow
        NSLayoutConstraint.activate([
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30),
            button.widthAnchor.constraint(equalToConstant: 50),
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        button.addTarget(self, action: #selector(self.refreshSession(gestureRecognize:)), for: .touchUpInside)
       
        
    }
    
    func configSession() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Enable plane detection
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    
    func setupVisionModel() {
        // Set up Vision Model
        if #available(iOS 12.0, *) {
            guard let selectedModel = try? VNCoreMLModel(for: CleanAir(configuration: .init()).model) else { // (Optional) This can be replaced with other models on
                fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project from https://developer.apple.com/machine-learning")
            }
            // Set up Vision-CoreML Request
            let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
            classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
            visionRequests = [classificationRequest]
        } else {
            // Fallback on earlier versions
            print("Not support version")
        }
    }
    
    // MARK: - CoreML Vision Handling
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        DispatchQueue.main.async {
            // 1. Run Update.
            self.updateCoreML()
            
            // 2. Loop this function.
            self.loopCoreMLUpdate()
        }
        
    }
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        // Catch Errors
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        // Get Classifications
//        let classifications = observations[0...1] // top 2 results
//            .compactMap({ $0 as? VNClassificationObservation })
//            .map({ "\($0.identifier) \(String(format:"- %.2f", $0.confidence))" })
//            .joined(separator: "\n")
//
//
//        DispatchQueue.main.async { [self] in
//            // Print Classifications
//            print(classifications)
//            print("--")
//
//            // Display Debug Text on screen
//            var debugText:String = ""
//            debugText += classifications
//
//            // Store the latest prediction
//            var objectName:String = "…"
//            objectName = classifications.components(separatedBy: "-")[0]
//            objectName = objectName.components(separatedBy: ",")[0]
//            self.latestPrediction = objectName
//
//        }
        let classifications = observations.first(where: { $0.confidence > 0.5 }) as? VNClassificationObservation
        DispatchQueue.main.async { [self] in
            // Print Classifications
            print(classifications)
            print("--")
            print("abc \(classifications?.identifier)")
            self.latestPrediction = classifications?.identifier ?? ""
        }
        if self.latestPrediction.trimmingCharacters(in: .whitespacesAndNewlines) == "human_being" {
            if self.mascotNode == nil {
                let node : SCNNode = createMascot()
                sceneView.scene.rootNode.addChildNode(node)
            }
            return
        }
    }
    
    func updateCoreML() {
        ///////////////////////////
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        // Note: Not entirely sure if the ciImage is being interpreted as RGB, but for now it works with the Inception model.
        // Note2: Also uncertain if the pixelBuffer should be rotated before handing off to Vision (VNImageRequestHandler) - regardless, for now, it still works well with the Inception model.
        
        ///////////////////////////
        // Prepare CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        // let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!, orientation: myOrientation, options: [:]) // Alternatively; we can convert the above to an RGB CGImage and use that. Also UIInterfaceOrientation can inform orientation values.
        
        ///////////////////////////
        // Run Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
        
    }
    @objc func refreshSession(gestureRecognize: UITapGestureRecognizer) {
        
        self.resetTracking()
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
    }
    
    private func playSound() {
        // Ensure there is only one audio player
        self.mascotNode?.removeAllAudioPlayers()
        // Create a player from the source and add it to `objectNode`
        self.mascotNode?.addAudioPlayer(SCNAudioPlayer(source: audioSource))
    }

    
//    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // HIT TEST : REAL WORLD
        // Get Screen Centre
//        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
//
//        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
//
//        if let closestResult = arHitTestResults.first {
//            // Get Coordinates of HitTest
//            let transform : matrix_float4x4 = closestResult.worldTransform
//            let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
//
//            // Create 3D Text
//            let node : SCNNode = createMascot()
//            sceneView.scene.rootNode.addChildNode(node)
//            node.position = worldCoord
//        }
//        UnityEmbeddedSwift.shared.show()
//    }
   
    func createMascot() -> SCNNode {
//        let billboardConstraint = SCNBillboardConstraint()
//        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        mascotNode = SCNScene(named: "art.scnassets/Fox/max.scn")?.rootNode.childNodes.first
        mascotNode?.scale = .init(0.5, 0.5, 0.5)
        let nodeParent = SCNNode()
        if let _mascot = self.mascotNode {
            nodeParent.addChildNode(_mascot)
        }
        
//        nodeParent.constraints = [billboardConstraint]
        return nodeParent
    }
    func createNewBubbleParentNode(_ text : String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        var font = UIFont(name: "Futura", size: 0.15)
        font = font?.withTraits(traits: .traitBold)
        bubble.font = font
        bubble.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        bubble.firstMaterial?.diffuse.contents = UIColor.orange
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.3, 0.3, 0.3)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }
    private func resetTracking() {
        self.configSession()
        self.mascotNode = nil
    }
    
    private func setUpAudio() {
        // Instantiate the audio source
        audioSource = SCNAudioSource(fileNamed: "sample.mp3")!
        // As an environmental sound layer, audio should play indefinitely
        audioSource.loops = true
        // Decode the audio from disk ahead of time to prevent a delay in playback
        audioSource.load()
    }
    
    
     @objc func handleTap(_ sender: UITapGestureRecognizer) {
         let location = sender.location(in: sceneView)
         let results = sceneView.hitTest(location, options: [SCNHitTestOption.searchMode : 1])
         for _ in results.filter( { $0.node.name == "Max" }) {  /// See if the beam hit the cube
             self.isPlaySound = !self.isPlaySound
             if isPlaySound == false {
                 self.playSound()
                 self.createContent()
             }else {
                 self.mascotNode?.removeAllAudioPlayers()
             }
            
         }
       
     }
    
    func createContent() {
        let string = "Coverin text with a plane :)"
        let text = SCNText(string: string, extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 1)
        text.flatness = 0.005
        let textNode = SCNNode(geometry: text)
        let fontScale: Float = 0.01
        textNode.scale = SCNVector3(fontScale, fontScale, fontScale)
        let mascotHeight = Float(mascotNode?.frame.height ?? 0)
        textNode.position = SCNVector3(0, 0,-10)
        let (min, max) = (text.boundingBox.min, text.boundingBox.max)
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)

        let width = (max.x - min.x) * fontScale
        let height = (max.y - min.y) * fontScale
        let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        let planeNode = SCNNode(geometry: plane)
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.5)
        planeNode.geometry?.firstMaterial?.isDoubleSided = true
        planeNode.position = textNode.position
        textNode.eulerAngles = planeNode.eulerAngles
        planeNode.addChildNode(textNode)
        
        self.sceneView.scene.rootNode.addChildNode(planeNode)

    }

}
extension DemoVC: ARSCNViewDelegate {

}
extension UIFont {
    // Based on: https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
    func withTraits(traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}
