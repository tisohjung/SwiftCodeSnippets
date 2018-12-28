//
//  SwiftCodeSnippets.swift
//
//  Created by LawLincoln on 15/5/21.
//  Copyright (c) 2015年 LawLincoln. All rights reserved.
//

import AppKit
let rawUrl = "https://raw.githubusercontent.com"
let directoryUrl = "https://github.com/burczyk/XcodeSwiftSnippets/tree/master/plist"
let codeSnippetDirectory = "/Library/Developer/Xcode/UserData/CodeSnippets/"
let configureDirectory = "/Library/Application Support/SelfStudio"
var sharedPlugin: SwiftCodeSnippetsManager?

class SwiftCodeSnippetsManager: NSObject {
    var bundle: Bundle
    let NTC = NotificationCenter.default
    init(bundle: Bundle) {
        self.bundle = bundle
        super.init()
        updateCodeSnippets()
    }

    deinit {
        NTC.removeObserver(self)
    }
}

// MARK: - UpdateCodeSnippets
extension SwiftCodeSnippetsManager {
    func updateCodeSnippets(){
//        DispatchQueue.main.async {
//        }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async { () -> Void in
            
//        }
//        dispatch_async(DispatchQueue.global(DispatchQueue.GlobalQueuePriority.default, 0), {
            guard let data = try? Data(contentsOf: NSURL(string: directoryUrl)! as URL) else {
                print("\(#file) \(#function)[39]: Error trying to create Data")
                return
            }
            if let content = String(data: data, encoding: String.Encoding.utf8) {
                let start = "<td class=\"content\">"
                let end = "</td>"
                let matches = content.matchesOf(startPattern: start, endPattern: end)
                var urls = [String]()
                for item in matches{
                    let hrefMatch = item.matchesOf(startPattern: "href=\"", endPattern: "\"")
                    if hrefMatch.count > 0 {
                        let url = hrefMatch[0]
                        if (url as NSString).hasSuffix(".codesnippet") {
                            urls.append(url)
                        }
                    }
                }
                let filePath = self.appConfigure()
                var toDownloads = [String]()
                var toDeletes = [String]()
                let nowArray = urls as NSArray
                if let oldArray = NSArray(contentsOfFile: filePath) {
                    for item in oldArray {
                        if !nowArray.contains(item) {
                            toDeletes.append(item as! String)
                        }
                    }
                    for item in nowArray {
                        if !oldArray.contains(item) {
                            toDownloads.append(item as! String)
                        }
                    }
                }
                
                if urls.count > 0 {
                    nowArray.write(toFile: filePath, atomically: true)
                }
                
                if toDownloads.count > 0 {
                    self.downloadFrom(urls: toDownloads, done: { () -> () in
                        print("😀😀😀😀😀😀SwiftCodeSnippetsManager updat done")
                    })
                } else {
                    print("😀😀😀😀😀😀SwiftCodeSnippetsManager not downloading")
                }
                
                if toDeletes.count > 0 {
                    self.deleteFiles(items: toDeletes)
                } else {
                    print("😀😀😀😀😀😀SwiftCodeSnippetsManager not delete files")
                }
                
                
            }
        }
    }
    
    func appConfigure()->String{
        let dir = (NSHomeDirectory() as NSString).appendingPathComponent(configureDirectory)
        let fm = FileManager.default
        var isDir : ObjCBool = true
        if !fm.fileExists(atPath: dir, isDirectory: &isDir) {
            do {
                try fm.createDirectory(atPath: dir, withIntermediateDirectories: false, attributes: nil)
            } catch _ {
            }
        }
        let configureFile = (dir as NSString).appendingPathComponent("conf")
        return configureFile
    }
    
    func deleteFiles(items:[String]){
        for item in items {
            let fm = FileManager.default
            let home = (NSHomeDirectory() as NSString).appendingPathComponent(codeSnippetDirectory)
            let path = (home as NSString).appendingPathComponent(item)
            do {
                try fm.removeItem(atPath: path)
            } catch _ {
            }
        }
    }
    
    func downloadFrom(urls:[String], done:()->()){
        var urls = urls
        if urls.count > 0 {
            if let alast = urls.last {
            var last = alast as NSString
                last = last .replacingOccurrences(of: "/blob", with: "") as NSString
            if let  aurl = NSURL(string: "https://raw.githubusercontent.com" + (last as String)) ,
                let data = NSData(contentsOf: aurl as URL){
                    let fileName = alast.fileName()
                data.write(name: fileName)
                    urls.removeLast()
                    if urls.count > 0 {
                        downloadFrom(urls: urls, done: done)
                    }else{
                        done()
                    }
                }
            }
        }else{
            done()
        }
    }
}

extension NSData {
    func write(name:String){
        let fm = FileManager.default
        let home = (NSHomeDirectory() as NSString).appendingPathComponent(codeSnippetDirectory)
        let path = (home as NSString).appendingPathComponent(name)
        var isDir : ObjCBool = false
        if !fm.fileExists(atPath: path, isDirectory: &isDir) {
            self.write(toFile: path, atomically: true)
        }
    }
}
extension String {
    func fileName()->String{
        return (self as NSString).lastPathComponent
    }
    
    func matchesOf(startPattern:String,endPattern:String)->[String]{
        let startRx = try? NSRegularExpression(pattern: startPattern, options: NSRegularExpression.Options())
        let endRx = try? NSRegularExpression(pattern: endPattern, options: NSRegularExpression.Options())
        let selfLen = self.utf16.count
        let range = NSMakeRange(0, selfLen)
        var codeSnippets: [String]! = [String]()
        startRx?.enumerateMatches(in: self, options: NSRegularExpression.MatchingOptions(), range: range, using: { (match, flags, stop) -> Void in
            if let startMatch = match {
                let startLen = startMatch.range.location + startMatch.range.length
                let len = selfLen - startLen
                let subRange = NSMakeRange(startLen, len)
                if let endMatch = endRx?.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(), range: subRange) {
                    let dataRangeLen = endMatch.range.location - startLen
                    let dataRange = NSMakeRange(startLen, dataRangeLen)
                    let aData = (self as NSString).substring(with: dataRange)
                    codeSnippets.append(aData)
                }
            }
        })
        return codeSnippets
    }
}
