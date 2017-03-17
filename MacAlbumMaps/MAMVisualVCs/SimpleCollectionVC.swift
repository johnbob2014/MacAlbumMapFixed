//
//  SimpleCollectionVC.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/3/17.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

class SimpleCollectionVC: NSViewController,NSCollectionViewDataSource,NSCollectionViewDelegate {
    
    var sourceArray = [Any](){
        didSet{
            itemCollectionView.reloadData()
        }
    }

    @IBOutlet weak var itemPopUpButton: NSPopUpButton!
    @IBAction func itemPopUpButtonTD(_ sender: NSPopUpButton) {
        sender.selectItem(at: sender.indexOfSelectedItem)
        
        if let titleOfSelectedItem = sender.titleOfSelectedItem{
            sender.title = titleOfSelectedItem
        }
        
        //print(itemPopUpButton.indexOfSelectedItem)
        self.updateSource()
    }
    
    func updateSource() {
        switch itemPopUpButton.indexOfSelectedItem {
        case 0:
            sourceArray = appContext.mediaInfos.filter(){ ($0.favorite?.boolValue)! }
        case 1:
            sourceArray = appContext.mediaInfos.filter(){ ($0.eliminateThisMedia?.boolValue)! }
        case 2:
            sourceArray = appContext.coordinateInfos.filter(){ ($0.favorite?.boolValue)! }
        default:
            break
        }
    }
    
    @IBOutlet weak var itemCollectionView: NSCollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.title = NSLocalizedString("Collections Manager",comment:"项目管理器")
        
        itemPopUpButton.removeAllItems()
        itemPopUpButton.addItems(withTitles: [NSLocalizedString("Favorite Medias",comment:"喜爱的媒体"),NSLocalizedString("Eliminated Medias",comment:"排除的媒体"),NSLocalizedString("Favorite Coordinates",comment:"喜爱的地点")])
        itemPopUpButton.selectItem(at: 0)
        
        itemCollectionView.register(GCThumbnailCollectionViewItem.self, forItemWithIdentifier: "GCThumbnailCollectionViewItem")
        itemCollectionView.minItemSize = NSSize.init(width: 150, height: 150)
        itemCollectionView.maxItemSize = NSSize.init(width: 200, height: 200)
        //itemCollectionView.
        self.updateSource()
    }
    
    // MARK: - NSCollectionViewDataSource
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return sourceArray.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "GCThumbnailCollectionViewItem", for: indexPath)
        
        let managedObject = sourceArray[indexPath.item]
        if managedObject is MediaInfo {
            let mediaInfo = managedObject as! MediaInfo
            
            if let thumbnailURLString = mediaInfo.thumbnailURLString{
                if let thumbnailURL = URL.init(string: thumbnailURLString){
                    if let thumbnail = NSImage.init(contentsOf: thumbnailURL){
                        
                        item.representedObject = ["thumbnail":thumbnail,"title":mediaInfo.mediaTitle]
                    }
                }
            }
        }else if managedObject is CoordinateInfo{
            let coordinateInfo = managedObject as! CoordinateInfo
            var title = coordinateInfo.title
            if title == nil{
                title = String.init(format: "%.2f,%.2f",(coordinateInfo.latitude?.doubleValue)!,(coordinateInfo.longitude?.doubleValue)!)
            }
            item.representedObject = ["thumbnail":NSImage.init(named: "AppIcon.icns")!,"title":title!]
        }
        
        if item is GCThumbnailCollectionViewItem {
            let thumbnailItem = item as! GCThumbnailCollectionViewItem
            thumbnailItem.removeAction = {
                
                if managedObject is MediaInfo{
                    let mediaInfo = managedObject as! MediaInfo
                    if self.itemPopUpButton.indexOfSelectedItem == 0 {
                        mediaInfo.favorite = NSNumber.init(value: false)
                    }else if self.itemPopUpButton.indexOfSelectedItem == 1 {
                        mediaInfo.eliminateThisMedia = NSNumber.init(value: false)
                    }
                }else if managedObject is CoordinateInfo{
                    (managedObject as! CoordinateInfo).favorite = NSNumber.init(value: false)
                }
                
                do {
                    try appContext.save()
                    self.updateSource()
                } catch  {
                    if let window = self.view.window{
                        NSAlert.createSimpleAlertAndBeginSheetModal(messageText: NSLocalizedString("Remove failed!",comment:"删除失败！"), for: window)
                    }
                }
            
            }
        }
        
        return item
    }
    
    // MARK: - NSCollectionViewDelegate
}
