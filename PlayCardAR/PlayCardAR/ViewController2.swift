//
//  ViewController2.swift
//  PlayCardAR
//
//  Created by Quoc Lam on 29/09/2022.
//

import UIKit
import RealityKit

class ViewController2: UIViewController {

    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the "Box" scene from the "Experience" Reality File
        let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        arView.scene.anchors.append(boxAnchor)
    }

}
