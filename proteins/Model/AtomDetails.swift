import SceneKit
import Foundation
import SwiftyJSON
import ChameleonFramework

class AtomDetails {
    
    var name : String?
    var symb : String?
    var melt : Double?
    var boil : Double?
    var summary : String?
    var appearence : String?
    var atomic_mass : Double?
    
    init(json : JSON){
        
        if let name = json["name"].string{
            self.name = name
        }
        if let symb = json["symbol"].string{
            self.symb = symb
        }
        if let melt = json["melt"].double{
            self.melt = melt
        }
        if let boil = json["boil"].double{
            self.boil = boil
        }
        if let summary = json["summary"].string{
            self.summary = summary
        }
        if let appearence = json["appearance"].string{
            self.appearence = appearence
        }
        if let atom_mass = json["atomic_mass"].double{
            self.atomic_mass = atom_mass
        }
    }
}


