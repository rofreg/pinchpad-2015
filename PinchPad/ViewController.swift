//
//  ViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/2/15.
//
//

import UIKit
import TwitterKit
import TMTumblrSDK
import Locksmith

class ViewController: UIViewController{
    @IBOutlet var canvas: CanvasScrollView!
    @IBOutlet var toolConfigViewContainer: UIView!
    @IBOutlet var menuViewContainer: UIView!
    @IBOutlet var pendingPostsView: UIView!
    @IBOutlet var pendingPostsLabel: UILabel!
    @IBOutlet var pendingPostsRetryButton: UIButton!
    
    @IBOutlet var pencilButton: UIBarButtonItem!
    @IBOutlet var eraserButton: UIBarButtonItem!
    
    var lastTool = Tool.Brush
   
    override func viewDidLoad() {
        // When our data changes, update the display
        self.updatePendingPostsDisplay()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.updatePendingPostsDisplay), name: NSManagedObjectContextObjectsDidChangeNotification, object: nil)
        
        // When our tool changes, update the display
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.updateToolbarDisplay), name: "ToolConfigChanged", object: nil)
        
        // Clear canvas when we are told to
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.clear), name: "ClearCanvas", object: nil)
        
        // Enable Adonit support
        enableAdonitShortcutButtons()
        
        super.viewDidLoad()
    }
    
    
    // MARK: Adonit handling
    
    func enableAdonitShortcutButtons() {
        let undoShortcut = JotShortcut.init(descriptiveText: "Undo", key: "undo", target: self, selector: #selector(ViewController.undo))
        let redoShortcut = JotShortcut.init(descriptiveText: "Redo", key: "redo", target: self, selector: #selector(ViewController.redo))
        
        JotStylusManager.sharedInstance().addShortcutOptionButton1Default(undoShortcut)
        JotStylusManager.sharedInstance().addShortcutOptionButton2Default(redoShortcut)
    }
    
    
    // MARK: Screen rotation
    
    override func shouldAutorotate() -> Bool {
        return false
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        // For the main drawing view, restrict rotation to portrait
        return UIInterfaceOrientationMask.Portrait
    }
    
    
    // MARK: tool handling
    
    @IBAction func menu(){
        toolConfigViewContainer.hidden = true
        menuViewContainer.hidden = !menuViewContainer.hidden
    }
    
    @IBAction func pencil(){
        menuViewContainer.hidden = true
        if (ToolConfig.sharedInstance.tool != .Eraser){
            // Toggle config menu if the pencil or brush is already selected
            toolConfigViewContainer.hidden = !toolConfigViewContainer.hidden
        } else {
            // Otherwise, switch to last tool
            ToolConfig.sharedInstance.tool = lastTool
        }
    }
    
    @IBAction func eraser(){
        menuViewContainer.hidden = true
        if (ToolConfig.sharedInstance.tool == .Eraser){
            // Toggle config menu if the eraser is already selected
            toolConfigViewContainer.hidden = !toolConfigViewContainer.hidden
        } else {
            // Otherwise, switch to eraser (but remember what tool we were using last)
            lastTool = ToolConfig.sharedInstance.tool
            ToolConfig.sharedInstance.tool = .Eraser
        }
    }
    
    @IBAction func undo(){
        self.canvas.undo()
    }
    
    @IBAction func redo(){
        self.canvas.redo()
    }
    
    @IBAction func post(sender: AnyObject){
        // Some code based on https://twittercommunity.com/t/upload-images-with-swift/28410/7
        
        // Don't post if we haven't drawn any strokes
        if (self.canvas.contentView.strokes.count == 0 && Sketch.animationFrameCount == 0){
            let alert = UIAlertController(title: "Your sketch is blank", message: "You haven't drawn anything yet, silly!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        // Get the image data
        let imageData: NSData
        if (Sketch.animationFrameCount == 0){
            // This is a normal sketch; just grab the current canvas
            imageData = self.canvas.contentView.asNSData()
        } else {
            // This is an animation! We need to assemble a GIF (and clear our stored GIF frames from the DB)
            imageData = Sketch.assembleAnimatedGif()!
            Sketch.clearAnimationFrames()
        }

        // If we're not logged into any services, let's just share this using the native iOS dialog
        if (AuthManager.loggedInServices().count == 0){
            let vc = UIActivityViewController(activityItems: [imageData], applicationActivities: nil)
            if (sender.isKindOfClass(UIBarButtonItem)){
                vc.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            }
            self.presentViewController(vc, animated: true, completion: nil)
            return
        }
        
        // Format the date
        let date = NSDate(), dateFormatter = NSDateFormatter(), timeFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        timeFormatter.dateFormat = "h:mma"
        let caption = "\(dateFormatter.stringFromDate(date)), \(timeFormatter.stringFromDate(date).lowercaseString)"
        
        // Actually post
        for service in AuthManager.loggedInServices(){
            print("Posting to service #\(service.rawValue+1)")
            AuthManager.enqueue(service, imageData: imageData, caption: caption)
        }
        
        // Clear the canvas
        self.clear()
    }
    
    
    // MARK: Other menu-related functions
    
    func clear(){
        self.canvas.clear()
        self.menuViewContainer.hidden = true
        self.toolConfigViewContainer.hidden = true
    }
    
    
    // MARK: Pending post display handling
    
    func updatePendingPostsDisplay(){
        let fetchRequest = NSFetchRequest(entityName: "Sketch")
        fetchRequest.predicate = NSPredicate(format: "(syncStarted == nil OR syncStarted > %@) AND (duration = 0)", NSDate().dateByAddingTimeInterval(-60))
        let unsynced = try? Sketch.managedContext.executeFetchRequest(fetchRequest)
        
        fetchRequest.predicate = NSPredicate(format: "syncError == true AND duration = 0")
        let syncErrors = try? Sketch.managedContext.executeFetchRequest(fetchRequest)
        
        if let syncErrors = syncErrors where syncErrors.count > 0{
            pendingPostsView.alpha = 1
            pendingPostsRetryButton.hidden = false
            let pluralPosts = (syncErrors.count == 1 ? "post" : "posts")
            pendingPostsLabel.text = "\(syncErrors.count) \(pluralPosts) failed to sync"
        } else if let unsynced = unsynced where unsynced.count > 0{
            pendingPostsView.alpha = 1
            pendingPostsRetryButton.hidden = true
            pendingPostsLabel.text = "Posting..."
        } else {
            pendingPostsRetryButton.hidden = true
            pendingPostsLabel.text = "Post submitted!"
            UIView.animateWithDuration(0.5, delay: 2.0, options: [], animations: { () -> Void in
                self.pendingPostsView.alpha = 0
            }, completion: nil)
        }
    }
    
    @IBAction func retry(){
        AuthManager.sync()
    }
    
    
    // MARK: Toolbar display handling
    
    func updateToolbarDisplay(){
        if (ToolConfig.sharedInstance.tool == .Eraser){
            pencilButton.tintColor = UIColor.lightGrayColor()
            eraserButton.tintColor = self.view.tintColor
        } else {
            pencilButton.tintColor = self.view.tintColor
            eraserButton.tintColor = UIColor.lightGrayColor()
        }
    }
}