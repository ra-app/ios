
import UIKit

@objc class RaInvitationViewController : OnboardingBaseViewController {
    @IBOutlet var headerView: UIView!
    @IBOutlet var scrollView:UIScrollView!
    private var activeFieldView:UIView!
    
    @IBOutlet var codeInputField: RaTextField!
    static var compl : ((Bool) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWasShown), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillBeHidden), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        codeInputField.textField.addTarget(self, action: #selector(textFieldDidBeginEditing)
            , for: UIControl.Event.editingDidBegin)
        
        codeInputField.textField.addTarget(self, action: #selector(textFieldDidEndEditing)
            , for: UIControl.Event.editingDidEnd)
        
    
        
        self.headerView.setGradientForTitleView(gradientLayer: CAGradientLayer())
    }


    @IBAction func btnContinueTouched(_ sender: Any) {
        self.onboardingController.invitationDidComplete(viewController: self)
        //WelcomeScreenViewController.compl(true)
//        RaAGBViewController.showAGB(inViewCtrl: self) { (bRet) in
//            if bRet {
//                self.dismiss(animated: false, completion: {
//                     RaWelcomeScreenViewController.compl(true)
//                })
//            }
//        }
    }
    
//    @objc static func showWelcomeAndAGB(inViewCtrl:UIViewController, completionHandler: @escaping (Bool) -> Void)
//    {
//        compl = completionHandler
//        let welcome = RaWelcomeScreenViewController(nibName: "RaWelcomeScreenViewController", bundle: nil)
//
//        inViewCtrl.present(welcome, animated: false, completion: nil)
//    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func deregisterFromKeyboardNotifications(){
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc override func keyboardWasShown(notification: NSNotification){
        //Need to calculate keyboard exact size due to Apple suggestions
        self.scrollView.isScrollEnabled = true
        var info = notification.userInfo!
        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize!.height, right: 0.0)
        
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if let activeFieldView = self.activeFieldView {
            if (!aRect.contains(activeFieldView.frame.origin)){
                self.scrollView.scrollRectToVisible(activeFieldView.frame, animated: true)
            }
        }
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
        var info = notification.userInfo!
        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: -keyboardSize!.height, right: 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        self.view.endEditing(true)
        self.scrollView.isScrollEnabled = false
    }
    
    @objc func textFieldDidBeginEditing(_ textField: UITextField){
        activeFieldView = self.codeInputField
    }
    
   @objc func textFieldDidEndEditing(_ textField: UITextField){
        activeFieldView = nil
    }
}

private var xoAssociationKeyForBottomConstrainInVC: UInt8 = 0

extension UIViewController {
    
    var containerDependOnKeyboardBottomConstrain :NSLayoutConstraint! {
        get {
            return objc_getAssociatedObject(self, &xoAssociationKeyForBottomConstrainInVC) as? NSLayoutConstraint
        }
        set(newValue) {
            objc_setAssociatedObject(self, &xoAssociationKeyForBottomConstrainInVC, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func watchForKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWasShown(notification:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name:UIResponder.keyboardWillHideNotification, object: nil);
    }
    
    @objc func keyboardWasShown(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.containerDependOnKeyboardBottomConstrain.constant = -keyboardFrame.height
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.containerDependOnKeyboardBottomConstrain.constant = 0
            self.view.layoutIfNeeded()
        })
    }
}
