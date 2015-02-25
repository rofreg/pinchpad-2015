//
//  PPToolConfigurationView.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/8/15.
//
//

import UIKit

class PPToolConfigurationViewController: UIViewController{
    var delegate: PPToolConfigurationViewControllerDelegate?
    
    @IBAction func widthChanged(sender: UISlider){
        if let d = delegate{
            d.widthChanged(sender.value)
        }
    }
}


protocol PPToolConfigurationViewControllerDelegate {
    func widthChanged(value: Float)
}