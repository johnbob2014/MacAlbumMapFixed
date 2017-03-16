//
//  URL+Assistant.swift
//  MacAlbumMaps
//
//  Created by 张保国 on 2017/2/26.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Foundation

extension URL{
//    static var documentURL: URL{
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
//    }
    
    static var appApplicationSupportURL: URL{
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return urls[urls.count - 1]
    }
    
//    static var cachesURL: URL{
//        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
//    }
}
