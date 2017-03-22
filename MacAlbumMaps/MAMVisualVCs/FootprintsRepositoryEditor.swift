//
//  FootprintsRepositoryEditor.swift
//  MacAlbumMaps
//
//  Created by 张保国 on 2017/3/13.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

enum FootprintsRepositoryEditorStyle: Int {
    case Import = 0
    case Export
}

class FootprintsRepositoryEditor: NSViewController,NSTableViewDelegate,NSTableViewDataSource,NSTabViewDelegate {
    //@IBOutlet var arrayController: NSArrayController!
    
    var fr = FootprintsRepository()
    
    var style = FootprintsRepositoryEditorStyle.Import
    
    @IBOutlet weak var titleTF: NSTextField!
    
    @IBOutlet weak var placemarkStatisticalInfoTF: NSTextView!
    
    @IBOutlet weak var footprintsTV: NSTableView!
    
    
    @IBOutlet weak var styleTabView: NSTabView!
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        
    }
    
    func checkShareAndBrowse() -> Bool {
        if MAMSettingManager.hasPurchasedShareAndBrowse {
            return true
        }else{
            let purchaseVC = PurchaseShareAndBrowseVC()
            self.presentViewControllerAsModalWindow(purchaseVC)
            
            return false
        }
    }
    
    var saveAction: (() -> Void)?
    @IBAction func saveBtnTD(_ sender: NSButton) {
        if !self.checkShareAndBrowse() { return }
        
        var alertMessage = NSLocalizedString("Save failed.",comment:"保存失败！")
        if MAMCoreDataManager.addFRInfo(fr: fr){
            alertMessage = NSLocalizedString("Save succeeded.",comment:"保存成功。")
            
            saveAction?()
        }
        
        if let window = self.view.window{
            NSAlert.createSimpleAlertAndBeginSheetModal(messageText: alertMessage, for: window)
        }
        
    }
    
    var showAction: (() -> Void)?
    @IBAction func showBtnTD(_ sender: NSButton) {
        showAction?()
        self.dismiss(nil)
    }
    
    @IBOutlet weak var includeThumbnailsCheckBtn: NSButton!
    @IBAction func includeThumbnailsCheckBtnTD(_ sender: NSButton) {
        self.switchThumbnailState(state: sender.state)
    }
    
//    override init(footprintsRepository: FootprintsRepository,style: FootprintsRepositoryEditorStyle) {
//        
//        
//        self.fr = footprintsRepository
//    }
    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//    }
    
    /// 转换缩略图状态，0为关闭，1为启用
    ///
    /// - Parameter state: 0为关闭，1为启用
    func switchThumbnailState(state: Int) -> Void {
        if state == 0{
            // 关闭缩略图
            normalGPXBtn.isEnabled = true
            
            enhancedGPXBtn.isEnabled = false
            footprintsTV.isEnabled = false
        }else{
            // 启用缩略图
            normalGPXBtn.isEnabled = false
            
            enhancedGPXBtn.isEnabled = true
            footprintsTV.isEnabled = true
        }
    }
    
    @IBOutlet weak var normalGPXBtn: NSButton!
    @IBAction func normalGPXBtnTD(_ sender: NSButton) {
        self.exportToGPXFile(enhancedGPX: false)
    }
    
    @IBOutlet weak var enhancedGPXBtn: NSButton!
    @IBAction func enhancedGPXBtnTD(_ sender: NSButton) {
        self.exportToGPXFile(enhancedGPX: true)
    }
    
    func exportToGPXFile(enhancedGPX: Bool) -> Void {
        if !self.checkShareAndBrowse() { return }
        
        if let window = self.view.window{
            let savePanel = NSSavePanel.init()
            
            savePanel.nameFieldStringValue = fr.title + ".gpx"
            savePanel.message = NSLocalizedString("Select path to save footprints repository as gpx file", comment: "选择文件保存位置")
            savePanel.allowedFileTypes = ["gpx"]
            savePanel.allowsOtherFileTypes = true
            savePanel.isExtensionHidden = false
            savePanel.canCreateDirectories = true
            
            savePanel.beginSheetModal(for: window) { (result) in
                if result == NSFileHandlingPanelOKButton {
                    if let filePath = savePanel.url?.path{
                        print("Export To: " + filePath)
                        let succeeded = self.fr.exportToGPXFile(filePath: filePath,enhancedGPX: enhancedGPX)
                        print("Export " + (succeeded ? "succeeded.":"failed!"))
                        let alert = NSAlert.init()
                        alert.messageText = succeeded ? NSLocalizedString("Export succeeded.", comment: "导出成功。") : NSLocalizedString("Export failed!", comment: "导出失败！")
                        alert.beginSheetModal(for: window)
                    }
                }
                
            }
        }
        
        let alertMessage = MAMCoreDataManager.addFRInfo(fr: fr) ? NSLocalizedString("Save succeeded.",comment:"分享自动保存成功。") : NSLocalizedString("Save failed.",comment:"分享自动保存失败！")
        print(alertMessage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Footprints Repository Editor", comment: "足迹包编辑器")
        
        titleTF.stringValue = fr.title
        placemarkStatisticalInfoTF.string = fr.placemarkStatisticalInfo.trimmingCharacters(in: CharacterSet.init(charactersIn: "∙")).replacingOccurrences(of: "∙", with: "\n")
        footprintsTV.register(NSNib.init(nibNamed: "FootprintAnnotationTableCellView", bundle: nil), forIdentifier: "FootprintAnnotationTableCellView")
        
        
        switch style {
        case .Import:
            styleTabView.selectTabViewItem(at: 0)
        case .Export:
            styleTabView.selectTabViewItem(at: 1)
        }
        
        if fr.thumbnailCount > 0{
            includeThumbnailsCheckBtn.isEnabled = true
            self.switchThumbnailState(state: 1)
        }else{
            includeThumbnailsCheckBtn.isEnabled = false
            self.switchThumbnailState(state: 0)
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fr.footprintAnnotations.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let fp = fr.footprintAnnotations[row]
        if fp.thumbnailArray.count > 0 {
            return 160
        }else{
            return 40
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if let view = tableView.make(withIdentifier: "FootprintAnnotationTableCellView", owner: self){
            
            let faTCV = view as! FootprintAnnotationTableCellView
            
            let fp = fr.footprintAnnotations[row]
            
            faTCV.footprintAnnotation = fp
            faTCV.removeAction = {
                tableView .removeRows(at: [row], withAnimation: NSTableViewAnimationOptions.effectFade)
                self.fr.footprintAnnotations.remove(at: row)
                tableView.reloadData()
                //print(self.fr.footprintAnnotations.count)
            }
            
            return faTCV
        }else{
            return nil
        }
        
    }
}
