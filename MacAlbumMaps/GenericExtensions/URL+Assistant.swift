//
//  URL+Assistant.swift
//  MacAlbumMaps
//
//  Created by 张保国 on 2017/2/26.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Foundation

extension URL{
    static var documentURL: URL{
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }
    
    static var libraryURL: URL{
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last!
    }
    
    static var cachesURL: URL{
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
    }
}
