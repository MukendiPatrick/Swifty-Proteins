import Foundation
import SceneKit
import ChameleonFramework

class Atom {
    
    var x : Float
    let y : Float
    let z : Float
    let color : UIColor
    let numOfAtom : Int
    let nameOfAtom : String
    
    init(_ num: String, _ x: String, _ y: String, _ z: String, _ name: String) {
        
        self.nameOfAtom = name
        self.numOfAtom = Int(num)!
        self.x = Float(x)!
        self.y = Float(y)!
        self.z = Float(z)!
        
        if name == "H" {
            self.color = UIColor.flatWhite()
        } else if name == "C" {
            self.color = UIColor.flatBlack()
        } else if name == "N" {
            self.color = UIColor.flatBlueDark()
        } else if name == "O" {
            self.color = UIColor.flatRed()
        } else if name == "F" {
            self.color = UIColor.flatGreen()
        } else if name == "Cl" {
            self.color = UIColor.flatGreen()
        } else if name == "Br" {
            self.color = UIColor.flatRedDark()
        } else if name == "I" {
            self.color = UIColor.flatMagenta()
        } else if name == "S" {
            self.color = UIColor.flatYellow()
        } else {
            self.color = UIColor.flatPink()
        }
    }
    
    func createAtom() -> SCNNode {
        let atomShape = SCNSphere(radius: 0.4)
        atomShape.firstMaterial!.diffuse.contents = self.color
        atomShape.firstMaterial!.specular.contents = UIColor.white
        
        let atomNode = SCNNode(geometry: atomShape)
        atomNode.position = SCNVector3Make(x, y, z)
        atomNode.name = self.nameOfAtom
        
        return atomNode
    }
}

