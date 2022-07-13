//
//  AcuantMrzResult.swift
//  AcuantNFC
//
//  Created by John Moon local on 10/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation

@objcMembers public class AcuantMrzResult: NSObject {
    public var surName: String = ""
    public var givenName: String = ""
    public var country: String = ""
    public var passportNumber: String = ""
    public var nationality: String = ""
    public var dob: String = ""
    public var gender: String = ""
    public var passportExpiration: String = ""
    public var personalDocNumber: String = ""
    public var optional1: String = ""
    public var checkSumResult1: Bool = false
    public var checkSumResult2: Bool = false
    public var checkSumResult3: Bool = false
    public var checkSumResult4: Bool = false
    public var checkSumResult5: Bool = false
    public var threeLineMrz: Bool = false
    var checkSumDigit1: String = ""
    var checkSumDigit2: String = ""
    var checkSumDigit3: String = ""
    var checkSumDigit4: String = ""
    var checkSumDigit5: String = ""

    func cleanFields(character: String = "<") {
        surName = surName.replacingOccurrences(of: character, with: "")
        givenName = givenName.replacingOccurrences(of: character, with: "")
        country = country.replacingOccurrences(of: character, with: "")
        passportNumber = passportNumber.replacingOccurrences(of: character, with: "")
        nationality = nationality.replacingOccurrences(of: character, with: "")
        dob = dob.replacingOccurrences(of: character, with: "")
        gender = gender.replacingOccurrences(of: character, with: "")
        passportExpiration = passportExpiration.replacingOccurrences(of: character, with: "")
        personalDocNumber = personalDocNumber.replacingOccurrences(of: character, with: "")
    }
}
