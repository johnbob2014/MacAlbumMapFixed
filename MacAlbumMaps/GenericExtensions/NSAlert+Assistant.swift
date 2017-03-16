//
//  NSAlert+Assistant.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/3/16.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

extension NSAlert{
    class func createSimpleAlertAndBeginSheetModal(messageText: String,for sheetWindow: NSWindow, completionHandler handler: ((NSModalResponse) -> Void)? = nil) -> Void {
        let alert = NSAlert.init()
        alert.messageText = messageText
        alert.beginSheetModal(for: sheetWindow,completionHandler: handler)
    }
}
