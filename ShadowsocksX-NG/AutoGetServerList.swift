//
//  AutoGetServerList.swift
//  ShadowsocksX-NG
//
//  Created by ashen on 2017/12/13.
//  Copyright © 2017年 qiuyuzhou. All rights reserved.
//

import Cocoa

class AutoGetServerList: NSObject {

    
    class func getVPN(_ success:@escaping()->Void) {
        // 北京时间0/6/12/24 点更新
        let url = URL(string: "https://global.ishadowx.net/")//
        let request = URLRequest(url: url!)
        let congiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: congiguration)
        let task = session.dataTask(with: request, completionHandler: { (data, response, error)->Void in
            if error == nil{
                DispatchQueue.main.async {
                    self.check(String(data: data!, encoding: String.Encoding.utf8)!, success: success)
                }
            }
        })
        
        task.resume()
    }
    
    class func check(_ str: String,success:@escaping()->Void) {
        let profileMgr = ServerProfileManager.instance

        do {
            //            <h4>IP Address:.+?>(.*?)</span>[\w\W]*Port:.+?>(.*?)\n</span>[\w\W]*Password:.+?>(.*?)\n</span>[\w\W]*Method:(.*?)</h4>
            var pattern = "<h4>IP Address:.+?>(.*?)</span>"
            pattern = pattern.appending("[\\w\\W]+?Port:.+?>(.*?)\n</span>")
            pattern = pattern.appending("[\\w\\W]+?Password:.+?>(.*?)\n</span>")
            pattern = pattern.appending("[\\w\\W]+?Method:(.*?)</h4>")
            let regex = try NSRegularExpression(pattern: pattern, options:
                NSRegularExpression.Options.caseInsensitive)
            
            let res = regex.matches(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.count))
            
            for checkingRes in res {
                
                let name = (str as NSString).substring(with: checkingRes.range(at: 1))
                let ip = (str as NSString).substring(with: checkingRes.range(at: 1))
                let port = (str as NSString).substring(with: checkingRes.range(at: 2))
                let pwd = (str as NSString).substring(with: checkingRes.range(at: 3))
                let style = (str as NSString).substring(with: checkingRes.range(at: 4))
                
                if ip == "" {
                    continue
                }
                let p = ServerProfile()
                
                p.serverHost = ip
                p.serverPort = uint16(port == "" ? "0" : port)!
                p.password = pwd
                p.method = style
                p.remark = name
                
                for (index,pf) in profileMgr.profiles.enumerated() {
                    if pf.serverHost == ip {
                        profileMgr.profiles.remove(at: index)
                        p.uuid = pf.uuid
                    }
                }
                if port != "" && pwd != "" {
                    profileMgr.profiles.append(p)
                }
                
            }
            profileMgr.save()
            ServerProfileManager.instance.refreshPing()
            print("Success Server Lists")
            success()
        }
        catch {
            print(error)
        }
    }
}
