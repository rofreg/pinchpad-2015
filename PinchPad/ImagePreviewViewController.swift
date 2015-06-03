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
        if (Sketch.animationFrameCount > 0){
            self.imageView.animatedImage = FLAnimatedImage(animatedGIFData: Sketch.assembleAnimatedGif()!)
        } else {
            // Or just load the current image
            var vc: ViewController = UIApplication.sharedApplication().delegate!.window!!.rootViewController as! ViewController
            self.imageView.image = vc.canvas.contentView.asImage()
        }
    }
    
    func dismiss(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}