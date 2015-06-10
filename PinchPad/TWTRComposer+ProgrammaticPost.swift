//
//  TWTRComposer+ProgrammaticPost.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 3/1/15.
//
//

import TwitterKit

extension TWTRComposer {
    func postStatus(statusText: String, imageData: NSData, completion: (success: Bool) -> Void){
        // Some code based on https://twittercommunity.com/t/upload-images-with-swift/28410/7
        
        let strUploadUrl = "https://upload.twitter.com/1.1/media/upload.json"
        let strStatusUrl = "https://api.twitter.com/1.1/statuses/update.json"
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        var twAPIClient = Twitter.sharedInstance().APIClient
        var error: NSError?
        var parameters: Dictionary = Dictionary<String, String>()
        
        // Load image data
        parameters["media"] = imageData.base64EncodedStringWithOptions(nil)
        
        let twUploadRequest = twAPIClient.URLRequestWithMethod("POST", URL: strUploadUrl, parameters: parameters, error: &error)
        twAPIClient.sendTwitterRequest(twUploadRequest) {
            (uploadResponse, uploadResultData, uploadConnectionError) -> Void in
            if let e = uploadConnectionError{
                println("Error uploading image: \(e)")
            } else {
                // Parse result from JSON
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
                    let twStatusRequest = twAPIClient.URLRequestWithMethod("POST", URL: strStatusUrl, parameters: parameters, error: &error)
                
                    twAPIClient.sendTwitterRequest(twStatusRequest) { (statusResponse, statusData, statusConnectionError) -> Void in
                        if let e = statusConnectionError{
                            println("Error posting status: \(e)")
                            completion(success:false)
                        } else {
                            completion(success:true)
                        }
                    } // completion
                } else {
                    println("Did not get json response")
                    println(parsedObject)
                    completion(success:false)
                }
            }
        } // completion
            
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}
