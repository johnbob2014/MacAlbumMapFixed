//
//  MediaMapVC.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/2/17.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa
import MapKit
import MediaLibrary

class MediaMapVC: NSViewController,MKMapViewDelegate,NSOutlineViewDelegate,NSOutlineViewDataSource,NSTabViewDelegate,NSTableViewDelegate,NSTableViewDataSource{
    
    // MARK: - 属性
    
    @IBOutlet weak var mainMapView: MKMapView!
    
    let mediaLibraryLoader = GCMediaLibraryLoader()
    
    /// 当前地图模式
    var currentMapMode: MapMode = MapMode.Moment
    
    /// 标签栏序号
    /// ☆带属性观测器的核心属性
    var indexOfTabViewItem = 0{
        didSet{
            self.clearMainMapView()
            
            currentMergeDistance = 0.0
            
            switch indexOfTabViewItem {
            case 0:
                placemarkInfoTF.stringValue = NSLocalizedString("Choose date range", comment: "请选择日期范围")
                currentMapMode = MapMode.Moment
                self.showMediaInfoButtons()
            case 1:
                placemarkInfoTF.stringValue = NSLocalizedString("Choose a location", comment: "请选择地点")
                currentMapMode = MapMode.Location
                self.showMediaInfoButtons()
            case 2:
                placemarkInfoTF.stringValue = NSLocalizedString("Choose a footprints repository", comment: "请选择足迹包")
                currentMapMode = MapMode.Browser
                browserTableView.reloadData()
                self.hideMediaInfoButtons()
            default:
                break
            }
        }
    }
    
    func showMediaInfoButtons() {
        eliminateCheckBtn.isHidden = false
        //shareCheckBtn.isHidden = false
        favoriteCoordinateInfoBtn.isHidden = false
        favoriteMediaBtn.isHidden = false
    }
    
    func hideMediaInfoButtons() {
        eliminateCheckBtn.isHidden = true
        //shareCheckBtn.isHidden = true
        favoriteCoordinateInfoBtn.isHidden = true
        favoriteMediaBtn.isHidden = true
    }
    
    /// 当前添加的、用于导航的 MKAnnotation数组
    var currentIDAnnotations = [MKAnnotation]()
    var currentMediaInfoGroupAnnotations = [MediaInfoGroupAnnotation]()
    //var currentFootprintAnnotations = [FootprintAnnotation]()
    
    var indexOfCurrentAnnotationDidChange = false
    /// 当前MKAnnotation序号 
    /// ☆带属性观测器的核心属性
    var indexOfCurrentAnnotation = 0{
        willSet{
            if indexOfCurrentAnnotation == newValue {
                indexOfCurrentAnnotationDidChange = false
            }else{
                indexOfCurrentAnnotationDidChange = true
            }
        }
        didSet{
            //print("didSet: indexOfCurrentAnnotation")
            if indexOfCurrentAnnotation >= 0 && indexOfCurrentAnnotation < currentIDAnnotations.count{
                
                // 显示序号
                self.indexOfCurrentAnnotationLabel.stringValue = "\(self.indexOfCurrentAnnotation + 1)/\(self.currentIDAnnotations.count)"
                
                // 如果是时刻模式，或者显示的是时刻模式生成的足迹包，添加直线路线
                if indexOfTabViewItem == 0 || (currentFootprintsRepository != nil && currentFootprintsRepository!.radius == 0){
                    
                    if currentIDAnnotations.count >= 2{
                        mainMapView.removeOverlays(mainMapView.overlays.filter({ !($0 is MKCircle) }))
                        var startCoord = CLLocationCoordinate2D.init()
                        var endCoord = CLLocationCoordinate2D.init()
                        var overlayTitle = ""
                        
                        if indexOfCurrentAnnotation == 0 {
                            // 添加下条路线
                            startCoord = currentIDAnnotations[0].coordinate
                            endCoord = currentIDAnnotations[1].coordinate
                            overlayTitle = MKOverlayColorTitle.Next.rawValue
                            
                            self.createSignleOverlay(startCoordinate: startCoord, endCoordinate: endCoord, overlayTitle: overlayTitle)
                        }else if indexOfCurrentAnnotation == currentIDAnnotations.count - 1{
                            // 添加上条路线
                            startCoord = currentIDAnnotations[indexOfCurrentAnnotation - 1].coordinate
                            endCoord = currentIDAnnotations[indexOfCurrentAnnotation].coordinate
                            overlayTitle = MKOverlayColorTitle.Previous.rawValue
                            
                            self.createSignleOverlay(startCoordinate: startCoord, endCoordinate: endCoord, overlayTitle: overlayTitle)
                            
                        }else if currentIDAnnotations.count >= 3{
                            // 添加上条路线
                            startCoord = currentIDAnnotations[indexOfCurrentAnnotation - 1].coordinate
                            endCoord = currentIDAnnotations[indexOfCurrentAnnotation].coordinate
                            overlayTitle = MKOverlayColorTitle.Previous.rawValue
                            self.createSignleOverlay(startCoordinate: startCoord, endCoordinate: endCoord, overlayTitle: overlayTitle)
                            
                            // 添加下条路线
                            startCoord = currentIDAnnotations[indexOfCurrentAnnotation].coordinate
                            endCoord = currentIDAnnotations[indexOfCurrentAnnotation + 1].coordinate
                            overlayTitle = MKOverlayColorTitle.Next.rawValue
                            self.createSignleOverlay(startCoordinate: startCoord, endCoordinate: endCoord, overlayTitle: overlayTitle)
                        }
                    }
                }
                
                // ☆移动地图
                if indexOfCurrentAnnotationDidChange {
                    let annotation = self.currentIDAnnotations[indexOfCurrentAnnotation]
                    mainMapView.setCenter(annotation.coordinate, animated: false)
                    mainMapView.selectAnnotation(annotation, animated: true)
                }
                
            }else{
                indexOfCurrentAnnotation = oldValue
            }
        }
    }
    
    func createSignleOverlay(startCoordinate:CLLocationCoordinate2D,endCoordinate:CLLocationCoordinate2D,overlayTitle:String) {
        if changeOverlayStyleBtn.tag == 0{
            MediaMapVC.asyncCreateRouteMKPolyline(startCoordinate: startCoordinate, endCoordinate: endCoordinate, completionHandler: { (polylineOptional, distance) in
                if let polyline = polylineOptional{
                    polyline.title = overlayTitle
                    self.mainMapView.addOverlays([polyline])
                }
            })
        }else{
            let linePolyline = MediaMapVC.createLineMKPolyline(startCoordinate: startCoordinate, endCoordinate: endCoordinate)
            linePolyline.title = overlayTitle
            let arrowPolygon = MediaMapVC.createArrowMKPolygon(startCoordinate: startCoordinate, endCoordinate: endCoordinate)
            arrowPolygon.title = overlayTitle
            self.mainMapView.addOverlays([linePolyline,arrowPolygon])
        }
    }
    
    /// 当前 MediaInfoGroupAnnotation 的 MediaInfo数组
    var currentMediaInfos = [MediaInfo](){
        didSet{
            self.indexOfCurrentMediaInfo = 0
        }
    }
    
    /// 当前MediaInfo序号
    /// ☆带属性观测器的核心属性
    var indexOfCurrentMediaInfo = 0{
        didSet{
            if indexOfCurrentMediaInfo >= 0 && indexOfCurrentMediaInfo < self.currentMediaInfos.count {
                //let currentMediaInfo = self.currentMediaInfos[indexOfCurrentMediaInfo]
                
                // 显示MediaInfo序号和信息
                var stringValue = "\(indexOfCurrentMediaInfo + 1)/\(self.currentMediaInfos.count)\n"
                stringValue += currentMediaInfo.detailInfomation
                
                currentMediaInfoLabel.stringValue = stringValue
                
                eliminateCheckBtn.state = currentMediaInfo.eliminateThisMedia!.intValue
                shareCheckBtn.state = currentMediaInfo.actAsThumbnail!.intValue
                favoriteMediaBtn.state = (currentMediaInfo.favorite?.intValue)!
                favoriteCoordinateInfoBtn.state = (currentMediaInfo.coordinateInfo?.favorite?.intValue)!
                
                // 显示MediaInfo缩略图或原图
                if let thumbnailURL = URL.init(string: currentMediaInfo.thumbnailURLString!){
                    self.imageView.image = NSImage.init(contentsOf:thumbnailURL)
                }else if let imageURL = URL.init(string: currentMediaInfo.urlString!){
                    self.imageView.image = NSImage.init(contentsOf:imageURL)
                }
                
                // 如果是影片
                if currentMediaInfo.contentType == kUTTypeQuickTimeMovie as String{
                    
                }
                
            }else{
                indexOfCurrentMediaInfo = oldValue
            }
        }
    }
    
    /// 只读，计算属性，当前的MediaInfo
    var currentMediaInfo: MediaInfo{
        get{
            return currentMediaInfos[indexOfCurrentMediaInfo]
        }
    }
    
    /// 当前 FootprintAnnotation 的 ThumbnailArray
    var currentFootprintAnnotationThumbnailArray = [Data](){
        didSet{
            indexOfCurrentThumbnail = 0
        }
    }
    
    /// 当前Thumbnail序号
    /// ☆带属性观测器的核心属性
    var indexOfCurrentThumbnail = 0{
        didSet{
            if indexOfCurrentThumbnail >= 0 && indexOfCurrentThumbnail < currentFootprintAnnotationThumbnailArray.count{
                imageView.image = currentThumbnail
                currentMediaInfoLabel.stringValue = "\(indexOfCurrentThumbnail + 1)/\(currentFootprintAnnotationThumbnailArray.count)\n\n\n\n\n\n\n\n"
            }else{
                indexOfCurrentThumbnail = oldValue
            }
        }
    }
    
    /// 只读，当前Thumbnail
    var currentThumbnail: NSImage?{
        get{
            let thumbnailData = currentFootprintAnnotationThumbnailArray[indexOfCurrentThumbnail]
            return NSImage.init(data: thumbnailData)
        }
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.title = NSLocalizedString("Mac Album Maps", comment: "相册地图 - MacOS")
        
        self.addNotificationObserver()
        
        self.initMapView()
        
        self.initControls()
        
        self.updateMediaInfos()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector:#selector(didReceiveNotification(noti:)), name: NSNotification.Name(rawValue: "App_Running_Info"), object: nil)
    }
    
    private func initMapView(){
        mainMapView.delegate = self
        mainMapView.mapType = MKMapType.standard
        mainMapView.showsScale = true
        //mainMapView.showsUserLocation = true
        
        mainMapView.addAnnotations(appContext.coordinateInfos.filter { (info) -> Bool in
            if let favorite = info.favorite{
                return favorite.boolValue
            }else{
                return false
            }
        })
    }
    
    private func initControls(){
        mapModeTabView.delegate = self
        
        // 初始化日期选择器
        self.startDatePicker.dateValue = Date.init(timeIntervalSinceNow: -7*24*60*60)
        self.endDatePicker.dateValue = Date.init(timeIntervalSinceNow: 0)
        
        // 初始化分组距离
        mergeDistanceForMomentTF.stringValue = "200"
        mergeDistanceForLocationTF.stringValue = "1000"
        
        // 初始化NSOutlineView
        let sortedMediaInfos = appContext.mediaInfos.sorted{ (infoA, infoB) -> Bool in
            infoA.creationDate?.compare(infoB.creationDate as! Date) == ComparisonResult.orderedAscending
        }

        rootTreeNode = MAMCoreDataManager.placemarkHierarchicalInfoTreeNode(mediaInfos: sortedMediaInfos)
        self.locationOutlineView.reloadData()
        self.locationOutlineView.expandItem(rootTreeNode)
        
        // 初始化statisticalInfoTV
        if MAMSettingManager.everLaunched {
            statisticalInfoTVString = self.calculateStatisticalInfos(mediaInfos: sortedMediaInfos)
        }else{
            placemarkInfoTF.stringValue = NSLocalizedString("Preparing data for first lanuch, wait please...", comment: "正在为首次使用准备数据，请耐心等待...")
        }
        
        changeOverlayStyleBtn.tag = 0
        
        shareCheckBtn.isHidden = true
        
        browserTableView.register(NSNib.init(nibNamed: "GCTableCellView", bundle: nil), forIdentifier: "GCTableCellView")
    }
    
    private func updateMediaInfos(){
        
        mediaLibraryLoader.loadCompletionHandler = { (loadedMediaObjects: [MLMediaObject]) -> Void in
            if !MAMSettingManager.everLaunched{
                MAMCoreDataManager.latestModificationDate = Date.init(timeIntervalSince1970: 0.0)
                MAMSettingManager.everLaunched = true
            }
            
            self.goBtn.isEnabled = false
            self.loadProgressIndicator.isHidden = false
            self.loadProgressIndicator.startAnimation(self)
            
            
            
            MAMCoreDataManager.updateCoreData(from: loadedMediaObjects)
            
            self.goBtn.isEnabled = true
            self.loadProgressIndicator.stopAnimation(self)
            self.loadProgressIndicator.isHidden = true
            
            MAMCoreDataManager.asyncUpdatePlacemarks()
        }
        
        mediaLibraryLoader.asyncLoadMedia()
    }
    
    // MARK: - 左侧视图 Left View
    
    // MARK: - 主控TabView
    @IBOutlet weak var mapModeTabView: NSTabView!
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        if tabViewItem != nil{
            let tabIndex = tabView.indexOfTabViewItem(tabViewItem!)
            indexOfTabViewItem = tabIndex
        }
    }
    
    // MARK: - 左侧时刻选项栏
    @IBOutlet weak var startDatePicker: NSDatePicker!
    @IBOutlet weak var endDatePicker: NSDatePicker!
    @IBOutlet weak var mergeDistanceForMomentTF: NSTextField!
    
    // MARK: - 左侧地址选项栏
    @IBOutlet weak var mergeDistanceForLocationTF: NSTextField!
    
    // MARK: - 地址模式NSOutlineView
    @IBOutlet weak var locationOutlineView: NSOutlineView!
    var rootTreeNode = GCTreeNode()
    
    // NSOutlineViewDataSource
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item != nil{
            let treeNode = item as! GCTreeNode
            return treeNode.numberOfChildren
        }else{
            return rootTreeNode.numberOfChildren
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        let treeNode = item as! GCTreeNode
        if treeNode.isLeaf {
            return false
        }else{
            return true
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        //print(item)
        if item != nil{
            let treeNode = item as! GCTreeNode
            return treeNode.childAtIndex(index: index)!
        }else{
            return rootTreeNode
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.make(withIdentifier: (tableColumn?.identifier)!, owner: self) as! NSTableCellView
        
        let treeNode = item as! GCTreeNode
        
        if tableColumn?.identifier == "TC0" {
            view.textField?.stringValue =  treeNode.title
        }else if tableColumn?.identifier == "TC1"{
            view.textField?.stringValue = "\(treeNode.representedObject as! Int)"
        }
        
        return view
    }
    
    // NSOutlineViewDelegate
    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        return false
    }
    
    // MARK: - 浏览模式NSTableView
    @IBOutlet weak var browserTableView: NSTableView!
    
    var frInfos: [FootprintsRepositoryInfo]{
        return appContext.footprintsRepositoryInfos.sorted(by: {(infoA, infoB) -> Bool in
            infoA.creationDate?.compare(infoB.creationDate as! Date) == ComparisonResult.orderedDescending})
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return frInfos.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.make(withIdentifier: "GCTableCellView", owner: self)
        
        if view is GCTableCellView{
            let cellView = view as! GCTableCellView
            let info = self.frInfos[row]
            
            var imageName = ""
            if let footprintsRepositoryTypeNumber = info.footprintsRepositoryType{
                let footprintsRepositoryType = FootprintsRepositoryType(rawValue: footprintsRepositoryTypeNumber.intValue)
                switch footprintsRepositoryType! {
                case .Unknown:
                    break
                case .Sent:
                    imageName = "IcoMoon_Share2_WBG.png"
                case .Received:
                    imageName = "IcoMoon_Download_WBG.png"
                case .Recorded:
                    break
                case .Edited:
                    break
                }
            }
            
            if !imageName.isEmpty{
                cellView.thumbnailImageView.image = NSImage.init(named: imageName)
            }
            
            cellView.titleTextField.stringValue = info.title!
            cellView.removeAction = {
                if MAMCoreDataManager.removeFRInfo(frInfo: info){
                    self.browserTableView.reloadData()
                }
            }
            cellView.subTitleTextField.isHidden = true
            
        }else if view is NSTableCellView{
            (view as! NSTableCellView).textField?.stringValue = self.tileString(row: row)
        }
        
        return view
    }
    
//    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
//        let tfCell = cell as! NSTextFieldCell
//        tfCell.title = self.tileString(row: row)
//        
//    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 50
    }
    
//    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
//        if let dataCell = tableColumn?.dataCell(forRow: row){
//            let cell = dataCell as! NSCell
//            cell.stringValue = self.tileString(row: row)
//            return cell
//        }else{
//            return nil
//        }
//        //return NSCell.init(textCell: "oik")//self.tileString(row: row))
//    }
    
    func tileString(row: Int) -> String {
        let info = frInfos[row]
        
        var headerString = ""
        if let footprintsRepositoryTypeNumber = info.footprintsRepositoryType{
            let footprintsRepositoryType = FootprintsRepositoryType(rawValue: footprintsRepositoryTypeNumber.intValue)
            switch footprintsRepositoryType! {
            case .Unknown:
                headerString = "❓"
            case .Sent:
                headerString = "📤"
            case .Received:
                headerString = "📥"
            case .Recorded:
                headerString = "🎥"
            case .Edited:
                headerString = "📦"
            }
        }
        
        return headerString + info.title!
    }
    
//    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
//        return false
//    }
//    
//    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
//        
//        let rowAction = NSTableViewRowAction.init(style: NSTableViewRowActionStyle.destructive, title: "Remove"){ (rowAction, indexPath) in
//            let info = self.frInfos[indexPath]
//            if MAMCoreDataManager.removeFRInfo(frInfo: info){
//                self.browserTableView.reloadData()
//            }
//        }
//        
//        
//        return [rowAction]
//    }
    
    // MARK: - 左侧主控按钮
    
    @IBOutlet weak var goBtn: NSButton!
    /// 当前分组距离
    var currentMergeDistance: Double = 0.0
    var currentStartDate: Date = Date.init(timeIntervalSinceReferenceDate: 0.0)
    var currentEndDate: Date = Date.init(timeIntervalSinceReferenceDate: 0.0)
    var currentPlacemark = ""
    @IBAction func goBtnTD(_ sender: NSButton) {
        goBtn.isEnabled = false
        loadProgressIndicator.isHidden = false
        loadProgressIndicator.startAnimation(self)
        
        var filteredMediaInfos = [MediaInfo]()
        
        switch indexOfTabViewItem {
        case 0:
            // 时刻模式
            currentStartDate = self.startDatePicker.dateValue
            currentEndDate = self.endDatePicker.dateValue
            filteredMediaInfos = appContext.mediaInfos.filter { $0.creationDate.isBetween(self.startDatePicker.dateValue..<self.endDatePicker.dateValue) }.sorted { (infoA, infoB) -> Bool in
                    infoA.creationDate?.compare(infoB.creationDate as! Date) == ComparisonResult.orderedAscending
            }
            
            currentMergeDistance = NSString.init(string: mergeDistanceForMomentTF.stringValue.replacingOccurrences(of: ",", with: "")).doubleValue
            if currentMergeDistance == 0{
                currentMergeDistance = 200
            }
            
            self.showMediaInfos(mediaInfos: filteredMediaInfos,mapMode:MapMode.Moment,mergeDistance: currentMergeDistance)
            
        case 1:
            // 地点模式
            if let item = locationOutlineView.item(atRow: locationOutlineView.selectedRow){
                let tn = item as! GCTreeNode
                
                currentPlacemark = tn.title
                let filteredMediaInfos = appContext.mediaInfos.filter { $0.coordinateInfo.localizedPlaceString_Placemark.contains(tn.title) }.sorted { (infoA, infoB) -> Bool in
                    infoA.creationDate?.compare(infoB.creationDate as! Date) == ComparisonResult.orderedAscending
                }
                
                currentMergeDistance = NSString.init(string: mergeDistanceForLocationTF.stringValue.replacingOccurrences(of: ",", with: "")).doubleValue
                if currentMergeDistance == 0{
                    currentMergeDistance = 1000
                }
                self.showMediaInfos(mediaInfos: filteredMediaInfos,mapMode: MapMode.Location,mergeDistance: currentMergeDistance)
            }
            
        default:
            // 浏览模式
            if browserTableView.selectedRow >= 0{
                let frInfo = frInfos[browserTableView.selectedRow]
                if let fr = FootprintsRepository.importFromMFRFile(filePath: frInfo.filePath){
                    self.showFootprintsRepository(fr: fr)
                }
            }
            
        }
        
        goBtn.isEnabled = true
        loadProgressIndicator.stopAnimation(self)
        loadProgressIndicator.isHidden = true
    }
    
    @IBAction func locationBtnTD(_ sender: NSButton) {
        
    }
    
    
    @IBOutlet weak var loadProgressIndicator: NSProgressIndicator!

    // MARK: - 左侧地址信息解析显示
    @IBOutlet weak var placemarkInfoTF: NSTextField!
    
    // MARK: - 左侧统计信息
    @IBOutlet var statisticalInfoTV: NSTextView!
    var statisticalInfoTVString = ""{
        didSet{
            let dateString = Date.init(timeIntervalSinceNow: 0.0).stringWithDefaultFormat()
            statisticalInfoTV.string = "\n" + dateString + "\n" + statisticalInfoTVString + "\n" + statisticalInfoTV.string!
        }
    }
    
    func didReceiveNotification(noti: NSNotification) {
        for (infoKey,info) in noti.userInfo! {
            switch infoKey as! String {
            case "StatusBar_String":
                placemarkInfoTF.stringValue = info as! String
            case "Long_Info_String":
                //statisticalInfoTVString = info as! String
                if let window = self.view.window{
                    NSAlert.createSimpleAlertAndBeginSheetModal(messageText: info as! String, for: window)
                }
            default:
                break
            }
        }
    }

    // MARK: - 右侧视图 Right View
    
    // MARK: - 地图
    func clearMainMapView() {
        mainMapView.removeAnnotations(currentIDAnnotations)
        mainMapView.removeOverlays(mainMapView.overlays)
        
        currentIDAnnotations = []
        currentMediaInfoGroupAnnotations = []
        //currentFootprintAnnotations = []
        
        currentMediaInfos = []
        
        currentFootprintsRepository = nil
        currentFootprintAnnotationThumbnailArray = []
        
        currentMediaInfoLabel.stringValue = ""
        imageView.image = nil
        
        
//        mainMapView.addAnnotations(appContext.coordinateInfos.filter { (info) -> Bool in
//            if let favorite = info.favorite{
//                return favorite.boolValue
//            }else{
//                return false
//            }
//        })
    }

    // MARK: - 右侧功能按钮
    
    // MARK: - 显示隐藏我的位置
    @IBAction func userLocationBtnTD(_ sender: NSButton) {
        var shows = mainMapView.showsUserLocation
        shows = !shows
        mainMapView.showsUserLocation = shows
        
        if shows {
            mainMapView.selectAnnotation(mainMapView.userLocation, animated: true)
            sender.image = NSImage.init(named: "IcoMoon_User-On_WBG")
        }else{
            sender.image = NSImage.init(named: "IcoMoon_User_WBG")
        }
    }
    
    // MARK: - 地图类型转换
    @IBAction func mapTypeBtnTD(_ sender: NSButton) {
        if mainMapView.mapType == MKMapType.standard {
            mainMapView.mapType = MKMapType.hybrid
        }else{
            mainMapView.mapType = MKMapType.standard
        }
    }
    
    // MARK: - 路线类型转换
    @IBOutlet weak var changeOverlayStyleBtn: NSButton!
    @IBAction func changeOverlayStyleBtnTD(_ sender: NSButton) {
        if changeOverlayStyleBtn.tag == 0 {
            // 当前是模拟路线
            
            print("转为直线路线")
            changeOverlayStyleBtn.tag = 1
        }else{
            // 当前是直线路线
            
            print("转为模拟路线")
            changeOverlayStyleBtn.tag = 0
        }
        
        let previousIndexOfCurrentAnnotation = indexOfCurrentAnnotation - 1
        indexOfCurrentAnnotation = previousIndexOfCurrentAnnotation + 1
    }
    
    // MARK: - 分享足迹包
    @IBAction func shareFootprintsRepositoryBtnTD(_ sender: NSButton) {
        if MAMSettingManager.hasPurchasedShareAndBrowse {
            if let fr = self.createFootprintsRepository(withThumbnailArray: true){
                
                if MAMCoreDataManager.addFRInfo(fr: fr){
                    browserTableView.reloadData()
                }
                
                let fpEditor = FootprintsRepositoryEditor()
                fpEditor.fr = fr
                self.presentViewControllerAsModalWindow(fpEditor)
            }
        }else{
            placemarkInfoTF.stringValue = NSLocalizedString("Did not purchase ShareAndBrowse function.", comment: "尚未购买 ShareAndBrowse 功能！")
            
            let pruchase = PurchaseShareAndBrowseVC()
            self.presentViewControllerAsModalWindow(pruchase)
        }
    }
    
    // MARK: - 导入足迹包
    @IBAction func importBtnTD(_ sender: NSButton) {
        mapModeTabView.selectTabViewItem(at: 2)
        
        let openPanel = NSOpenPanel.init()
        //openPanel.directoryURL = URL.documentURL
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["gpx"]
        openPanel.allowsOtherFileTypes = true
        
        if openPanel.runModal() == NSModalResponseOK{
            if let filePath = openPanel.urls.first?.path{
                print("Import from: " + filePath)
                //print(FileManager.default.fileExists(atPath: filePath))
                if let fr = FootprintsRepository.importFromGPXFile(filePath: filePath){
                    print("Import succeeded!")
                    self.showFootprintsRepository(fr: fr)
                    
                    // 购买 ShareAndBrowse 后才保存足迹包
                    if MAMSettingManager.hasPurchasedShareAndBrowse {
                        fr.footprintsRepositoryType = .Received
                        if MAMCoreDataManager.addFRInfo(fr: fr){
                            placemarkInfoTF.stringValue = NSLocalizedString("Successfully import footprints repository: ", comment: "导入足迹包成功：") + fr.title
                            browserTableView.reloadData()
                        }
                    }
                }else{
                    print("Import failed!")
                    
                    if let window = self.view.window{
                        NSAlert.createSimpleAlertAndBeginSheetModal(messageText: NSLocalizedString("Import failed!", comment: "导入失败！"), for: window)
                    }
                }
            }
        }
    }
    

    // MARK: - 右侧Annotation序号
    @IBOutlet weak var indexOfCurrentAnnotationLabel: NSTextField!
    
    // MARK: - 右侧导航按钮 Navigation
    var playTimer: Timer?
    
    @IBAction func firstBtnTD(_ sender: NSButton) {
        self.indexOfCurrentAnnotation = 0
    }
    
    @IBAction func previousBtnTD(_ sender: NSButton) {
        self.indexOfCurrentAnnotation -= 1
    }
    
    @IBAction func playBtnTD(_ sender: NSButton) {
        if playTimer == nil {
            //playTimer = Timer.init(timeInterval: 2.0, repeats: true, block: { _ in self.indexOfCurrentAnnotation += 1 })
            playTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: { _ in self.indexOfCurrentAnnotation += 1 })
            playTimer?.fire()
            sender.layer?.borderWidth = 3.0
            sender.layer?.borderColor = NSColor.brown.cgColor
        }else{
            playTimer?.invalidate()
            playTimer = nil
            sender.layer?.borderWidth = 0.0
        }
    }
    
    @IBAction func nextBtnTD(_ sender: NSButton) {
        self.indexOfCurrentAnnotation += 1
    }
    
    @IBAction func lastBtnTD(_ sender: NSButton) {
        self.indexOfCurrentAnnotation = self.currentIDAnnotations.count - 1
    }
    
    // MARK: - 右侧底部图片视图 Right Bottom Left Image View
    
    @IBOutlet weak var imageView: NSImageView!
    
    // MARK: - 右侧底部MediaInfo信息视图
    @IBOutlet weak var currentMediaInfoLabel: NSTextField!
    
    // MARK: - 右侧底部图片导航按钮
    /// 上一张图片
    @IBAction func previousImageBtnTD(_ sender: NSButton) {
        if currentMediaInfos.count > 0{
            indexOfCurrentMediaInfo -= 1
        }
        if currentFootprintAnnotationThumbnailArray.count > 0{
            indexOfCurrentThumbnail -= 1
        }
    }
    /// 下一张图片
    @IBAction func nextImageBtnTD(_ sender: NSButton) {
        if currentMediaInfos.count > 0{
            self.indexOfCurrentMediaInfo += 1
        }
        if currentFootprintAnnotationThumbnailArray.count > 0{
            indexOfCurrentThumbnail += 1
        }
    }
    
    @IBOutlet weak var eliminateCheckBtn: NSButton!
    @IBAction func eliminateCheckBtnTD(_ sender: NSButton) {
        //let currentMediaInfo = currentMediaInfos[indexOfCurrentMediaInfo]
        currentMediaInfo.eliminateThisMedia = NSNumber.init(value: sender.state == 1 ? true : false)
        try! appContext.save()
    }
    
    @IBOutlet weak var shareCheckBtn: NSButton!
    @IBAction func shareCheckBtnTD(_ sender: NSButton) {
        //print(sender.state)
        //let currentMediaInfo = currentMediaInfos[indexOfCurrentMediaInfo]
        currentMediaInfo.actAsThumbnail = NSNumber.init(value: sender.state == 1 ? true : false)
        try! appContext.save()
    }
    
    @IBOutlet weak var favoriteMediaBtn: NSButton!
    @IBAction func favoriteMedia(_ sender: NSButton) {
        var isFavorite = (currentMediaInfo.favorite?.boolValue)! ? true : false
        
        isFavorite = !isFavorite
        
        currentMediaInfo.favorite = NSNumber.init(value: isFavorite)
        do {
            try appContext.save()
            //sender.title = isFavorite ? "⭐️" : "☆"
            sender.state = isFavorite ? 1:0
        } catch {
            
        }
    }

    @IBOutlet weak var favoriteCoordinateInfoBtn: NSButton!
    @IBAction func favoriteCoordinate(_ sender: NSButton) {
        if let coordinateInfo = currentMediaInfo.coordinateInfo{
            var isFavorite = (coordinateInfo.favorite?.boolValue)! ? true : false
            
            isFavorite = !isFavorite
            
            currentMediaInfo.coordinateInfo?.favorite = NSNumber.init(value: isFavorite)
            do {
                try appContext.save()
                
                if isFavorite{
                    sender.state = isFavorite ? 1:0
                    mainMapView.addAnnotation(coordinateInfo)
                }else{
                    mainMapView.removeAnnotation(coordinateInfo)
                }
                
            } catch {
                
            }
        }
        
    }
    
    // MARK: - 列表

    @IBAction func itemsBtnTD(_ sender: NSButton) {
        let simple = SimpleCollectionVC()
        self.presentViewControllerAsModalWindow(simple)
    }
    


    // MARK: - 相册地图核心方法
    
    func calculateStatisticalInfos(mediaInfos: [MediaInfo]) -> String {
        var statisticalString = ""
        
        let piDic = MAMCoreDataManager.placemarkInfoDictionary(mediaInfos: mediaInfos)
        //statisticalString += NSLocalizedString("Location statistical info: ", comment: "地点统计信息：") + "\n"
        statisticalString += "∙" + NSLocalizedString("Country: ", comment: "国家：") + "\(piDic[.kCountryArray]!.count)\n"
        statisticalString += "∙" + NSLocalizedString("AdministrativeArea: ", comment: "省：") + "\(piDic[.kAdministrativeAreaArray]!.count)\n"
        statisticalString += "∙" + NSLocalizedString("Locality: ", comment: "市：") + "\(piDic[.kLocalityArray]!.count)\n"
        statisticalString += "∙" + NSLocalizedString("SubLocality: ", comment: "县乡：") + "\(piDic[.kSubLocalityArray]!.count)\n"
        statisticalString += "∙" + NSLocalizedString("Thoroughfare: ", comment: "村镇街道：") + "\(piDic[.kThoroughfareArray]!.count)"
        
        return statisticalString
    }
    
    var currentPlacemarkStatisticalInfo = ""
    func showMediaInfos(mediaInfos: [MediaInfo],mapMode: MapMode,mergeDistance: CLLocationDistance) {
        
        statisticalInfoTVString = self.calculateStatisticalInfos(mediaInfos: mediaInfos)
        currentPlacemarkStatisticalInfo = statisticalInfoTVString.replacingOccurrences(of: "\n", with: ",")
        
        var groupArray: Array<Array<GCLocationAnalyserProtocol>>? = nil
        if mapMode == MapMode.Moment {
            groupArray = GCLocationAnalyser.divideLocationsInOrder(from: mediaInfos,mergeDistance: mergeDistance)
        }else if mapMode == MapMode.Location{
            groupArray = GCLocationAnalyser.divideLocationsOutOfOrder(from: mediaInfos,mergeDistance: mergeDistance)
        }
        
        if groupArray == nil {
            return
        }
        
        self.clearMainMapView()
        
        for (groupIndex,currentGroup) in groupArray!.enumerated() {
            //print("groupIndex: \(groupIndex)")
            
            let mediaGroupAnno = MediaInfoGroupAnnotation()
            //let footprintAnno = FootprintAnnotation()
            
            for (mediaInfoIndex,mediaObject) in currentGroup.enumerated() {
                //print("mediaInfoIndex: \(mediaInfoIndex)")
                let mediaInfo = mediaObject as! MediaInfo
                let creationDate = mediaInfo.creationDate as! Date
                
                // 添加MediaInfo
                mediaGroupAnno.mediaInfos.append(mediaInfo)
                
                if mediaInfoIndex == 0 {
                    // 该组第1张照片
                    mediaGroupAnno.location = mediaInfo.location
                    
                    if let placeName = mediaInfo.coordinateInfo?.localizedPlaceString_Placemark{
                        mediaGroupAnno.annoTitle = placeName.placemarkBriefName()
                    }
//                    else{
//                        mediaGroupAnno.annoTitle = mediaInfo.coordinateInfo?//NSLocalizedString("(Parsing location)", comment: "（正在解析位置）")
//                    }
                    
                    if mapMode == MapMode.Moment {
                        mediaGroupAnno.annoSubtitle = creationDate.stringWithDefaultFormat()
                    }else if mapMode == MapMode.Location{
                        mediaGroupAnno.annoSubtitle = creationDate.stringWithFormat(format: "yyyy-MM-dd")
                    }
                    
                }else if mediaInfoIndex == currentGroup.count - 1{
                    // 该组最后1张照片
                    if mapMode == MapMode.Location{
                        mediaGroupAnno.annoSubtitle += " ~ " + creationDate.stringWithFormat(format: "yyyy-MM-dd")
                    }

                }
                
                if mediaGroupAnno.annoTitle.isEmpty{
                    mediaGroupAnno.annoTitle = mediaGroupAnno.annoSubtitle
                }
                
            }
            
            // 将该点添加到地图
            self.mainMapView.addAnnotation(mediaGroupAnno)
            
            if groupIndex == 0 {
                //print("根据 currentMergeDistance 缩放地图")
                let span = MKCoordinateSpan.init(latitudeDelta: currentMergeDistance / 10000.0, longitudeDelta: currentMergeDistance / 10000.0)
                mainMapView.setRegion(MKCoordinateRegion.init(center: mediaGroupAnno.coordinate, span: span), animated: true)
                
            }
            
            // 更新数组
            self.currentMediaInfoGroupAnnotations.append(mediaGroupAnno)
            
        }
        
        currentIDAnnotations = currentMediaInfoGroupAnnotations
        mainMapView.selectAnnotation(currentIDAnnotations.first!, animated: true)
        
        // 添加
        if mapMode == MapMode.Moment {
            //self.addLineOverlays(annotations: self.currentIDAnnotations)
        }else if mapMode == MapMode.Location{
            self.addCircleOverlays(annotations: self.currentIDAnnotations, radius: mergeDistance / 2.0)
        }
    }
    
    var currentFootprintsRepository: FootprintsRepository?
    func showFootprintsRepository(fr: FootprintsRepository) -> Void {
        if fr.footprintAnnotations.count == 0{
            return
        }
        
        self.clearMainMapView()
        currentFootprintsRepository = fr
        
        mainMapView.addAnnotations(fr.footprintAnnotations)
        currentIDAnnotations = fr.footprintAnnotations
        
        statisticalInfoTVString = fr.placemarkStatisticalInfo
        
        if fr.radius > 0 {
            self.addCircleOverlays(annotations: currentIDAnnotations, radius: fr.radius)
            currentMergeDistance = fr.radius * 2.0
        }
        
        let span = MKCoordinateSpan.init(latitudeDelta: currentMergeDistance / 10000.0, longitudeDelta: currentMergeDistance / 10000.0)
        mainMapView.setRegion(MKCoordinateRegion.init(center: fr.footprintAnnotations.first!.coordinate, span: span), animated: true)
        
        mainMapView.selectAnnotation(currentIDAnnotations.first!, animated: true)
    }
    
    func addLineOverlays(annotations: [MKAnnotation],fixedArrowLength: CLLocationDistance = 0.0) {
        self.mainMapView.removeOverlays(self.mainMapView.overlays)
        
        if annotations.count < 2 {
            return
        }
        
        // 记录距离信息
        var totalDistance: CLLocationDistance = 0.0
        
        // 添加
        var previousCoord: CLLocationCoordinate2D = CLLocationCoordinate2D.init(latitude: 0.0, longitude: 0.0)
        for (index,anno) in annotations.enumerated() {
            if index >= 1 {
                let polyline = MediaMapVC.createLineMKPolyline(startCoordinate: previousCoord, endCoordinate: anno.coordinate)
                let polygon = MediaMapVC.createArrowMKPolygon(startCoordinate: previousCoord, endCoordinate: anno.coordinate ,fixedArrowLength: fixedArrowLength)
                
                self.mainMapView.addOverlays([polyline,polygon])
                
                totalDistance += MKMetersBetweenMapPoints(MKMapPointForCoordinate(previousCoord), MKMapPointForCoordinate(anno.coordinate))
            }
            
            previousCoord = anno.coordinate
        }
    }
    
    class func createLineMKPolyline(startCoordinate:CLLocationCoordinate2D,endCoordinate:CLLocationCoordinate2D) -> MKPolyline {
        let coordinates = [startCoordinate,endCoordinate]
        return MKPolyline.init(coordinates: coordinates, count: 2)
    }
    
    class func createArrowMKPolygon(startCoordinate:CLLocationCoordinate2D,endCoordinate:CLLocationCoordinate2D,fixedArrowLength: CLLocationDistance = 0.0) -> MKPolyline {
        let start_MP: MKMapPoint = MKMapPointForCoordinate(startCoordinate)
        let end_MP: MKMapPoint = MKMapPointForCoordinate(endCoordinate)
        var x_MP: MKMapPoint = MKMapPoint.init()
        var y_MP = x_MP
        var z_MP = x_MP
        
        let arrowLength = fixedArrowLength == 0 ? MKMetersBetweenMapPoints(start_MP, end_MP) : fixedArrowLength
        
        let z_radian = atan2(end_MP.x - start_MP.x, end_MP.y - start_MP.y)
        z_MP.x = end_MP.x - arrowLength * 0.75 * sin(z_radian);
        z_MP.y = end_MP.y - arrowLength * 0.75 * cos(z_radian);
        
        let arrowRadian = 90.0 / 360.0 * M_2_PI
        x_MP.x = end_MP.x - arrowLength * sin(z_radian - arrowRadian)
        x_MP.y = end_MP.y - arrowLength * cos(z_radian - arrowRadian)
        y_MP.x = end_MP.x - arrowLength * sin(z_radian + arrowRadian)
        y_MP.y = end_MP.y - arrowLength * cos(z_radian + arrowRadian)
        
        return MKPolyline.init(points: [z_MP,x_MP,end_MP,y_MP,z_MP], count: 5)
    }
    
    func addCircleOverlays(annotations: [MKAnnotation],radius circleRadius: CLLocationDistance) {
        self.mainMapView.removeOverlays(self.mainMapView.overlays)
        
        if annotations.count < 1 {
            return
        }
        var circleOverlays = [MKCircle]()
        for anno in annotations {
            let circle = MKCircle.init(center: anno.coordinate, radius: circleRadius)
            circleOverlays.append(circle)
        }
        
        self.mainMapView.addOverlays(circleOverlays)
    }
    
    func asyncAddRouteOverlays(annotations: [MKAnnotation],completionHandler:((_ routePolylineCount:Int ,_ routeTotalDistance:CLLocationDistance) -> Void)?){
        
        mainMapView.removeOverlays(self.mainMapView.overlays)
        
        if annotations.count < 2 {
            completionHandler?(0,0)
            return
        }
        
        DispatchQueue.global(qos: .default).async {
            var routeTotalDistance: CLLocationDistance = 0;
            var routePolylineCount = 0;
            var lastCoordinate = CLLocationCoordinate2D.init()
            
            for (annoIndex,anno) in annotations.enumerated() {
                if annoIndex > 0 {
                    MediaMapVC.asyncCreateRouteMKPolyline(startCoordinate: lastCoordinate, endCoordinate: anno.coordinate, completionHandler: { (routePolyline, routeDistance) in
                        var newPolyline = MKPolyline.init()
                        
                        if routePolyline != nil{
                            routePolylineCount += 1
                            routeTotalDistance += routeDistance
                            newPolyline = routePolyline!
                        }else{
                            newPolyline = MediaMapVC.createLineMKPolyline(startCoordinate: lastCoordinate, endCoordinate: anno.coordinate)
                            routeTotalDistance += MKMetersBetweenMapPoints(MKMapPointForCoordinate(lastCoordinate), MKMapPointForCoordinate(anno.coordinate))
                        }
                        
                        DispatchQueue.main.async {
                            self.mainMapView.addOverlays([newPolyline])
                        }
                        
                    })
                }
                lastCoordinate = anno.coordinate
                
                Thread.sleep(forTimeInterval: 0.2)
                if annoIndex % 50 == 0{
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }

        }
        
        
    }
    
    class func asyncCreateRouteMKPolyline(startCoordinate:CLLocationCoordinate2D,endCoordinate:CLLocationCoordinate2D,completionHandler:@escaping (_ routePolyline:MKPolyline?,_ routeDistance:CLLocationDistance) -> Void) {
        let startMapItem = MKMapItem.init(placemark: MKPlacemark.init(coordinate: startCoordinate))
        let endMapItem = MKMapItem.init(placemark: MKPlacemark.init(coordinate: endCoordinate))
        
        let directionsRequest = MKDirectionsRequest.init()
        directionsRequest.source = startMapItem
        directionsRequest.destination = endMapItem
        
        let directions = MKDirections.init(request: directionsRequest)
        
        directions.calculate(completionHandler: { (directionsResponse, error) in
            if let route = directionsResponse?.routes.first{
                let polyline = route.polyline
                completionHandler(polyline,route.distance)
            }else{
                completionHandler(nil,0)
            }
        })
    }
    
    /// 根据添加的 MediaInfoGroupAnnotation数组 生成足迹包
    func createFootprintsRepository(withThumbnailArray: Bool) -> FootprintsRepository? {
        
        if currentMediaInfoGroupAnnotations.isEmpty{
            if let window = self.view.window{
                NSAlert.createSimpleAlertAndBeginSheetModal(messageText: NSLocalizedString("No photos yet. Can not create footprint repository.",comment:"没有添加照片信息，无法创建足迹包！"), for: window)
            }
            
            print("没有添加照片信息，无法创建足迹包！")
            return nil
        }
        
        var footprintAnnotations = [FootprintAnnotation]()
        
        for mediaInfoGroupAnno in currentMediaInfoGroupAnnotations{
            let footprintAnno = FootprintAnnotation()
            
            for (infoIndex,mediaInfo) in mediaInfoGroupAnno.mediaInfos.enumerated() {
                footprintAnno.customTitle = mediaInfoGroupAnno.annoTitle
                
                if infoIndex == 0 {
                    footprintAnno.coordinateWGS84 = mediaInfo.coordinateWGS84
                    footprintAnno.altitude = mediaInfo.location.altitude
                    footprintAnno.speed = mediaInfo.location.speed
                    footprintAnno.startDate = mediaInfo.creationDate as! Date
                }
                    
                if currentMapMode == MapMode.Location && infoIndex == mediaInfoGroupAnno.mediaInfos.count - 1{
                    footprintAnno.endDate = mediaInfo.creationDate as Date?
                }
                
                // 添加缩略图
                if withThumbnailArray {
                    if let thumbnailURLString = mediaInfo.thumbnailURLString{
                        if let thumbnailURL = URL.init(string: thumbnailURLString){
                            
                            var thumbnailData: Data?
                            do {
                                try thumbnailData = Data.init(contentsOf: thumbnailURL)
                            } catch  {
                                
                            }
                            
                            if thumbnailData != nil{
                                footprintAnno.thumbnailArray.append(thumbnailData!)
                            }
                        }
                    }
                }
            }
            
            footprintAnnotations.append(footprintAnno)
        }
        
        //print(footprintAnnotations)
        
        let footprintsRepository = FootprintsRepository()
        footprintsRepository.footprintAnnotations = footprintAnnotations
        footprintsRepository.footprintsRepositoryType = FootprintsRepositoryType.Sent
        footprintsRepository.creationDate = Date.init(timeIntervalSinceNow: 0.0)
        footprintsRepository.placemarkStatisticalInfo = currentPlacemarkStatisticalInfo
        
        if currentMapMode == MapMode.Moment{
            footprintsRepository.title = currentStartDate.stringWithDefaultFormat() + " ~ " + currentEndDate.stringWithDefaultFormat()
        }else if currentMapMode == MapMode.Location {
            footprintsRepository.radius = currentMergeDistance / 2.0
            footprintsRepository.title = currentPlacemark
        }
        
        return footprintsRepository
    }
    
    // MARK: - 地图视图代理方法 MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MediaInfoGroupAnnotation {
            let pinAV = MKPinAnnotationView.init(annotation: annotation, reuseIdentifier: "pinAV")
            pinAV.pinTintColor = NSColor.green.withAlphaComponent(0.6)//DynamicColor.randomColor(in: DynamicColor.preferredAnnotationViewColors)
            pinAV.canShowCallout = true
            
            let mediaGroupAnno = annotation as! MediaInfoGroupAnnotation
            if let mediaInfo = mediaGroupAnno.mediaInfos.first{
                let imageView = NSImageView.init(frame: NSRect.init(x: 0, y: 0, width: 80, height: 80))
                imageView.image = NSImage.init(contentsOf: URL.init(string: mediaInfo.thumbnailURLString!)!)
                pinAV.leftCalloutAccessoryView = imageView
            }
            
            return pinAV
        }else if annotation is CoordinateInfo{
            let starAV = GCStarAnnotationView.init(annotation: annotation, reuseIdentifier: "starAV")
            return starAV
        }else{
            return nil
        }
        
    }
    
    //var lastRandomColor = DynamicColor.randomColor(in: DynamicColor.preferredOverlayColors)
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        var overlayColor = NSColor.green
        
        if let t1 = overlay.title{
            if let t2 = t1{
                if let colorTitle = MKOverlayColorTitle(rawValue:t2){
                    switch colorTitle {
                        case .Random:
                            overlayColor = DynamicColor.randomFlatColor
                        case .Previous:
                            overlayColor = NSColor.purple
                        case .Next:
                            overlayColor = NSColor.blue
                    }
                }
            }
        }
        
        
        if overlay is MKPolyline {
            //lastRandomColor = NSColor.green
            let polylineRenderer = MKPolylineRenderer.init(overlay: overlay)
            polylineRenderer.lineWidth = 3
            polylineRenderer.strokeColor = overlayColor.withAlphaComponent(0.6)
            return polylineRenderer
        }else if overlay is MKPolygon{
            let polygonRenderer = MKPolygonRenderer.init(overlay: overlay)
            polygonRenderer.lineWidth = 1
            polygonRenderer.strokeColor = overlayColor.withAlphaComponent(0.6)
            return polygonRenderer
        }else if overlay is MKCircle {
            //lastRandomColor = NSColor.green
            let circleRenderer = MKCircleRenderer.init(overlay: overlay)
            circleRenderer.lineWidth = 1
            circleRenderer.fillColor = overlayColor.withAlphaComponent(0.4)
            circleRenderer.strokeColor = overlayColor.withAlphaComponent(0.6)
            return circleRenderer
        }else {
            return MKOverlayRenderer.init(overlay: overlay)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //print("mapView didSelect")
        if let currentSelectedAnnotationIndex = self.currentIDAnnotations.index(where: { $0 === view.annotation }){
            self.indexOfCurrentAnnotation = currentSelectedAnnotationIndex.hashValue
        }
        
        if view is MKPinAnnotationView {
            if view.annotation is MediaInfoGroupAnnotation{
                let mediaGroupAnno = view.annotation as! MediaInfoGroupAnnotation
                currentMediaInfos = mediaGroupAnno.mediaInfos
            }else if view.annotation is FootprintAnnotation{
                let footprintAnno = view.annotation as! FootprintAnnotation
                currentFootprintAnnotationThumbnailArray = footprintAnno.thumbnailArray
            }
        }else if view is GCStarAnnotationView{
            if view.annotation is CoordinateInfo{
                let coordinateInfo = view.annotation as! CoordinateInfo
                currentMediaInfoLabel.stringValue = coordinateInfo.locationInfomation
            }
        }
    }
    
}
