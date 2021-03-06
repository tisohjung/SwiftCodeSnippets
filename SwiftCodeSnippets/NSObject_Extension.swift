//
//  NSObject_Extension.swift
//
//  Created by LawLincoln on 15/5/21.
//  Copyright (c) 2015年 LawLincoln. All rights reserved.
//

import Foundation

extension NSObject {
    class func pluginDidLoad(bundle: Bundle) {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? NSString
        if appName == "Xcode" {
        	if sharedPlugin == nil {
        		sharedPlugin = SwiftCodeSnippetsManager(bundle: bundle)
        	}
        }
    }
}
