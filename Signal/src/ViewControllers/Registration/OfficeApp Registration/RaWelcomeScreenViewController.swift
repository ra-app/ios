//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

@objc class RaWelcomeScreenViewController : OnboardingBaseViewController {
    @IBOutlet var headerView: UIView!
    static var compl : ((Bool) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.headerView.setGradientForTitleView(gradientLayer: CAGradientLayer())
        self.view.backgroundColor = Theme.backgroundColor
    }


    @IBAction func btnContinueTouched(_ sender: Any) {
        self.onboardingController.welcomeDidComplete(viewController: self)
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

}
