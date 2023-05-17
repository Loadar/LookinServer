#if SHOULD_COMPILE_LOOKIN_SERVER

//
//  LKS_TraceManager+Extension.swift
//  LookinServer
//
//  Created by Shida Zhu on 2022/8/21.
//

import Foundation
import UIKit
#if SPM_LOOKIN_SERVER_ENABLED
import LookinServerBase
#endif

public class LKS_SwiftTraceManager: NSObject {
    @objc public static func swiftMarkIVars(ofObject hostObject: AnyObject) {
        var mirror: Mirror? = Mirror(reflecting: hostObject)
        var inClass: AnyClass? = type(of: hostObject)
        while let m = mirror, let childClass = inClass {
            m.children.forEach { child in
                // 若child的基类是NSProxy，转换会产生指令异常的崩溃，先转换成AnyObject, 再根据classForCoder来判断
                if let child = child as? (label: String?, value: AnyObject),
                   child.value.classForCoder != nil,
                   let value = child.value as? NSObject {
                    let label: String? = child.label?.replacingOccurrences(of: "$__lazy_storage_$_", with: "")
                    
                    guard (value is UIView) || (value is CALayer) || (value is UIViewController) || (value is UIGestureRecognizer) else {
                        return
                    }
                    
                    guard let label = label, label.count > 0 else {
                        return
                    }
                    
                    let ivarTrace = LookinIvarTrace()
                    ivarTrace.hostObject = hostObject
                    ivarTrace.hostClassName = NSStringFromClass(childClass)
                    ivarTrace.ivarName = label
                    
                    if (value === hostObject) {
                        ivarTrace.relation = LookinIvarTraceRelationValue_Self
                    } else if let hostView = hostObject as? UIView {
                        var ivarLayer: CALayer? = nil
                        if let layer = value as? CALayer {
                            ivarLayer = layer
                        } else if let view = value as? UIView {
                            ivarLayer = view.layer
                        }
                        if let layer = ivarLayer, layer.superlayer === hostView.layer {
                            ivarTrace.relation = "superview"
                        }
                    }
                    value.lks_ivarTraces = (value.lks_ivarTraces ?? []) + [ivarTrace]
                }
            }
            mirror = m.superclassMirror
            inClass = childClass.superclass()
        }
    }
}

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
