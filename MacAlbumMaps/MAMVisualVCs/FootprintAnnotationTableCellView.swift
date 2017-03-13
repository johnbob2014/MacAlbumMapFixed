//
//  FootprintAnnotationTableCellView.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/3/13.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

class FootprintAnnotationTableCellView: NSTableCellView,NSCollectionViewDelegate,NSCollectionViewDataSource {
    
    @IBOutlet weak var titleTF: NSTextField!
    
    
    
    @IBOutlet weak var thumbnailCollectionView: NSCollectionView!
    
    @IBOutlet weak var removeBtn: NSButton!
    @IBAction func removeBtnTD(_ sender: NSButton) {
        self.print("remove fa")
    }
    
    
    var footprintAnnotation = FootprintAnnotation(){
        didSet{
            
            titleTF.stringValue = footprintAnnotation.customTitle + "  " + footprintAnnotation.dateString
            
            thumbnailCollectionView.delegate = self
            thumbnailCollectionView.dataSource = self
            thumbnailCollectionView.register(GCThumbnailCollectionViewItem.self, forItemWithIdentifier: "GCThumbnailCollectionViewItem")
            thumbnailCollectionView.reloadData()
        }
    }
        
    // MARK: - NSCollectionViewDataSource
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return footprintAnnotation.thumbnailArray.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "GCThumbnailCollectionViewItem", for: indexPath)
        let thumbanilData = footprintAnnotation.thumbnailArray[indexPath.item]
        
        if let thumbnail = NSImage.init(data: thumbanilData){
            item.representedObject = thumbnail
        }
        
        return item
    }
    
    // MARK: - NSCollectionViewDelegate
    
    
    // MARK: - 根据需要重写父类方法
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
        removeBtn.alphaValue = 0.6
    }
}
