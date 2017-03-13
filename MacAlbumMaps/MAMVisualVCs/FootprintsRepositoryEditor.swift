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
    
    @IBOutlet weak var fasTV: NSTableView!
    
    var fr = FootprintsRepository()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Export Footprints Repository", comment: "导出足迹包")
        
        titleTF.stringValue = fr.title
        placemarkStatisticalInfoTF.string = fr.placemarkStatisticalInfo
        fasTV.register(NSNib.init(nibNamed: "FootprintAnnotationTableCellView", bundle: nil), forIdentifier: "FootprintAnnotationTableCellView")
    }
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fr.footprintAnnotations.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 160
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        //var faTCV: FootprintAnnotationTableCellView?
        if let view = tableView.make(withIdentifier: "FootprintAnnotationTableCellView", owner: self){
            
            let faTCV = view as! FootprintAnnotationTableCellView
            
            let fp = fr.footprintAnnotations[row]
            
            faTCV.footprintAnnotation = fp
            
            return faTCV
        }else{
            return nil
        }
        
        
    }
}
