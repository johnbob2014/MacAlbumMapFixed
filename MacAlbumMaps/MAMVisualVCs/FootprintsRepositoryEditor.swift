//
//  FootprintsRepositoryEditor.swift
//  MacAlbumMaps
//
//  Created by 张保国 on 2017/3/13.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

class FootprintsRepositoryEditor: NSViewController,NSTableViewDelegate,NSTableViewDataSource {
    //@IBOutlet var arrayController: NSArrayController!
    
    @IBOutlet weak var titleTF: NSTextField!
    
    @IBOutlet weak var placemarkStatisticalInfoTF: NSTextView!
    
    @IBOutlet weak var footprintsTV: NSTableView!
    
    @IBOutlet weak var includeThumbnailsCheckBtn: NSButton!
    @IBAction func includeThumbnailsCheckBtnTD(_ sender: NSButton) {
        if sender.state == 0{
            // 关闭缩略图
            normalGPXBtn.isEnabled = true
        }else{
            // 启用缩略图
            normalGPXBtn.isEnabled = false
        }
        
        footprintsTV.reloadData()
    }
    
    
    @IBOutlet weak var normalGPXBtn: NSButton!
    @IBAction func normalGPXBtnTD(_ sender: NSButton) {
            }
    
    @IBAction func enhancedGPXBtnTD(_ sender: NSButton) {
        if let window = self.view.window{
            let savePanel = self.savePanel()
            
            savePanel.beginSheetModal(for: window) { (result) in
                if result == NSFileHandlingPanelOKButton {
                    if let filePath = savePanel.url?.absoluteString{
                        print("Export To: " + filePath)
                        let succeeded = self.fr.exportToGPXFile(filePath: filePath,enhancedGPX: true)
                        print("Export: " + (succeeded ? "1":"0"))
                    }
                }
                
            }
        }
    }
    
    func savePanel() -> NSSavePanel {
        let savePanel = NSSavePanel.init()
        savePanel.nameFieldLabel = fr.title + ".gpx"
        savePanel.message = NSLocalizedString("Select path to save footprints repository as gpx file", comment: "选择文件保存位置")
        savePanel.allowedFileTypes = ["gpx"]
        savePanel.allowsOtherFileTypes = true
        savePanel.isExtensionHidden = false
        savePanel.canCreateDirectories = true
        
        return savePanel
    }
    
    var fr = FootprintsRepository()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Export Footprints Repository", comment: "导出足迹包")
        
        titleTF.stringValue = fr.title
        placemarkStatisticalInfoTF.string = fr.placemarkStatisticalInfo
        footprintsTV.register(NSNib.init(nibNamed: "FootprintAnnotationTableCellView", bundle: nil), forIdentifier: "FootprintAnnotationTableCellView")
        
        normalGPXBtn.isEnabled = false
    }
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fr.footprintAnnotations.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if includeThumbnailsCheckBtn.state == 1 {
            let fp = fr.footprintAnnotations[row]
            if fp.thumbnailArray.count > 0 {
                return 160
            }else{
                return 40
            }
        }else{
            return 40
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        //var faTCV: FootprintAnnotationTableCellView?
        if let view = tableView.make(withIdentifier: "FootprintAnnotationTableCellView", owner: self){
            
            let faTCV = view as! FootprintAnnotationTableCellView
            
            let fp = fr.footprintAnnotations[row]
            
            faTCV.footprintAnnotation = fp
            faTCV.removeAction = {
                tableView .removeRows(at: [row], withAnimation: NSTableViewAnimationOptions.effectFade)
                self.fr.footprintAnnotations.remove(at: row)
                tableView.reloadData()
                print(self.fr.footprintAnnotations.count)
                //tableView.reloadData(forRowIndexes: IndexSet.init(integersIn: row + 1..<self.fr.footprintAnnotations.count), columnIndexes: [0])
            }
            
            return faTCV
        }else{
            return nil
        }
        
        
    }
}
