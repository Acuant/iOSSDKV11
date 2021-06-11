//
//  AcuantMrzParser.swift
//  AcuantNFC
//
//  Created by John Moon local on 10/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation

public class AcuantMrzParser{
    private let FILLER : Character = "<"
    private let PASSPORT_FIRST_VALUE = "P"
    
    public init(){
        
    }
    
    private func indexOf(str: String, data: Character, offSetStart:Int) -> Int{
        var counter = 0
        for char in str{
            if(counter >= offSetStart){
                if(char == data){
                    return counter
                }
            }
            counter += 1
        }
        return -1
    }

    private func getSubstring(str: String, offsetStart: Int, offsetEnd: Int) -> String{
        let start = str.index(str.startIndex, offsetBy: offsetStart)
        let end = str.index(str.startIndex, offsetBy: offsetEnd)
        return str.substring(with: start..<end)
    }

    private func parseFirstLineOfThree(firstLine:String) -> AcuantMrzResult?{
        var startPos = 0
        if(firstLine.count == 30){
            let result = AcuantMrzResult()

            startPos += 1
            //let type = firstLine[startPos]
            startPos += 1

            result.country = getSubstring(str: firstLine, offsetStart: startPos, offsetEnd: startPos + 3)
            startPos += 3
            
            result.passportNumber = getSubstring(str: firstLine, offsetStart: startPos, offsetEnd: startPos+9)//.replacingOccurrences(of: "<", with: "")
            startPos += 9
            
            result.checkSumChar1 = firstLine[startPos]
            startPos += 1
            
            result.checkSumResult1 = checkSum(input: result.passportNumber, checkSumChar: result.checkSumChar1)
            
            result.optional1 = getSubstring(str: firstLine, offsetStart: startPos, offsetEnd: startPos + 15)

            return result
        }
        return nil
    }

    private func parseSecondLineOfThree(line: String, result: AcuantMrzResult) -> AcuantMrzResult?{
        if(line.count != 30){
            return nil
        }

        var startPos = 0

        result.dob = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos+6)
        startPos+=6

        let checkChar2 = line[startPos]
        startPos+=1
        
        result.checkSumResult2 = checkSum(input: result.dob, checkSumChar: checkChar2)

        result.gender = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos+1)
        startPos+=1

        result.passportExpiration = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos+6)
        startPos+=6

        let checkChar3 = line[startPos]
        startPos+=1
        
        result.checkSumResult3 = checkSum(input: result.passportExpiration, checkSumChar: checkChar3)
        
        result.nationality = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos+3)
        startPos+=3

        let optional2 = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos+11)
        startPos+=11
        
        let finalCheckString = "\(result.passportNumber)\(result.checkSumChar1)\(result.optional1)\(result.dob)\(checkChar2)\(result.passportExpiration)\(checkChar3)\(optional2)"
        
        result.checkSumResult4 = checkSum(input: finalCheckString, checkSumChar: line[startPos])
        
        result.checkSumResult5 = true
        
        result.passportNumber = result.passportNumber.replacingOccurrences(of: "<", with: "")

        return result
    }

    private func parseFirstLineOfTwo(firstLine:String) -> AcuantMrzResult?{
        var startPos = 0
        if(firstLine[startPos] == PASSPORT_FIRST_VALUE && firstLine.count == 44){
            let result = AcuantMrzResult()

            startPos+=1
            //let type = firstLine[startPos]
            startPos += 1

            result.country = getSubstring(str: firstLine, offsetStart: startPos, offsetEnd: startPos + 3)
            startPos += 3
            
            var nextPos = indexOf(str: firstLine, data: FILLER, offSetStart: startPos)
            if(nextPos != -1){
                result.surName = getSubstring(str: firstLine, offsetStart: startPos, offsetEnd: nextPos)
            }
            startPos = nextPos + 2

            
            nextPos = indexOf(str: firstLine, data: FILLER, offSetStart: startPos)
            if(nextPos != -1){
                result.givenName = getSubstring(str: firstLine, offsetStart: startPos, offsetEnd: nextPos)
            }

            return result
        }
        return nil
    }

    private func parseSecondLineOfTwo(line:String, result: AcuantMrzResult) -> AcuantMrzResult?{
        if(line.count != 44){
            return nil
        }

        var startPos = 0
        result.passportNumber = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos+9)
        startPos+=9

        result.checkSumResult1 = checkSum(input: result.passportNumber, checkSumChar: line[startPos])
        startPos+=1

        result.nationality = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos+3)
        startPos+=3

        result.dob = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos+6)
        startPos+=6

        result.checkSumResult2 = checkSum(input: result.dob, checkSumChar: line[startPos])
        startPos+=1

        result.gender = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos+1)
        startPos+=1

        result.passportExpiration = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos+6)
        startPos+=6

        result.checkSumResult3 = checkSum(input: result.passportExpiration, checkSumChar: line[startPos])
        startPos+=1

        result.personalDocNumber = getSubstring(str: line, offsetStart: startPos, offsetEnd: startPos+14)
        startPos+=14

        result.checkSumResult4 = checkSum(input: result.personalDocNumber, checkSumChar: line[startPos])
        startPos += 1
        
        let finalCheckString = "\(getSubstring(str: line, offsetStart: 0, offsetEnd: 10))\(getSubstring(str: line, offsetStart: 13, offsetEnd: 20))\(getSubstring(str: line, offsetStart: 21, offsetEnd: 43))"
        
        result.checkSumResult5 = checkSum(input: finalCheckString, checkSumChar: line[startPos])
        
        result.passportNumber = result.passportNumber.replacingOccurrences(of: "<", with: "")

        return result
    }

    public func parseMrz(mrz:String) -> AcuantMrzResult?{
        let mrzWithNoSpaces = mrz.replacingOccurrences(of: " ",  with: "")
        print(mrzWithNoSpaces)
        let mrzLines = mrzWithNoSpaces.split(separator: "\n")
        if(mrzLines.count == 2){
            var result = parseFirstLineOfTwo(firstLine: String(mrzLines[0]))
            if(result != nil){
                result = parseSecondLineOfTwo(line: String(mrzLines[1]), result: result!)
                
                result?.threeLineMrz = false;
                
                return result;
            }
        }
        else if(mrzLines.count == 3){
            var result = parseFirstLineOfThree(firstLine: String(mrzLines[0]))
            if(result != nil){
                result = parseSecondLineOfThree(line: String(mrzLines[1]), result: result!)
                
                result?.threeLineMrz = true;
                
                return result
            }
        }
        return nil
    }

    private let CHECK_SUM_ARRAY = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]

    private func checkSum(input: String, checkSumChar:String) -> Bool{
        var count = 0
        let checkSumValue = getValue(character: checkSumChar)
        for i in 0..<input.count {
            count += getValue(character: input[i]) * getWeight(position: i)
        }
        return checkSumValue == count % 10
    }

    private func getWeight(position: Int) -> Int{
        if(position%3 == 0){
            return 7
        }
        else if(position%3 == 1){
            return 3
        }
        else{
            return 1
        }

    }
    private func getValue(character: String) -> Int{
        let value = CHECK_SUM_ARRAY.firstIndex(of: character)
        if (value != nil && value! > 0){
            return value!
        }
        else {
            return 0
        }
    }

}
