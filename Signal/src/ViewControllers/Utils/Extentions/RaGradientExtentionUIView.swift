
import Foundation

extension UIView {
    
    /* #005AF5 0%, #015DF2 18%, #0567EB 32%, #0C78DE 46%, #1690CC 55%, #23AFB5 66%, #33D49B 85%, #34D49A 90%, #3BD696 93%, #47DA91 95%, #58DE89 97%, #99F26B 100% */
     @objc static func getGradientLayerForFrame(frame:CGRect) -> UIImage {
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.frame = frame
 
//        gradientLayer.locations = [ 0.0, 0.18, 0.32, 0.46, 0.55, 0.66, 0.85, 0.90, 0.93, 0.95, 0.97]
//        //gradientLayer.borderWidth = layer.borderWidth
//
//        //gradientLayer.cornerRadius = layer.cornerRadius
//
//        gradientLayer.startPoint = CGPoint(x: 1.0, y: 1.0)
//        gradientLayer.endPoint = CGPoint(x:1.0, y: 0.0)
        
        let frame = CGRect(x: 0, y: 0, width: 375, height: 88)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.colors = [
            UIColor(hexFromString: "005AF5").cgColor,
            /*UIColor(hexFromString: "015DF2").cgColor,
            UIColor(hexFromString: "0567EB").cgColor,
            UIColor(hexFromString: "0C78DE").cgColor,
            UIColor(hexFromString: "1690CC").cgColor,
            UIColor(hexFromString: "23AFB5").cgColor,
            UIColor(hexFromString: "33D49B").cgColor,
            UIColor(hexFromString: "34D49A").cgColor,
            UIColor(hexFromString: "3BD696").cgColor,
            UIColor(hexFromString: "47DA91").cgColor,
            UIColor(hexFromString: "58DE89").cgColor,
            UIColor(hexFromString: "99F26B").cgColor*/
            UIColor(hexFromString: "33D49B").cgColor
        ]
         gradientLayer.masksToBounds = true
        gradientLayer.locations = [0.35, 1.0]
        //gradientLayer.locations = [ 0.18/*, 0.32, 0.46, 0.55, 0.66, 0.85, 0.90, 0.93, 0.95, 0.97*/]
        
        gradientLayer.startPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
        
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    @objc func setGradientForTitleView(gradientLayer:CAGradientLayer) {
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [
            UIColor(hexFromString: "005AF5").cgColor,
            UIColor(hexFromString: "015DF2").cgColor,
            UIColor(hexFromString: "0567EB").cgColor,
            UIColor(hexFromString: "0C78DE").cgColor,
            UIColor(hexFromString: "1690CC").cgColor,
            UIColor(hexFromString: "23AFB5").cgColor,
            UIColor(hexFromString: "33D49B").cgColor,
            UIColor(hexFromString: "34D49A").cgColor,
            UIColor(hexFromString: "3BD696").cgColor,
            UIColor(hexFromString: "47DA91").cgColor,
            UIColor(hexFromString: "58DE89").cgColor,
            UIColor(hexFromString: "99F26B").cgColor
        ]
        gradientLayer.locations = [ 0.0, 0.18, 0.32, 0.46, 0.55, 0.66, 0.85, 0.90, 0.93, 0.95, 0.97]
        gradientLayer.borderWidth = layer.borderWidth
     
        gradientLayer.cornerRadius = layer.cornerRadius
        
        gradientLayer.startPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x:1.0, y: 0.0)
       
        gradientLayer.masksToBounds = true
        layer.insertSublayer(gradientLayer, at: 0)
        print("Test")
    }
    @objc func setGradient90DegreesForRaButton(gradientLayer:CAGradientLayer) {
       // let gradientLayer = CAGradientLayer()
        
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [
            UIColor(hexFromString: "005AF5").cgColor,
            UIColor(hexFromString: "025FF1").cgColor,
            UIColor(hexFromString: "086EE6").cgColor,
            UIColor(hexFromString: "1286D4").cgColor,
            UIColor(hexFromString: "20A8BA").cgColor,
            UIColor(hexFromString: "33D49B").cgColor,
            UIColor(hexFromString: "50DC8C").cgColor,
            UIColor(hexFromString: "84EC74").cgColor,
            UIColor(hexFromString: "99F26B").cgColor
        ]
        gradientLayer.locations = [0.34, 0.43, 0.54, 0.66, 0.79, 0.91, 0.93, 0.97, 0.99]
        //gradientLayer.borderColor = layer.borderColor
        gradientLayer.borderWidth = 0//layer.borderWidth
        //gradientLayer.type = CAGradientLayerType.axial
        gradientLayer.cornerRadius = layer.cornerRadius
        
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x:1.0, y: 1.0)
        //gradientLayerLeft.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        gradientLayer.masksToBounds = true
        layer.insertSublayer(gradientLayer, at: 0)
       
    }
}
