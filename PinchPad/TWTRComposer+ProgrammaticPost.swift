//
//  TWTRComposer+ProgrammaticPost.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 3/1/15.
//
//

import TwitterKit
import SwiftyJSON

extension TWTRComposer {
    func postStatus(statusText: String, imageData: NSData, completion: (success: Bool) -> Void){
        // Some code based on https://twittercommunity.com/t/upload-images-with-swift/28410/7
        
        let strUploadUrl = "https://upload.twitter.com/1.1/media/upload.json"
        let strStatusUrl = "https://api.twitter.com/1.1/statuses/update.json"
        let twAPIClient = Twitter.sharedInstance().APIClient
        var error: NSError?
        var parameters: Dictionary = Dictionary<String, String>()
        
        // Load image data
        parameters["media"] = imageData.base64EncodedStringWithOptions([])
        
        let twUploadRequest = twAPIClient.URLRequestWithMethod("POST", URL: strUploadUrl, parameters: parameters, error: &error)
        twAPIClient.sendTwitterRequest(twUploadRequest) {
            (uploadResponse, uploadResultData, uploadConnectionError) -> Void in
            // If we encountered any errors, print and return
            if let e = uploadConnectionError ?? error {
                print("Error uploading image: \(e)")
                return completion(success: false)
            }
            
            // Parse result from JSON
            guard let rawData = uploadResultData, json = JSON(data: rawData).dictionaryObject, media_id = json["media_id_string"] as? String else {
                print("Did not get valid JSON response")
                print(uploadResultData)
                return completion(success:false)
            }
            
            // We uploaded our image successfully! Now post a status with a link to the image.
            parameters = ["status": statusText, "media_ids": media_id]
            let twStatusRequest = twAPIClient.URLRequestWithMethod("POST", URL: strStatusUrl, parameters: parameters, error: &error)
            twAPIClient.sendTwitterRequest(twStatusRequest) { (statusResponse, statusData, statusConnectionError) -> Void in
                if let e = statusConnectionError ?? error {
                    print("Error posting status: \(e)")
                    return completion(success:false)
                }
                
                completion(success:true)
            }
        }
    }
}
