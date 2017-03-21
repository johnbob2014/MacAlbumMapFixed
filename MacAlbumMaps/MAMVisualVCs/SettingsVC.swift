//
//  SettingsVC.swift
//  MacAlbumMaps
//
//  Created by 张保国 on 2017/3/20.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

class SettingsVC: NSViewController {
    
    // MARK: - Browser
    @IBOutlet weak var playTimeIntervalTF: NSTextField!
    
    @IBOutlet weak var mergeDistanceForMomentTF: NSTextField!
    
    @IBOutlet weak var mergeDistanceForLocationTF: NSTextField!
    
    @IBOutlet weak var autoUseFirstMediaAsThumbnailBtn: NSButton!
    @IBOutlet weak var autoUseAllMediasAsThumbnailBtn: NSButton!
    
    @IBAction func radioButtonAction(_ sender: NSButton) {
        print(sender.tag)
        if sender.tag == 0{
            MAMSettingManager.autoUseFirstMediaAsThumbnail = false
            MAMSettingManager.autoUseAllMediasAsThumbnail = false
        }else if sender.tag == 1{
            MAMSettingManager.autoUseFirstMediaAsThumbnail = true
            MAMSettingManager.autoUseAllMediasAsThumbnail = false
        }else if sender.tag == 2{
            MAMSettingManager.autoUseFirstMediaAsThumbnail = false
            MAMSettingManager.autoUseAllMediasAsThumbnail = true
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.title = NSLocalizedString("Settings",comment:"设置")
        
        playTimeIntervalTF.stringValue = String.init(format: "%.2f", MAMSettingManager.playTimeInterval)
        mergeDistanceForMomentTF.stringValue = String.init(format: "%.2f", MAMSettingManager.mergeDistanceForMoment)
        mergeDistanceForLocationTF.stringValue = String.init(format: "%.2f", MAMSettingManager.mergeDistanceForLocation)
        
        if MAMSettingManager.autoUseFirstMediaAsThumbnail {
            autoUseFirstMediaAsThumbnailBtn.state = 1
        }
        
        if MAMSettingManager.autoUseAllMediasAsThumbnail{
            autoUseAllMediasAsThumbnailBtn.state = 1
        }
    }
    
}
