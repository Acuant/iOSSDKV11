//
//  CameraCornerOverlayView.swift
//  AcuantCamera
//
//  Created by John Moon local on 8/27/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

import Foundation
import UIKit

public class CameraCornerOverlayView: CALayer {
    public var bracketWidth: Int?
    public var bracketHeight: Int?
    public var defaultBracketMarginWidth: CGFloat?
    public var defaultBracketMarginHeight: CGFloat?
    
    private let corners = [CameraCornerView(), CameraCornerView(), CameraCornerView(), CameraCornerView()]
    
    public init(options: CameraOptions) {
        self.bracketHeight = options.bracketLengthInHorizontal
        self.bracketWidth = options.bracketLengthInVertical
        self.defaultBracketMarginWidth = options.defaultBracketMarginWidth
        self.defaultBracketMarginHeight = options.defaultBracketMarginHeight
        super.init()
        corners.forEach { c in
            self.addSublayer(c)
        }
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    internal func setFrame(frame: CGRect) {
        setDefaultCorners(frame: frame)
    }
    
    public func setColor(color: CGColor?) {
        if let uc = color{
            corners.forEach { c in
                c.strokeColor = uc
            }
        }
    }
    
    internal func getCorners(current: [CGPoint?], p1: CGPoint, p2: CGPoint) -> [CGPoint?] {
        var topLeft: CGPoint? = current[0]
        var topRight: CGPoint? = current[1]
        var bottomRight: CGPoint? = current[2]
        var bottomLeft: CGPoint? = current[3]
        
        if(p1.x > p2.x && p1.y > p2.y){
            topLeft = p2
            bottomRight = p1
        }
        else if(p1.x < p2.x && p1.y < p2.y){
            topLeft = p1
            bottomRight = p2
        }
        else if(p1.x > p2.x && p1.y < p2.y){
            topRight = p1
            bottomLeft = p2
        }
        else{
            topRight = p2
            bottomLeft = p1
        }
        return [topLeft, topRight, bottomRight, bottomLeft]
    }
    
    internal func getCorners(point1: CGPoint, point2: CGPoint, point3: CGPoint, point4: CGPoint) -> [CGPoint?] {
        let pointArray: [CGPoint?] = [nil, nil, nil, nil]
        let updated = getCorners(current: pointArray, p1: point1, p2: point3)
        return getCorners(current: updated, p1: point2, p2: point4)
    }

    internal func setCorners(point1: CGPoint, point2: CGPoint, point3: CGPoint, point4: CGPoint) {
        let corners = getCorners(point1: point1, point2: point2, point3: point3, point4: point4)
        
        animate(x: Int(corners[0]!.x), y: Int(corners[0]!.y), offsetx: bracketWidth!, offsety: bracketHeight!, view: self.corners[0])
        animate(x: Int(corners[1]!.x), y: Int(corners[1]!.y), offsetx: -bracketWidth!, offsety: bracketHeight!, view: self.corners[1])
        animate(x: Int(corners[2]!.x), y: Int(corners[2]!.y), offsetx: -bracketWidth!, offsety: -bracketHeight!, view: self.corners[2])
        animate(x: Int(corners[3]!.x), y: Int(corners[3]!.y), offsetx: bracketWidth!, offsety: -bracketHeight!, view: self.corners[3])
    }

    internal func setHorizontalCorners(point1: CGPoint, point2: CGPoint, point3: CGPoint, point4: CGPoint) {
        let corners = getCorners(point1: point1, point2: point2, point3: point3, point4: point4)

        animate(x: Int(corners[0]!.x), y: Int(corners[0]!.y), offsetx: bracketHeight!, offsety: bracketWidth!, view: self.corners[0])
        animate(x: Int(corners[1]!.x), y: Int(corners[1]!.y), offsetx: -bracketHeight!, offsety: bracketWidth!, view: self.corners[1])
        animate(x: Int(corners[2]!.x), y: Int(corners[2]!.y), offsetx: -bracketHeight!, offsety: -bracketWidth!, view: self.corners[2])
        animate(x: Int(corners[3]!.x), y: Int(corners[3]!.y), offsetx: bracketHeight!, offsety: -bracketWidth!, view: self.corners[3])
    }

    public func setDefaultCorners(frame: CGRect) {
        let center = CGSize(width: frame.width/2, height: frame.height/2)
        let xOffset = Int(center.width * defaultBracketMarginWidth!) + bracketWidth!
        let yOffset = Int(center.height * defaultBracketMarginHeight!)

        animate(x: Int(center.width) - xOffset, y: Int(center.height) - yOffset, offsetx: bracketWidth!, offsety: bracketHeight!, view: self.corners[0])
        animate(x: Int(center.width) + xOffset, y: Int(center.height) - yOffset, offsetx: -bracketWidth!, offsety: bracketHeight!, view: self.corners[1])
        animate(x: Int(center.width) + xOffset, y: Int(center.height) + yOffset, offsetx: -bracketWidth!, offsety: -bracketHeight!, view: self.corners[2])
        animate(x: Int(center.width) - xOffset, y: Int(center.height) + yOffset, offsetx: bracketWidth!, offsety: -bracketHeight!, view: self.corners[3])
    }
    
    func setHorizontalDefaultCorners(frame: CGRect) {
        let center = CGSize(width: frame.width/2, height: frame.height/2)
        let xOffset = Int(center.width * defaultBracketMarginHeight!)
        let yOffset = Int(center.height * defaultBracketMarginWidth!) + bracketWidth!

        animate(x: Int(center.width) - xOffset, y: Int(center.height) - yOffset, offsetx: bracketHeight!, offsety: bracketWidth!, view: self.corners[0])
        animate(x: Int(center.width) + xOffset, y: Int(center.height) - yOffset, offsetx: -bracketHeight!, offsety: bracketWidth!, view: self.corners[1])
        animate(x: Int(center.width) + xOffset, y: Int(center.height) + yOffset, offsetx: -bracketHeight!, offsety: -bracketWidth!, view: self.corners[2])
        animate(x: Int(center.width) - xOffset, y: Int(center.height) + yOffset, offsetx: bracketHeight!, offsety: -bracketWidth!, view: self.corners[3])
    }

    internal func getPath(x: Int, y: Int, offsetx: Int, offsety: Int) -> CGPath {
        let openSquarePath = UIBezierPath()
        
        var point = CGPoint(x: x, y: y)
        
        openSquarePath.move(to: point)
        point.y = CGFloat(y + offsety)
        openSquarePath.addLine(to: point)
        point.y = CGFloat(y)
        openSquarePath.addLine(to: point)
        point.x = CGFloat(x + offsetx)
        openSquarePath.addLine(to: point)
        
        return openSquarePath.cgPath
    }
    
    internal func animate(x: Int, y: Int, offsetx: Int, offsety: Int, view: CameraCornerView) {
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 1
        
        let target = getPath(x: x, y: y, offsetx: offsetx, offsety: offsety)
        // Your new shape here
        animation.toValue = target
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        
        // The next two line preserves the final shape of animation,
        // if you remove it the shape will return to the original shape after the animation finished
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        
        view.add(animation, forKey: nil)
    }
}
