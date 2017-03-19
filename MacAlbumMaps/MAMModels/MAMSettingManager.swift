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

let appApplicationSupportURL = URL.appApplicationSupportURL.appendingPathComponent("com.ZhangBaoGuo.MacAlbumMaps")

//这里是个巨大的坑？？？
//let appApplicationSupportPath = appApplicationSupportURL.absoluteString
let appApplicationSupportPath = appApplicationSupportURL.path

class MAMSettingManager: NSObject {
    
    /// 时刻模式分组距离
    class var mergeDistanceForMoment: CLLocationDistance{
        get{
            var mergeDistance = NSUserDefaultsController.shared().defaults.double(forKey: "mergeDistanceForMoment")
            if mergeDistance == 0.0 {
                mergeDistance = 300
            }
            return mergeDistance
        }
        set{
            NSUserDefaultsController.shared().defaults.setValue(newValue, forKey: "mergeDistanceForMoment")
            NSUserDefaultsController.shared().defaults.synchronize()
        }
    }
    
    /// 地点模式分组距离
    class var mergeDistanceForLocation: CLLocationDistance{
        get{
            var mergeDistance = NSUserDefaultsController.shared().defaults.double(forKey: "mergeDistanceForLocation")
            if mergeDistance == 0.0 {
                mergeDistance = 2000
            }
            return mergeDistance
        }
        set{
            NSUserDefaultsController.shared().defaults.setValue(newValue, forKey: "mergeDistanceForLocation")
            NSUserDefaultsController.shared().defaults.synchronize()
        }
    }
    
    /// 导航栏播放时间间隔，默认2.0秒
    class var playTimeInterval: TimeInterval{
        get{
            var interval = NSUserDefaultsController.shared().defaults.double(forKey: "playTimeInterval")
            if interval == 0.0 {
                interval = 2.0
            }
            return interval
        }
        set{
            NSUserDefaultsController.shared().defaults.setValue(newValue, forKey: "playTimeInterval")
            NSUserDefaultsController.shared().defaults.synchronize()
        }
    }
    
    /// 是否自动以第一张图片作为分享缩略图，默认为否
    class var autoUseFirstMediaAsThumbnail: Bool{
        get{
            if let autoUse = NSUserDefaultsController.shared().defaults.value(forKey: "autoUseFirstMediaAsThumbnail"){
                return autoUse as! Bool
            }else{
                return false
            }
        }
        set{
            NSUserDefaultsController.shared().defaults.setValue(newValue, forKey: "autoUseFirstMediaAsThumbnail")
            NSUserDefaultsController.shared().defaults.synchronize()
        }
    }
    
    /// 是否自动以全部图片作为分享缩略图，默认为否
    class var autoUseAllMediasAsThumbnail: Bool{
        get{
            if let autoUse = NSUserDefaultsController.shared().defaults.value(forKey: "autoUseAllMediasAsThumbnail"){
                return autoUse as! Bool
            }else{
                return false
            }
        }
        set{
            NSUserDefaultsController.shared().defaults.setValue(newValue, forKey: "autoUseAllMediasAsThumbnail")
            NSUserDefaultsController.shared().defaults.synchronize()
        }
    }
    
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
    
    /// 是否订购功能
    class var hasPurchasedShareAndBrowse: Bool{
        get{
            if let ever = NSUserDefaultsController.shared().defaults.value(forKey: "hasPurchasedShareAndBrowse"){
                return ever as! Bool
            }else{
                return false
            }
        }
        set{
            NSUserDefaultsController.shared().defaults.setValue(newValue, forKey: "hasPurchasedShareAndBrowse")
            NSUserDefaultsController.shared().defaults.synchronize()
        }
    }

}
