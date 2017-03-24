//
//  NSAlert+Assistant.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/3/16.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

extension NSAlert{
    
    /// 新建Alert并运行
    ///
    /// - Parameter messageText: 信息字符串
    class func createSimpleAlertAndRunModal(messageText: String) -> Void {
        let alert = NSAlert.init()
        alert.messageText = messageText
        alert.runModal()
    }
    
    
    /// 新建Alert并以表单方式运行
    ///
    /// - Parameters:
    ///   - messageText: 信息字符串
    ///   - sheetWindow: 表单窗口
    ///   - handler: 完成块
    class func createSimpleAlertAndBeginSheetModal(messageText: String,for sheetWindow: NSWindow, completionHandler handler: ((NSModalResponse) -> Void)? = nil) -> Void {
        let alert = NSAlert.init()
        alert.messageText = messageText
        alert.beginSheetModal(for: sheetWindow,completionHandler: handler)
    }
    
}
