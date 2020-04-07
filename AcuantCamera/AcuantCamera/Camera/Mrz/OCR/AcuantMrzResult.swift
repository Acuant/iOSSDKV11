//
//  AcuantMrzResult.swift
//  AcuantNFC
//
//  Created by John Moon local on 10/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation

@objcMembers public class AcuantMrzResult : NSObject{
    public var surName:String = ""
    public var givenName:String = ""
    public var country:String = ""
    public var passportNumber: String = ""
    public var nationality:String = ""
    public var dob: String = ""
    public var gender: String = ""
    public var passportExpiration: String = ""
    public var personalDocNumber: String = ""
    public var checkSumResult1: Bool = false
    public var checkSumResult2: Bool = false
    public var checkSumResult3: Bool = false
    public var checkSumResult4: Bool = false
    public var checkSumResult5: Bool = false
}
