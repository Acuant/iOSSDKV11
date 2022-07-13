//
//  AcuantMrzParser.swift
//  AcuantNFC
//
//  Created by John Moon local on 10/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation

public class AcuantMrzParser {
    private let FILLER: Character = "<"
    private let PASSPORT_FIRST_VALUE = "P"
    private let CHECK_SUM_ARRAY = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    private let characterSubstitutions = [("O", "0")]
    
    public init() { }
    
    public func parseMrz(mrz: String) -> AcuantMrzResult? {
        let mrzWithNoSpaces = mrz.replacingOccurrences(of: " ",  with: "")
        print(mrzWithNoSpaces)
        let mrzLines = mrzWithNoSpaces.split(separator: "\n")
        var result: AcuantMrzResult?
        if mrzLines.count == 2, let firstLineResult = parseFirstLineOfTwo(firstLine: String(mrzLines[0])) {
            result = parseSecondLineOfTwo(line: String(mrzLines[1]), result: firstLineResult)
            result?.threeLineMrz = false
        } else if mrzLines.count == 3, let firstLineResult = parseFirstLineOfThree(firstLine: String(mrzLines[0])) {
            result = parseSecondLineOfThree(line: String(mrzLines[1]), result: firstLineResult)
            result?.threeLineMrz = true
        }
        result?.cleanFields()
        return result
    }

    private func parseFirstLineOfThree(firstLine: String) -> AcuantMrzResult? {
        guard firstLine.count == 30 else {
            return nil
        }

        var startPos = 0
        let result = AcuantMrzResult()

        startPos += 2

        result.country = getSubstring(str: firstLine, offsetStart: startPos, offsetEnd: startPos + 3)
        startPos += 3

        result.passportNumber = getSubstring(str: firstLine, offsetStart: startPos, offsetEnd: startPos + 9)
        startPos += 9

        result.checkSumDigit1 = firstLine[startPos]
        let subPassportNumber = getPossibleSubstitution(text: result.passportNumber, checkSumDigit: result.checkSumDigit1)
        result.passportNumber = subPassportNumber.text
        result.checkSumDigit1 = subPassportNumber.checkSumDigit
        result.checkSumResult1 = checkSum(text: result.passportNumber, checkSumDigit: result.checkSumDigit1)
        startPos += 1

        result.optional1 = getSubstring(str: firstLine, offsetStart: startPos, offsetEnd: startPos + 15)

        return result
    }

    private func parseSecondLineOfThree(line: String, result: AcuantMrzResult) -> AcuantMrzResult? {
        guard line.count == 30 else {
            return nil
        }

        var startPos = 0

        result.dob = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos + 6)
        startPos += 6

        result.checkSumDigit2 = line[startPos]
        let subDob = getPossibleSubstitution(text: result.dob, checkSumDigit: result.checkSumDigit2)
        result.dob = subDob.text
        result.checkSumDigit2 = subDob.checkSumDigit
        result.checkSumResult2 = checkSum(numbers: result.dob, checkSumDigit: result.checkSumDigit2)
        startPos += 1

        result.gender = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos + 1)
        startPos += 1

        result.passportExpiration = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos + 6)
        startPos += 6

        result.checkSumDigit3 = line[startPos]
        let subPassportExpiration = getPossibleSubstitution(text: result.passportExpiration, checkSumDigit: result.checkSumDigit3)
        result.passportExpiration = subPassportExpiration.text
        result.checkSumDigit3 = subPassportExpiration.checkSumDigit
        result.checkSumResult3 = checkSum(numbers: result.passportExpiration, checkSumDigit: result.checkSumDigit3)
        startPos += 1
        
        result.nationality = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos + 3)
        startPos += 3

        let optional2 = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos + 11)
        startPos += 11
        
        let finalCheckString = "\(result.passportNumber)\(result.checkSumDigit1)\(result.optional1)\(result.dob)\(result.checkSumDigit2)\(result.passportExpiration)\(result.checkSumDigit3)\(optional2)"
        
        result.checkSumResult4 = checkSum(text: finalCheckString, checkSumDigit: line[startPos])
        
        result.checkSumResult5 = true

        return result
    }

    private func parseFirstLineOfTwo(firstLine: String) -> AcuantMrzResult? {
        var startPos = 0
        guard firstLine[startPos] == PASSPORT_FIRST_VALUE, firstLine.count == 44 else {
            return nil
        }

        let result = AcuantMrzResult()

        startPos += 2

        result.country = getSubstring(str: firstLine, offsetStart: startPos, offsetEnd: startPos + 3)
        startPos += 3

        var nextPos = indexOf(str: firstLine, data: FILLER, offSetStart: startPos)
        if nextPos != -1 {
            result.surName = getSubstring(str: firstLine, offsetStart: startPos, offsetEnd: nextPos)
        }
        startPos = nextPos + 2

        nextPos = indexOf(str: firstLine, data: FILLER, offSetStart: startPos)
        if nextPos != -1 {
            result.givenName = getSubstring(str: firstLine, offsetStart: startPos, offsetEnd: nextPos)
        }

        return result
    }

    private func parseSecondLineOfTwo(line: String, result: AcuantMrzResult) -> AcuantMrzResult? {
        guard line.count == 44 else {
            return nil
        }

        var startPos = 0
        result.passportNumber = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos + 9)
        startPos += 9

        result.checkSumDigit1 = line[startPos]
        let subPassportNumber = getPossibleSubstitution(text: result.passportNumber, checkSumDigit: result.checkSumDigit1)
        result.passportNumber = subPassportNumber.text
        result.checkSumDigit1 = subPassportNumber.checkSumDigit
        result.checkSumResult1 = checkSum(text: result.passportNumber, checkSumDigit: result.checkSumDigit1)
        startPos += 1

        result.nationality = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos + 3)
        startPos += 3

        result.dob = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos + 6)
        startPos += 6

        result.checkSumDigit2 = line[startPos]
        let subDob = getPossibleSubstitution(text: result.dob, checkSumDigit: result.checkSumDigit2)
        result.dob = subDob.text
        result.checkSumDigit2 = subDob.checkSumDigit
        result.checkSumResult2 = checkSum(numbers: result.dob, checkSumDigit: result.checkSumDigit2)
        startPos += 1

        result.gender = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos + 1)
        startPos += 1

        result.passportExpiration = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos + 6)
        startPos += 6

        result.checkSumDigit3 = line[startPos]
        let subPassportExpiration = getPossibleSubstitution(text: result.passportExpiration, checkSumDigit: result.checkSumDigit3)
        result.passportExpiration = subPassportExpiration.text
        result.checkSumDigit3 = subPassportExpiration.checkSumDigit
        result.checkSumResult3 = checkSum(numbers: result.passportExpiration, checkSumDigit: result.checkSumDigit3)
        startPos += 1

        result.personalDocNumber = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos + 14)
        startPos += 14
        
        result.checkSumDigit4 = line[startPos]
        let subPersonalDocNumber = getPossibleSubstitution(text: result.personalDocNumber, checkSumDigit: result.checkSumDigit4)
        result.personalDocNumber = subPersonalDocNumber.text
        result.checkSumDigit4 = subPersonalDocNumber.checkSumDigit
        result.checkSumResult4 = checkSum(text: result.personalDocNumber, checkSumDigit: result.checkSumDigit4)
        startPos += 1
        
        let finalCheckString = "\(result.passportNumber)\(result.checkSumDigit1)\(result.dob)\(result.checkSumDigit2)\(result.passportExpiration)\(result.checkSumDigit3)\(result.personalDocNumber)\(result.checkSumDigit4)"

        result.checkSumDigit5 = line[startPos]
        result.checkSumResult5 = checkSum(text: finalCheckString, checkSumDigit: result.checkSumDigit5)

        return result
    }

    private func getPossibleSubstitution(text: String, checkSumDigit: String) -> (text: String, checkSumDigit: String) {
        guard !checkSum(text: text, checkSumDigit: checkSumDigit) else {
            return (text, checkSumDigit)
        }

        for substitution in characterSubstitutions {
            if checkSumDigit == substitution.0, checkSum(text: text, checkSumDigit: substitution.1) {
                return (text, substitution.1)
            } else if checkSumDigit == substitution.1, checkSum(text: text, checkSumDigit: substitution.0) {
                return (text, substitution.0)
            }

            var substituedText = text.replacingOccurrences(of: substitution.0, with: substitution.1)
            if checkSum(text: substituedText, checkSumDigit: checkSumDigit) {
                return (substituedText, checkSumDigit)
            } else {
                if checkSumDigit == substitution.0, checkSum(text: substituedText, checkSumDigit: substitution.1) {
                    return (substituedText, substitution.1)
                } else if checkSumDigit == substitution.1, checkSum(text: substituedText, checkSumDigit: substitution.0) {
                    return (substituedText, substitution.0)
                }
            }

            substituedText = text.replacingOccurrences(of: substitution.1, with: substitution.0)
            if checkSum(text: substituedText, checkSumDigit: checkSumDigit) {
                return (substituedText, checkSumDigit)
            } else {
                if checkSumDigit == substitution.0, checkSum(text: substituedText, checkSumDigit: substitution.1) {
                    return (substituedText, substitution.1)
                } else if checkSumDigit == substitution.1, checkSum(text: substituedText, checkSumDigit: substitution.0) {
                    return (substituedText, substitution.0)
                }
            }
        }

        return (text, checkSumDigit)
    }

    private func checkSum(numbers: String, checkSumDigit: String) -> Bool {
        guard numbers.isNumeric else {
            return false
        }

        return checkSum(text: numbers, checkSumDigit: checkSumDigit)
    }

    private func checkSum(text: String, checkSumDigit: String) -> Bool {
        guard checkSumDigit.isNumeric || checkSumDigit == String(FILLER) else {
            return false
        }

        var count = 0
        let checkSumValue = getValue(character: checkSumDigit)
        for i in 0..<text.count {
            count += getValue(character: text[i]) * getWeight(position: i)
        }
        return checkSumValue == count % 10
    }

    private func getWeight(position: Int) -> Int {
        if position % 3 == 0 {
            return 7
        } else if position % 3 == 1 {
            return 3
        } else {
            return 1
        }
    }

    private func getValue(character: String) -> Int {
        if let value = CHECK_SUM_ARRAY.firstIndex(of: character), value > 0 {
            return value
        }
        return 0
    }

    private func indexOf(str: String, data: Character, offSetStart: Int) -> Int {
        var counter = 0
        for char in str {
            if counter >= offSetStart {
                if char == data {
                    return counter
                }
            }
            counter += 1
        }
        return -1
    }

    private func getSubstring(str: String, offsetStart: Int, offsetEnd: Int) -> String {
        let start = str.index(str.startIndex, offsetBy: offsetStart)
        let end = str.index(str.startIndex, offsetBy: offsetEnd)
        return String(str[start..<end])
    }

}
