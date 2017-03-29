//
//  CLLocationCoordinate2D+Assistant.swift
//  AlbumMaps
//
//  Created by BobZhang on 2017/3/29.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Foundation

extension CLLocationCoordinate2D{
    func isValid() -> Bool {
        var valid = false
        if latitude > -90 && latitude < 90 && latitude != 0 && longitude > -180 && longitude < 180 && longitude != 0 {
            valid = true
        }
        return valid
    }
    
}
