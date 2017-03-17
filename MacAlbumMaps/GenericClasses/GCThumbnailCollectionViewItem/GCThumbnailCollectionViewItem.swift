//
//  GCThumbnailCollectionViewItem.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/3/13.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

class GCThumbnailCollectionViewItem: NSCollectionViewItem {

    var removeAction: (() -> Void)?
    
    @IBOutlet weak var removeBtn: NSButton!
    @IBAction func removeBtnTD(_ sender: Any) {
        //print("removeBtnTD")
        removeAction?()
    }
    
    @IBOutlet weak var titleTF: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        removeBtn.alphaValue = 0.6
        titleTF.stringValue = ""
    }
    
}
