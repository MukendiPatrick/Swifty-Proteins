import UIKit
import SceneKit
import CoreData
import Alamofire
import SwiftyJSON
import SVProgressHUD
import ChameleonFramework

class TableViewController: UITableViewController {
    
    var destTitle = String()
    var names: [String] = []
    var filteredNames: [String] = []
    var allAtoms: [SCNNode] = []
    var allCoords = [[(x: Float, y: Float, z: Float)]]()
    
    lazy var searchBar:UISearchBar = UISearchBar()
    
    @IBOutlet weak var randBtn: UIBarButtonItem!
    
    @IBAction func randProtein(_ sender: UIBarButtonItem) {
        
        if filteredNames.count != 0 {
            randBtn.isEnabled = false
            getPDBDataAndShowProtein(proteinIndex: Int(arc4random_uniform(UInt32(filteredNames.count))))
        } else {
            let alert = UIAlertController(title: "There are no elements to choose from", message: "Please, change your search request or clear search field", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        filteredNames = names
        searchBar.searchBarStyle = UISearchBar.Style.prominent
        searchBar.placeholder = " Search..."
        searchBar.sizeToFit()
        searchBar.isTranslucent = false
        searchBar.backgroundImage = UIImage()
        searchBar.delegate = self
        searchBar.tintColor = UIColor.darkGray
        
        navigationItem.titleView = searchBar

        let backgroundView = UIImageView(image: #imageLiteral(resourceName: "gray_bg"))
        backgroundView.contentMode = .scaleAspectFill
        self.tableView.backgroundView = backgroundView
        self.tableView.separatorStyle = .none
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredNames.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TableViewCell
        cell.backgroundColor = UIColor.clear
        cell.ligoldName.text = filteredNames[indexPath.row]
        cell.ligoldName.textColor = UIColor.white
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.isUserInteractionEnabled = false
        getPDBDataAndShowProtein(proteinIndex: indexPath.row)
    }
    
    func getPDBDataAndShowProtein(proteinIndex index: Int) {

        SVProgressHUD.show()
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("ligolds.txt")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download("http://files.rcsb.org/ligands/view/\(filteredNames[index])_ideal.pdb", to: destination).response { response in
            if response.error == nil, let imagePath = response.destinationURL?.path {
                do {
                    var atomCord: [Atom] = []
                    let fullText = try String(contentsOfFile: imagePath, encoding: String.Encoding.utf8)
                    let textArr = fullText.components(separatedBy: .newlines)
                    for line in textArr {
                        if line.contains("ATOM"){
                            let elem = line.components(separatedBy: " ").filter({!$0.isEmpty})
                            let newAtom = Atom(elem[1], elem[6], elem[7], elem[8], elem[11])
                            atomCord.append(newAtom)
                            self.allAtoms.append(newAtom.createAtom())
                        }
                        else if line.contains("CONECT"){
                            var coordinates:[(x: Float, y: Float, z: Float)] = []
                            let elem = line.components(separatedBy: " ").filter({!$0.isEmpty})
                            for i in 1...elem.count - 1{
                                let currConnect = atomCord[Int(elem[i])! - 1]
                                coordinates.append((x: currConnect.x, y: currConnect.y, z: currConnect.z))
                            }
                            self.allCoords.append(coordinates)
                        }
                    }
                    self.destTitle = self.filteredNames[index]
                    self.performSegue(withIdentifier: "goToScene", sender: self)
                    self.randBtn.isEnabled = true
                    self.tableView.isUserInteractionEnabled = true
                } catch {
                    SVProgressHUD.dismiss()
                    self.tableView.isUserInteractionEnabled = true
                    print(error)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToScene" {
            let destinationVC = segue.destination as! ActionViewController
            
            destinationVC.title = destTitle
            let scene = SCNScene()
            var alreadyUsedAtoms = [(x: Float, y: Float, z: Float)]()
            
            scene.rootNode.addChildNode(SCNNode())
            for node in allAtoms {
                scene.rootNode.addChildNode(node)
            }
            for atom in allCoords {
                let from = atom[0]
                alreadyUsedAtoms.append(from)
                for cord in 1...atom.count - 1 {
                    if !checkIfAlreadyUsed(atomsArray: alreadyUsedAtoms, toSearch: atom[cord]) {
                        let celinder = makeCylinder(positionStart: SCNVector3(from.x, from.y, from.z), positionEnd: SCNVector3([atom[cord].x, atom[cord].y, atom[cord].z]), radius: 0.1, color: UIColor.flatGrayDark(), transparency: 0.1)
                        scene.rootNode.addChildNode(celinder)
                    }
                }
            }
            destinationVC.scene = scene
            
            allAtoms = []
            allCoords = []
        }
        SVProgressHUD.dismiss()
    }
    
    func showAlertController(_ message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Search bar methods
extension TableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredNames = names.filter{$0.localizedCaseInsensitiveContains(searchBar.text!)}
        } else {
            filteredNames = names
        }
        tableView.reloadData()
    }
}

// MARK: - Prepare to show protein methods
extension TableViewController {
    func checkIfAlreadyUsed(atomsArray: [(x: Float, y: Float, z: Float)], toSearch: (x: Float, y: Float, z: Float)) -> Bool {
        let (x1, x2, x3) = toSearch
        for (v1, v2, v3) in atomsArray { if v1 == x1 && v2 == x2 && v3 == x3 { return true } }
        return false
    }
    
    func makeCylinder(positionStart: SCNVector3, positionEnd: SCNVector3, radius: CGFloat , color: UIColor, transparency: CGFloat) -> SCNNode
    {
        let height = CGFloat(GLKVector3Distance(SCNVector3ToGLKVector3(positionStart), SCNVector3ToGLKVector3(positionEnd)))
        let startNode = SCNNode()
        let endNode = SCNNode()
        
        startNode.position = positionStart
        endNode.position = positionEnd
        
        let zAxisNode = SCNNode()
        zAxisNode.eulerAngles.x = Float(CGFloat(Double.pi / 2))
        
        let cylinderGeometry = SCNCylinder(radius: radius, height: height)
        cylinderGeometry.firstMaterial?.diffuse.contents = color
        let cylinder = SCNNode(geometry: cylinderGeometry)
        
        cylinder.position.y = Float(-height/2)
        zAxisNode.addChildNode(cylinder)
        
        let returnNode = SCNNode()
        
        if (positionStart.x > 0.0 && positionStart.y < 0.0 && positionStart.z < 0.0 && positionEnd.x > 0.0 && positionEnd.y < 0.0 && positionEnd.z > 0.0){
            endNode.addChildNode(zAxisNode)
            endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
            returnNode.addChildNode(endNode)
        }
        else if (positionStart.x < 0.0 && positionStart.y < 0.0 && positionStart.z < 0.0 && positionEnd.x < 0.0 && positionEnd.y < 0.0 && positionEnd.z > 0.0){
            endNode.addChildNode(zAxisNode)
            endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
            returnNode.addChildNode(endNode)
        }
        else if (positionStart.x < 0.0 && positionStart.y > 0.0 && positionStart.z < 0.0 && positionEnd.x < 0.0 && positionEnd.y > 0.0 && positionEnd.z > 0.0){
            endNode.addChildNode(zAxisNode)
            endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
            returnNode.addChildNode(endNode)
        }
        else if (positionStart.x > 0.0 && positionStart.y > 0.0 && positionStart.z < 0.0 && positionEnd.x > 0.0 && positionEnd.y > 0.0 && positionEnd.z > 0.0){
            endNode.addChildNode(zAxisNode)
            endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
            returnNode.addChildNode(endNode)
        }
        else{
            startNode.addChildNode(zAxisNode)
            startNode.constraints = [ SCNLookAtConstraint(target: endNode) ]
            returnNode.addChildNode(startNode)
        }
    
        return returnNode
    }
}







