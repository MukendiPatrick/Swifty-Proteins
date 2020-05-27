import UIKit
import LocalAuthentication
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn

class ViewController: UIViewController, GIDSignInUIDelegate {
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var googleBtn: GIDSignInButton!
    
    let context = LAContext()
    var error: NSError?
    var proteinsArr: [String] = []
    var dict : [String : AnyObject]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        googleBtn.colorScheme = .dark
    
        GIDSignIn.sharedInstance().uiDelegate = self
        

        button.isHidden = true
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            button.isHidden = false
        }
        
        let fileURLProject = Bundle.main.path(forResource: "ligands", ofType: "txt")
        var readStringProject = ""
        do {
            readStringProject = try String(contentsOfFile: fileURLProject!, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            print("Failed reading from URL: \(String(describing: fileURLProject)), Error: " + error.localizedDescription)
        }
        proteinsArr = readStringProject.components(separatedBy: "\n").filter({!$0.isEmpty})
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.getNotification(_:)),
                                               name: NSNotification.Name(rawValue: "AuthNotification"), object: nil)
    }
    
    @IBAction func loginButton(_ sender: Any) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "goToTableView", sender: self)
        }
    }
        
    @IBAction func authWithTouchID(_ sender: Any) {
        self.button.isEnabled = false
        
        let reason = "Authenticate with Touch ID"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason, reply:
            {(succes, error) in
                if succes {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "goToTableView", sender: self)
                        self.button.isEnabled = true
                    }
                }
                else {
                    self.showAlertController("Touch ID Authentication Failed")
                    self.button.isEnabled = true
                }
        })
    }
    
    func showAlertController(_ message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToTableView" {
            
            let destinationVC = segue.destination as! TableViewController
            destinationVC.names = proteinsArr
        }
    }
    
    @objc func getNotification(_ notification: NSNotification) {
        if notification.name.rawValue == "AuthNotification" {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "goToTableView", sender: self)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "AuthNotification"), object: nil)
    }
}
