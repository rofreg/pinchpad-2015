//
//  ImagePreviewViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/27/15.
//
//

import UIKit
import FLAnimatedImage

class ImagePreviewViewController : UIViewController{
    let tapRecognizer = UITapGestureRecognizer()
    @IBOutlet var imageView: FLAnimatedImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapRecognizer.addTarget(self, action: Selector("dismiss"))
        self.view.addGestureRecognizer(tapRecognizer)
        
        // Load animation preview
        self.imageView.animatedImage = FLAnimatedImage(animatedGIFData: Sketch.assembleAnimatedGif()!)
    }
    
    func dismiss(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}