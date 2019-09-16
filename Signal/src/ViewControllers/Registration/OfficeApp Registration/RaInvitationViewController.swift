
import UIKit

@objc class RaInvitationViewController : OnboardingBaseViewController, UITextFieldDelegate {
    @IBOutlet var headerView: UIView!
    @IBOutlet var codeInputField: RaTextField!
    @IBOutlet var labelDownloadHint: UILabel!
    
    static var compl : ((Bool) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.headerView.setGradientForTitleView(gradientLayer: CAGradientLayer())
        
       // codeInputField.textField.addTarget(self, action: #selector(textFieldDidBeginEditing)
       //     , for: UIControl.Event.editingDidBegin)
        
        codeInputField.textField.addTarget(self, action: #selector(textFieldDidEndEditing)
            , for: UIControl.Event.editingDidEnd)
        
        codeInputField.textField.keyboardType = .numbersAndPunctuation
        codeInputField.textField.delegate = self
        
        
        let str = labelDownloadHint.text
        
        let range = NSString(string: str!).range(of: "www.officeapp.eu", options: String.CompareOptions.caseInsensitive)
       
        let attrStr = NSMutableAttributedString.init(string:str!)
        
        attrStr.addAttributes([NSAttributedString.Key.underlineStyle: NSUnderlineStyle.thick.rawValue as Any],range: range)
        labelDownloadHint.attributedText = attrStr
    }


    @IBAction func btnContinueTouched(_ sender: Any) {
        self.onboardingController.invitationDidComplete(viewController: self)
    }
  
    @objc func textFieldDidEndEditing(_ textField: UITextField){
      
    }
    
    @IBAction func registerTouched(_ sender: Any) {
        guard let url = URL(string: "http://officeapp.eu") else { return }
        UIApplication.shared.open(url)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

