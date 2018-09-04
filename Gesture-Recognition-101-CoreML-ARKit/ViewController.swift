//
//  ViewController.swift
//  Gesture-Recognition-101-CoreML-ARKit
//
//  Created by Hanley Weng on 10/22/17.
//  Copyright © 2017 Emerging Interactions. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var debugTextView: UITextView!
    @IBOutlet weak var textOverlay: UITextField!
    
    var i = 0
    var j = 0

    
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    var visionRequests = [VNRequest]()
    let scene = SCNScene()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // --- ARKIT ---
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene() // SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // --- ML & VISION ---
        
        // Setup Vision Model
        guard let selectedModel = try? VNCoreMLModel(for: example_5s0_hand_model().model) else {
            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project. Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
        }
        
        // Set up Vision-CoreML Request
        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
        
        // Begin Loop to Update CoreML
        loopCoreMLUpdate()
    }
    var x = 0
    
    func addSprite(z1: Double)
    {
        let particlesNode = SCNNode()
        particlesNode.position = SCNVector3(0,0,-1)

       // particlesNode.orientation = SCNve
        let particleSystem = SCNParticleSystem(named: "reactor.scnp", inDirectory: "")
        particlesNode.addParticleSystem(particleSystem!)
        scene.rootNode.addChildNode(particlesNode)
        sceneView.scene = scene
    }
    func destroySprite()
    {
        scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
    }
    
    var x1 = 0.0
    var y1 = 0.0
    var z1 = -0.2
    
   
    func addBox(z1: Double)
    {
        let box = SCNSphere(radius: 0.1)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        box.materials = [material]
        let boxNode = SCNNode()

        boxNode.geometry = box
        boxNode.position = SCNVector3(x1,y1,z1)
        sceneView.scene.rootNode.addChildNode(boxNode)
        sceneView.scene = scene
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        ARConfiguration.WorldAlignment.camera

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            
        }
    }
    
    // MARK: - MACHINE LEARNING
    
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        dispatchQueueML.async {
            // 1. Run Update.
                self.updateCoreML()
            // 2. Loop this function.
                self.loopCoreMLUpdate()
        }
    }
    
    func updateCoreML() {
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        
        // Prepare CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        // Run Vision Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
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
        let classifications = observations[0...2] // top 3 results
            .flatMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(String(format:" : %.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        // Render Classifications
        DispatchQueue.main.async {
            // Print Classifications
                // print(classifications)
                // print("-------------")
            
            // Display Debug Text on screen
            self.debugTextView.text = "TOP 3 PROBABILITIES: \n" + classifications
            
            // Display Top Symbol
            var symbol = "❎"
            let topPrediction = classifications.components(separatedBy: "\n")[0]
            let topPredictionName = topPrediction.components(separatedBy: ":")[0].trimmingCharacters(in: .whitespaces)
            // Only display a prediction if confidence is above 1%
            let topPredictionScore:Float? = Float(topPrediction.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces))
            if (topPredictionScore != nil && topPredictionScore! > 0.03 ) {
                if (topPredictionName == "fist-UB-RHand") { symbol = "👊"
                    


                  self.i +=  1
                    if(self.i >= 20)
                    {
                        self.destroySprite()
                       self.i = 0
                    }
                }
                if (topPredictionName == "FIVE-UB-RHand")
                {
                    ARConfiguration.WorldAlignment.camera
                    symbol = "🖐"
                    self.i +=  1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4)  //
                    {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { //
                            
                            self.z1 -= 0.01
                        self.addBox(z1: self.z1)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {

                            self.destroySprite()

                        }
                        }
                    
                        self.i = 0
                        
                    }
                    
                    }
                    
                
                
            }
            
            self.textOverlay.text = symbol
            
        }
    }
    
    // MARK: - HIDE STATUS BAR
    override var prefersStatusBarHidden : Bool { return true }
}

