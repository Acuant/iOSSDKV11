//
//  Utils.swift
//  SampleApp
//
//  Created by Tapas Behera on 7/12/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//
import Foundation
public class Utils {
    public static func dateFieldToDateString(dateStr : String?) -> String?{
        var dateString = dateStr?.replacingOccurrences(of: "Date", with: "")
        dateString = dateString?.replacingOccurrences(of: "/", with: "")
        dateString = dateString?.replacingOccurrences(of: "(", with: "")
        dateString = dateString?.replacingOccurrences(of: ")", with: "")
        if let num = Int(dateString!) {
            let date = Date(timeIntervalSince1970: TimeInterval(num/1000))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy"
            dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
            let retStr = dateFormatter.string(from: date)
            return retStr;
        }
        return dateStr
    }
    
    public static func getAuthResultString(authResult:Int)->String {
        var returnValue = "Unknown"
        
        switch authResult {
        case 0:
            returnValue = "Unknown"
            break
        case 1:
            returnValue = "Passed"
            break
        case 2:
            returnValue = "Failed"
            break
        case 3:
            returnValue = "Skipped"
            break
        case 4:
            returnValue = "Caution"
            break
        case 5:
            returnValue = "Attention"
            break
        default:
            returnValue = "Unknown"
        }
        return returnValue;
    }
}
