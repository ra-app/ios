//
//  GradientButton.swift
//  Testing
//
//  Created by Lars Thode on 13.08.19.
//  Copyright © 2019 Jurasoft. All rights reserved.
//

import UIKit

@IBDesignable
@objc class RaGradientButton: UIButton {
    let gradientLayer = CAGradientLayer()
    
    
    public override func awakeFromNib() {
        self.layer.cornerRadius = 20
        setGradient90DegreesForRaButton(gradientLayer: gradientLayer)
        self.titleLabel?.font = UIFont(name: "Poppins-Regular", size: 15)
        self.titleLabel?.textColor = .white
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setGradient90DegreesForRaButton(gradientLayer: gradientLayer)
    }
    
    /* background: transparent linear-gradient(90deg, #005AF5 34%, #025FF1 43%, #086EE6 54%, #1286D4 66%, #20A8BA 79%, #33D49B 91%, #50DC8C 93%, #84EC74 97%, #99F26B 99%) 0% 0% no-repeat padding-box;
     */
    
    /*private func setGradient90DegreesForRaButton() {
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
        
        layer.insertSublayer(gradientLayer, below: titleLabel?.layer)
    }*/
}

