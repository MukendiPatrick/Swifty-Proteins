import UIKit
import SceneKit
import SwiftyJSON
import SVProgressHUD

class ActionViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var melt: UILabel!
    @IBOutlet weak var boil: UILabel!
    @IBOutlet weak var mass: UILabel!
    @IBOutlet weak var descript: UILabel!
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet var tap: UITapGestureRecognizer!
    @IBOutlet var pinch: UIPinchGestureRecognizer!
    @IBOutlet weak var shareBtn: UIBarButtonItem!
    
    var scene = SCNScene()
    var prevColor  = UIColor()
    var hittedObj  =  SCNNode()
    var previousScale: CGFloat = 1.0
    var DataDetails: [AtomDetails] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        initScene()
        getAtomDetails()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func shareImage(_ sender: Any) {
        
        shareBtn.isEnabled = false
        let bounds = UIScreen.main.bounds
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        self.view.drawHierarchy(in: bounds, afterScreenUpdates: false)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        SVProgressHUD.show()
        
        let activityViewController = UIActivityViewController(activityItems: [img!], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [.addToReadingList, .airDrop, .copyToPasteboard, .mail, .assignToContact]
        activityViewController.popoverPresentationController?.sourceView = self.view
        DispatchQueue.main.async {
            self.present(activityViewController, animated: true, completion: nil)
        }
        shareBtn.isEnabled = true
        SVProgressHUD.dismiss()
        activityViewController.completionWithItemsHandler = { activity, completed, items, error in
            if completed {
                self.showAlertController("Your photo was uploaded successfully.")
            }
             else if error != nil{
                self.showAlertController("Some error occurred. Please try again.")
            }
        }
    }
    
    @IBAction func scalePiece(_ gestureRecognizer : UIPinchGestureRecognizer) {   guard gestureRecognizer.view != nil else { return }
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            gestureRecognizer.view?.transform = (gestureRecognizer.view?.transform.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale))!
            gestureRecognizer.scale = 1.0
        }}
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: sceneView)
        
        hittedObj.geometry?.firstMaterial?.emission.contents = prevColor
        
        let hitList = sceneView.hitTest(location, options: nil)
        if let hitObject = hitList.first {
            for currAtom in DataDetails{
                if currAtom.symb?.lowercased() == hitObject.node.name?.lowercased() {
                    
                    melt.text = "Melting point: --"
                    boil.text = "Boiling point: --"
                    name.text = "Full Name: --"
                    descript.text = "--"
                    mass.text = "Atomic mass: --"
                    
                    if let temperature = currAtom.atomic_mass {
                        mass.text = "Atomic mass: \(String(describing: temperature))"
                    }
                    if let temperature = currAtom.melt {
                        melt.text = "Melting point: \(String(describing: temperature))°C"
                    }
                    if let temperature = currAtom.name {
                        name.text = "Full Name: \(temperature)"
                    }
                    if let temperature = currAtom.boil {
                         boil.text = "Boiling point: \(String(describing: temperature))°C"
                    }
                    descript.text = currAtom.summary
                }
            }
            hittedObj = hitObject.node
            prevColor = hitObject.node.geometry?.firstMaterial?.emission.contents as! UIColor
            hitObject.node.geometry?.firstMaterial?.emission.contents = UIColor.flatMint
        } else {
            name.text = nil
            boil.text = nil
            melt.text = nil
            mass.text = nil
            descript.text = nil
        }
    }
    
    func initScene(){
        
        name.text = nil
        boil.text = nil
        melt.text = nil
        mass.text = nil
        descript.text = nil
        
        tap.delegate = self
        pinch.delegate = self
        view.addGestureRecognizer(pinch)
        sceneView.addGestureRecognizer(tap)

        sceneView.backgroundColor = UIColor.white
        
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 35)
        
        scene.background.contents = UIColor(red: 60/255, green: 75/255, blue: 90/255, alpha: 1)
        scene.rootNode.addChildNode(cameraNode)
        sceneView.scene = scene
    }

    func showAlertController(_ message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func getAtomDetails(){
        if let path = Bundle.main.path(forResource: "PeriodicTableJSON", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let json = JSON(data)
                for i in json["elements"] {
                    let atomDetails = AtomDetails(json: i.1)
                    DataDetails.append(atomDetails)
                }
            } catch {}
        }
    }
}


