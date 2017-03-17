//
//  GCTableCellView.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/3/17.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

class GCTableCellView: NSTableCellView {
    
    var removeAction: (() -> Void)?
    
    @IBOutlet weak var thumbnailImageView: NSImageView!

    @IBOutlet weak var titleTextField: NSTextField!
    
    @IBOutlet weak var subTitleTextField: NSTextField!
    
    @IBAction func removeBtnTD(_ sender: NSButton) {
        removeAction?()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
