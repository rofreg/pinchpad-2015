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
    @IBOutlet var imageView: FLAnimatedImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load animation preview
        if (Sketch.animationFrameCount > 0){
            self.imageView.animatedImage = FLAnimatedImage(animatedGIFData: Sketch.assembleAnimatedGif()!)
        } else {
            // Or just load the current image
            let vc: ViewController = UIApplication.sharedApplication().delegate!.window!!.rootViewController as! ViewController
            self.imageView.image = vc.canvas.asImage()
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}