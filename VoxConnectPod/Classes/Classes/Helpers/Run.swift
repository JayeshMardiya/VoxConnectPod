//
//  Run.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation

public typealias SimpleClosure = (() -> ())

open class Run {

    @discardableResult
    open class func afterDelay(_ delayInSeconds: Double, block: @escaping ()->()) -> SimpleClosure? {
        var cancelled = false
        
        let cancelClosure: SimpleClosure = {
            cancelled = true
        }
        
        let time = DispatchTime.now() + Double(Int64(delayInSeconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: time) { () -> Void in
            if !cancelled {
                block()
            }
        }
        
        return cancelClosure
    }
    
    open class func onMainThread(_ block: @escaping ()->()) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) { () -> Void in
            block()
        }
    }
}
