//
//  TWTRComposer+ProgrammaticPost.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 3/1/15.
//
//

import TwitterKit

extension TWTRComposer {
    func postStatus(statusText: String, image: UIImage?, completion: (success: Bool) -> Void){
        // Some code based on https://twittercommunity.com/t/upload-images-with-swift/28410/7
        
        let strUploadUrl = "https://upload.twitter.com/1.1/media/upload.json"
        let strStatusUrl = "https://api.twitter.com/1.1/statuses/update.json"
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        var twAPIClient = Twitter.sharedInstance().APIClient
        var error: NSError?
        var parameters: Dictionary = Dictionary<String, String>()
        
        // Load image data
        var imageData : NSData = UIImagePNGRepresentation(image)
        parameters["media"] = imageData.base64EncodedStringWithOptions(nil)
        
        // TODO: GIF handling
        // let path = NSBundle.mainBundle().pathForResource("SampleAnim", ofType: "GIF")
        // var animData : NSData = NSData(contentsOfFile: path!)!
        // parameters["media"] = animData.base64EncodedStringWithOptions(nil)
        
        if let twUploadRequest = twAPIClient.URLRequestWithMethod("POST", URL: strUploadUrl, parameters: parameters, error: &error){
            twAPIClient.sendTwitterRequest(twUploadRequest) {
                (uploadResponse, uploadResultData, uploadConnectionError) -> Void in
                if let e = uploadConnectionError{
                    println("Error uploading image: \(e)")
                } else {
                    // Parse result with SwiftyJSON
                    var parseError: NSError?
                    let parsedObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(uploadResultData!,
                        options: NSJSONReadingOptions.AllowFragments,
                        error:&parseError)
                    
                    if let json = parsedObject as? NSDictionary {
                        let media_id = json["media_id_string"] as! String
                        
                        // We uploaded our image successfully! Now post a status with a link to the image.
                        parameters = Dictionary<String, String>()
                        parameters["status"] = statusText
                        parameters["media_ids"] = media_id
                        if let twStatusRequest = twAPIClient.URLRequestWithMethod("POST", URL: strStatusUrl, parameters: parameters, error: &error){
                            twAPIClient.sendTwitterRequest(twStatusRequest) { (statusResponse, statusData, statusConnectionError) -> Void in
                                if let e = statusConnectionError{
                                    println("Error posting status: \(e)")
                                    completion(success:false)
                                } else {
                                    completion(success:true)
                                }
                            } // completion
                        } else {
                            println("Error creating status request \(error)")
                            completion(success:false)
                        }
                    } else {
                        println("Did not get json response")
                        println(parsedObject)
                        completion(success:false)
                    }
                }
            } // completion
        } else {
            println("Error creating upload request \(error)")
            completion(success:false)
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}
