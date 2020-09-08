//
//  AcuantTokenService.swift
//  SampleApp
//
//  Created by John Moon local on 7/28/20.
//  Copyright © 2020 com.acuant. All rights reserved.
//

import Foundation
import AcuantCommon

public protocol IAcuantTokenService{
    func getTask(callback: @escaping (String?) -> ()) -> URLSessionTask?
}

public class AcuantTokenService: IAcuantTokenService{
    public init() { }
    public func getTask(callback: @escaping (String?) -> ()) -> URLSessionTask?{
        let session = URLSession.shared
        
        if  let endpoint = Credential.endpoints()?.acasEndpoint,
            let urlPath = NSURL(string: "\(endpoint)/oauth/token"),
            let username = Credential.username(),
            let password = Credential.password()
        {
            let request = NSMutableURLRequest(url: urlPath as URL)
            
            let sub = (Credential.subscription() != nil && !Credential.subscription()!.isEmpty) ? "\(Credential.subscription()!);" : ""
            let utf8str = (sub + username+":"+password).data(using: String.Encoding.utf8)
            let authValue = "Basic \(utf8str?.base64EncodedString() ?? "")"
            
            request.timeoutInterval = 60
            request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
            request.addValue(authValue, forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = "{\"grant_type\": \"client_credentials\"}".data(using: .utf8)
            
            let task = session.dataTask(with: request as URLRequest) { data,response,error in
                let httpResponse = response as? HTTPURLResponse
                
                if(httpResponse?.statusCode == 200 && data != nil){
                    if let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                        if let token = json["access_token"] as? String{
                            callback(token)
                        }
                        else{
                            callback(nil)
                        }
                    }
                }
                else{
                    callback(nil)
                }
            }
            return task
        }
        else{
            callback(nil)
            return nil
        }
    }
}
