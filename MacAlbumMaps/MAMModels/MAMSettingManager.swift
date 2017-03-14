//
//  MAMSettingManager.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/2/23.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

/// 地图模式
///
/// - Moment: 时刻模式
/// - Location: 地点模式
/// - Browser: 浏览模式
/// - Record: 记录模式

enum MapMode: Int {
    case Moment = 0
    case Location
    case Browser
    case Record
}

enum MKOverlayColorTitle: String {
    case Random = "Random"
    case Previous = "Previous"
    case Next = "Next"
}

let appCachesURL = URL.cachesURL.appendingPathComponent("com.ZhangBaoGuo.MacAlbumMaps")
let appCachesPath = appCachesURL.absoluteString

class MAMSettingManager: NSObject {
    /// 是否曾经登陆
    class var everLaunched: Bool{
        get{
            if let ever = NSUserDefaultsController.shared().defaults.value(forKey: "everLaunched"){
                return ever as! Bool
            }else{
                return false
            }
        }
        set{
            NSUserDefaultsController.shared().defaults.setValue(newValue, forKey: "everLaunched")
            NSUserDefaultsController.shared().defaults.synchronize()
        }
    }
    
    /// 是否曾经登陆
    class var hasPurchasedShareAndBrowse: Bool{
        get{
            if let ever = NSUserDefaultsController.shared().defaults.value(forKey: "hasPurchasedShareAndBrowse"){
                return ever as! Bool
            }else{
                return true
            }
        }
        set{
            NSUserDefaultsController.shared().defaults.setValue(newValue, forKey: "hasPurchasedShareAndBrowse")
            NSUserDefaultsController.shared().defaults.synchronize()
        }
    }

}
