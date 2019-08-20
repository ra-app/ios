//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

class AGBViewController: UIViewController {
    static var compl : ((Bool) -> Void)!
    
    @IBOutlet var imageViewAccepted: UIImageView!
    @IBOutlet var headerView: CustomHeaderView!
    @IBOutlet var btnContinue: GradientButton!
    
    var bAgbAccepted = false
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        headerView.titleLabel.text = "Allgemeine Geschäftsbedingungen"
//        headerView.subTitleLabel.text = "Um fortzufahren,\nlesen die AGB sorgfältig durch."
       // imageViewAccepted.layer.borderColor = UIColor.gray.cgColor
       // imageViewAccepted.layer.borderWidth = 0.5
        self.updateAGBImage()
    }

    @objc static func showAGB(inViewCtrl:UIViewController, completionHandler: @escaping (Bool) -> Void)
    {
        compl = completionHandler
        let agb = AGBViewController(nibName: "AGBViewController", bundle: nil)
        
        inViewCtrl.present(agb, animated: false, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func btnAcceptAgbTouched(_ sender: Any) {
        bAgbAccepted = !bAgbAccepted
        self.updateAGBImage()
    }
    
    func updateAGBImage() {
        if bAgbAccepted {
            self.imageViewAccepted.image = UIImage(named: "checkbox-checked-200.png")
            
        } else {
            self.imageViewAccepted.image = UIImage(named: "checkbox-200.png")
        }
        btnContinue.isEnabled = bAgbAccepted
    }
    
    @IBAction func btnContinueTouched(_ sender: Any) {
        UserDefaults.standard.set(bAgbAccepted, forKey: "agb")
        UserDefaults.standard.synchronize()
        
        self.dismiss(animated: false) {
            AGBViewController.compl(self.bAgbAccepted)
        }
    }
    
    @objc static func isAgbAccepted() -> Bool {
        return UserDefaults.standard.bool(forKey: "agb")
    }
}
