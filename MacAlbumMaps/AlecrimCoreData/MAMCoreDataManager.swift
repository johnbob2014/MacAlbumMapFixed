//
//  MAMCoreDataAssistant.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/2/17.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
import MapKit
import MediaLibrary

let EntityName_CoordinateInfo = "CoordinateInfo"


/// 地址信息数据字典键
enum PlacemarkInfoDictionaryKey : String {
    case kCountryArray = "kCountryArray"
    case kAdministrativeAreaArray = "kAdministrativeAreaArray"
    case kSubAdministrativeAreaArray = "kSubAdministrativeAreaArray"
    case kLocalityArray = "kLocalityArray"
    case kSubLocalityArray = "kSubLocalityArray"
    case kThoroughfareArray = "kThoroughfareArray"
    case kSubThoroughfareArray = "kSubThoroughfareArray"
}

//MARK: - 扩展
extension CoordinateInfo : MKAnnotation{
    
    //  MKAnnotation Protocol
    public var coordinate: CLLocationCoordinate2D {
        let mar = GCCoordinateTransformer.transformToMars(fromEarth:self.coordinateWGS84)
        if mar.isValid(){
            return mar
        }else{
            return self.coordinateWGS84
        }
        //return GCCoordinateTransformer.transformToMars(fromEarth:self.coordinateWGS84)
    }
    
    public var title: String?{
        return self.localizedPlaceString_Placemark?.placemarkBriefName()
    }
    
    /// WGS84座标
    var coordinateWGS84: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake((self.latitude?.doubleValue)!, (self.longitude?.doubleValue)!)
    }
    
    /// 地址信息字符串
    var locationInfomation: String{
        get{
            var detail = ""
            detail += NSLocalizedString("Location Information:",comment:"位置信息：") + "\n"
            detail += self.coordinateWGS84.latitude > 0 ? NSLocalizedString("N. ",comment: "北纬 "):NSLocalizedString("S. ",comment: "南纬 ")
            detail += "\(fabs(self.coordinateWGS84.latitude))  "
            detail += self.coordinateWGS84.longitude > 0 ? NSLocalizedString("E. ",comment: "东经 "):NSLocalizedString("W. ",comment: "西经 ")
            detail += "\(fabs(self.coordinateWGS84.longitude))\n"
            
            if let localizedPlaceString = self.localizedPlaceString_Placemark{
                detail += localizedPlaceString
            }else{
                detail += NSLocalizedString("Can not parse this coordinate",comment:"无法解析该座标")
            }
            
            return detail
        }
    }
    
    /// 更新地址信息
    func updatePlacemark(geocoder: CLGeocoder,completionHandler:((Bool, String?) -> Void)? = nil) {
        geocoder.reverseGeocodeLocation(CLLocation.init(latitude: self.coordinateWGS84.latitude, longitude: self.coordinateWGS84.longitude)) { (placemarks, error) in
            if error == nil{
                
                if let placemark = placemarks?.last{
                    
                    self.name_Placemark = placemark.name
                    self.ccISOcountryCode_Placemark = placemark.isoCountryCode
                    self.country_Placemark = placemark.country;
                    self.postalCode_Placemark = placemark.postalCode;
                    self.administrativeArea_Placemark = placemark.administrativeArea;
                    self.subAdministrativeArea_Placemark = placemark.subAdministrativeArea;
                    self.locality_Placemark = placemark.locality;
                    self.subLocality_Placemark = placemark.subLocality;
                    self.thoroughfare_Placemark = placemark.thoroughfare;
                    self.subThoroughfare_Placemark = placemark.subThoroughfare;
                    self.inlandWater_Placemark = placemark.inlandWater;
                    self.ocean_Placemark = placemark.ocean;
                    
                    self.localizedPlaceString_Placemark = placemark.localizedPlaceString(inReverseOrder: false, withInlandWaterAndOcean: false)
                    
                    print(self.localizedPlaceString_Placemark!)
                    completionHandler?(true,self.localizedPlaceString_Placemark!)
                    self.reverseGeocodeSucceed = NSNumber.init(value: true)
                    try! appContext.save()
                }else{
                    completionHandler?(false, nil)
                }
                
            }else{
                self.reverseGeocodeFailureCount += 1
                try! appContext.save()
                completionHandler?(false, nil)
            }
            
        }
    }

}

extension MediaInfo: GCLocationAnalyserProtocol{
    
    var coordinateWGS84: CLLocationCoordinate2D {
        let coordinateInfo = self.coordinateInfo!
        
        return CLLocationCoordinate2D.init(latitude: CLLocationDegrees(coordinateInfo.latitude!), longitude: CLLocationDegrees(coordinateInfo.longitude!))
    }

    // GCLocationAnalyserProtocol
    var location: CLLocation{
        return CLLocation.init(latitude: self.coordinateWGS84.latitude, longitude: self.coordinateWGS84.longitude)
    }
    
    var mediaTitle: String{
        var name = self.name
        if name == nil {
            if let urlString = self.urlString{
                name = URL.init(string: urlString)!.lastPathComponent
            }else{
                name = ""
            }
        }
        return name!
    }
    
    /// 详细信息字符串
    var detailInfomation: String{
        get{
            var detail = ""
            
            // 添加照片信息
            
            detail += NSLocalizedString("Name: ",comment: "名称：") + mediaTitle + "\n"
            
            if let contentType = self.contentType{
                detail += NSLocalizedString("Content Type: ",comment: "类型：") + contentType + "\n"
            }
            
            let floatFileSize = Float(fileSize)
            var fileSizeString = "\(floatFileSize)"
            if floatFileSize > 1024 * 1024 {
                fileSizeString = String.init(format: "%.2fM",floatFileSize/1024.0/1024.0)
            }else if floatFileSize > 1024{
                fileSizeString = String.init(format: "%.1fKB",floatFileSize/1024)
            }
            detail += NSLocalizedString("File Size: ",comment: "大小：") + fileSizeString + "\n"
            
            if let creationDate = self.creationDate{
                detail += NSLocalizedString("Taken Date: ",comment: "拍摄日期：") + (creationDate as Date).stringWithDefaultFormat() + "\n"
            }
            
            if let modificationDate = self.modificationDate{
                detail += NSLocalizedString("Imported Date: ",comment: "导入日期：") + (modificationDate as Date).stringWithDefaultFormat() + "\n"
            }
            
            // 添加地址信息
            if let coordinateInfo = self.coordinateInfo{
                detail += coordinateInfo.locationInfomation
            }
            
            return detail
        }
    }
}

extension FootprintsRepositoryInfo{
    var filePath: String {
        var path = ""
        if self.identifier != nil{
            path = appApplicationSupportPath + "/" + self.identifier!
        }else{
            path = appApplicationSupportPath + "/" + String.init(format: "%.0f", Date.timeIntervalSinceReferenceDate * 1000)
        }
        return path
    }
}

//MARK: - CoreData管理器
class MAMCoreDataManager: NSObject {
    
    // MARK: - MLMediaObject验证及更新
    
    /// 所有已更新照片的最晚一个导入到Mac的日期
    class var latestModificationDate: Date{
        get{
            if let md = NSUserDefaultsController.shared().defaults.value(forKey: "latestModificationDate"){
                return md as! Date
            }else{
                return Date.init(timeIntervalSince1970: 0.0)
            }
        }
        set{
            NSUserDefaultsController.shared().defaults.setValue(newValue, forKey: "latestModificationDate")
            NSUserDefaultsController.shared().defaults.synchronize()
        }
    }
    
    /// 验证数据
    /// Helps to make sure the media object is the photo format we want.
    class func isValidImage(_ mediaObject: MLMediaObject) -> Bool{
        var isValidImage = false
        
        let attrs = mediaObject.attributes
        let contentTypeStr = attrs[MLMediaObjectHiddenAttributeKeys.contentTypeKey] as! String
        
        // We only want photos, not movies or older PICT formats (PICT image files are not supported in a sandboxed environment).
        // if ((contentTypeStr != kUTTypePICT as String) && (contentTypeStr != kUTTypeQuickTimeMovie as String)){
        if (contentTypeStr != kUTTypePICT as String){
            if let latitudeNumber = attrs[MLMediaObjectHiddenAttributeKeys.latitudeKey]{
                if let longitudeNumber = attrs[MLMediaObjectHiddenAttributeKeys.longitudeKey]{
                    let latitude = (latitudeNumber as! NSNumber).doubleValue
                    let longitude = (longitudeNumber as! NSNumber).doubleValue
                    if (latitude > -90 && latitude < 90 && latitude != 0 && longitude > -180 && longitude < 180 && longitude != 0){
                        if let DateAsTimerInterval = attrs[MLMediaObjectHiddenAttributeKeys.DateAsTimerIntervalKey]{
                            print(MAMCoreDataManager.imageTitle(from: mediaObject),DateAsTimerInterval,latitude,longitude)
                            isValidImage = true
                        }
                        
                        /*
                         if let Places = attrs[MLMediaObjectHiddenAttributeKeys.PlacesKey]{
                         print(Places)
                         }
                         
                         if let Name = attrs[MLMediaObjectHiddenAttributeKeys.NameKey]{
                         print(Name)
                         }
                         
                        if let FaceList = attrs[MLMediaObjectHiddenAttributeKeys.FaceListKey]{
                            print(FaceList)
                            let array = FaceList as! NSArray
                            let dic = array.firstObject as! NSDictionary
                            
                            let faceKey = dic["faceKey"] as! String
                            print(faceKey)
                            
                            let faceTileImageURL = dic["faceTileImageURL"] as! NSURL
                            print(faceTileImageURL.absoluteString!)
                            
                            let index = dic["index"] as! NSNumber
                            print(index)
                            
                            let name = dic["name"] as! String
                            print(name)
                            
                            let rectangle = dic["rectangle"] as! String
                            print(rectangle)
                            
                        }
                        */
                    }
                }
            }
            
        }
        
        return isValidImage
    }
    
    /// 获取 MLMediaObject 的名字
    /// Obtains the title of the MLMediaObject (either the meta name or the last component of the URL).
    class func imageTitle(from mediaObject: MLMediaObject) -> String {
        guard let title = mediaObject.attributes["name"] else {
            return mediaObject.url!.lastPathComponent
        }
        return title as! String
    }
    
    /// 从指定的 MLMediaObject数组 中获取数据
    ///
    /// - Parameter mediaObjects: MLMediaObject数组
    class func asyncUpdateCoreData(from mediaObjects:[MLMediaObject]){
        DispatchQueue.global(qos: .default).async {
            MAMCoreDataManager.updateCoreData(from: mediaObjects)
        }
    }

    /// 从指定的 MLMediaObject数组 中获取数据
    ///
    /// - Parameter mediaObjects: MLMediaObject数组
    class func updateCoreData(from mediaObjects:[MLMediaObject]){
        var validMediaObjects = [MLMediaObject]()
        
        let latestMD = self.latestModificationDate
        
        var newLatestMD: Date = latestMD
        for mediaObject in mediaObjects {
            if let currentMD = mediaObject.modificationDate{
                if currentMD.compare(latestMD) == ComparisonResult.orderedDescending {
                    if (MAMCoreDataManager.isValidImage(mediaObject)){
                        validMediaObjects.append(mediaObject)
                    }
                }
                
                if currentMD.compare(newLatestMD) == ComparisonResult.orderedDescending{
                    newLatestMD = currentMD
                }
            }
        }
        
        // 更新所有照片的最新导入日期
        self.latestModificationDate = newLatestMD
        
        var keyArray : [String] = []
        
        for aMO in validMediaObjects {
            for aKey in aMO.attributes.keys {
                if !keyArray.contains(aKey) {
                    keyArray.append(aKey)
                }
            }
        }
        
        if keyArray.count > 0 {
            print("[MLMediaObject] keyArray:\n\(keyArray)")
        }
        
        var addCoordinateInfoCount = 0
        var addMediaInfoCount = 0
        
        for mediaObject in validMediaObjects {
            let latitude = mediaObject.attributes[MLMediaObjectHiddenAttributeKeys.latitudeKey] as! NSNumber
            let longitude = mediaObject.attributes[MLMediaObjectHiddenAttributeKeys.longitudeKey] as! NSNumber
            
            var currentCoordInfo : CoordinateInfo?
            
            let exitsCoordInfo = appContext.coordinateInfos.first(where: { $0.latitude == latitude && $0.longitude == longitude })
            if exitsCoordInfo == nil{
                let newCoordInfo = appContext.coordinateInfos.create()
                newCoordInfo.latitude = latitude
                newCoordInfo.longitude = longitude
                addCoordinateInfoCount += 1
                
                currentCoordInfo = newCoordInfo
            }else{
                currentCoordInfo = exitsCoordInfo
            }
            
            let exitsMediaInfo = appContext.mediaInfos.first(where: { $0.identifier == mediaObject.identifier })
            if exitsMediaInfo == nil{
                let newMediaInfo = appContext.mediaInfos.create()
                
                newMediaInfo.coordinateInfo = currentCoordInfo
                
                newMediaInfo.identifier = mediaObject.identifier
                newMediaInfo.contentType = mediaObject.contentType
                //newMediaInfo.faceListArray = NSData.ini (mediaObject.attributes[MLMediaObjectHiddenAttributeKeys.FaceListKey] as! NSArray)
                newMediaInfo.fileSize = Int64(mediaObject.fileSize)
                newMediaInfo.mediaSourceIdentifier = mediaObject.mediaSourceIdentifier
                newMediaInfo.mediaType = Int16(mediaObject.mediaType.rawValue)
                newMediaInfo.name = mediaObject.name
                newMediaInfo.originalURLString = mediaObject.originalURL?.absoluteString
                newMediaInfo.thumbnailURLString = mediaObject.thumbnailURL?.absoluteString
                newMediaInfo.urlString = mediaObject.url?.absoluteString
                newMediaInfo.modificationDate = mediaObject.modificationDate as NSDate?
                
                let attrs = mediaObject.attributes
                
                if let DateAsTimerInterval = attrs[MLMediaObjectHiddenAttributeKeys.DateAsTimerIntervalKey]{
                    newMediaInfo.creationDate = NSDate.init(timeIntervalSinceReferenceDate: DateAsTimerInterval as! TimeInterval)
                }
                
                addMediaInfoCount += 1
            }
        }
        
        var scanPhotosResult = ""
        
        do {
            try appContext.save()
            
            if addMediaInfoCount > 0{
                scanPhotosResult += NSLocalizedString("Scan medias result:", comment: "扫描媒体结果:") + "\n\n"
                scanPhotosResult += "∙" + NSLocalizedString("New Media Count: ", comment: "新添加媒体数: ") + "\(addMediaInfoCount)" + "\n"
                scanPhotosResult += "∙" + NSLocalizedString("Total Media Count: ", comment: "总媒体数: ") + "\(appContext.mediaInfos.count())" + "\n"
                scanPhotosResult += "∙" + NSLocalizedString("New Coordinate Count: ", comment: "新添加座标点数: ") + "\(addCoordinateInfoCount)" + "\n"
                scanPhotosResult += "∙" + NSLocalizedString("Total Coordinate Count: ", comment: "总座标点数: ") + "\(appContext.coordinateInfos.count())" + "\n"
                
                scanPhotosResult += "\n" + NSLocalizedString("Latest date: ", comment: "最新日期: ") + latestMD.stringWithDefaultFormat()
            }
            
        } catch  {
            scanPhotosResult += NSLocalizedString("Failed to scan medias!", comment: "扫描媒体失败!")
        }
        
        if !scanPhotosResult.isEmpty{
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "App_Running_Info"), object: nil, userInfo: ["Long_Info_String":scanPhotosResult])
        }
    
    }
    
    // MARK: - 地址信息解析工具
    
    /// 更新CoordinateInfo的Placemark
    class func asyncUpdatePlacemarks() -> Void {
        DispatchQueue.global(qos: .background).async{
            let geocoder = CLGeocoder.init()
            let total = appContext.coordinateInfos.count()
            let coordinateInfos = appContext.coordinateInfos.filter(){ $0.reverseGeocodeSucceed?.boolValue == false }
            
            if coordinateInfos.count == 0{
                // 已经全部解析完成
                DispatchQueue.main.async {
                    let infoString = NSLocalizedString("Total Coordinate Count:", comment: "座标点总计：") + "\(total) " + NSLocalizedString("Parsing is complete!", comment: "地址信息已全部解析完成！")
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "App_Running_Info"), object: nil, userInfo: ["StatusBar_String":infoString])
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "App_Running_Info"), object: nil, userInfo: ["Needs_Update_View":""])
                }
            }
            
            let reverseGeocodeSucceedCount = total - coordinateInfos.count
            
            for (index,coordinateInfo) in coordinateInfos.enumerated(){
                
                if coordinateInfo.reverseGeocodeFailureCount <= 5{
                    coordinateInfo.updatePlacemark(geocoder: geocoder){
                        (succeeded,placemarkString) -> Void in
                        var infoString = NSLocalizedString("Parsing coordinate: ", comment: "正在解析座标：") + "\(reverseGeocodeSucceedCount+index+1)/\(total)  "
                        infoString += succeeded ? placemarkString! : "\(index) " + NSLocalizedString("Parse failed!", comment: "解析失败！")
                        
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "App_Running_Info"), object: nil, userInfo: ["StatusBar_String":infoString])
                        }
                        
                    }
                    Thread.sleep(forTimeInterval: 1.0)
                }else{
                    print("解析失败5次以上，不再解析！")
                }
            }
            
            // 解析失败5次以上的总个数
            let failures = appContext.coordinateInfos.filter({ (info) -> Bool in
                info.reverseGeocodeFailureCount >= 5
            })
            var infoString = ""
            if failures.count > 0{
                infoString = NSLocalizedString("Parse complete. ",comment:"本次解析完成。 ") + "\(failures.count)" + NSLocalizedString("Coordinates failed to reverse more than 5 times.",comment:"个座标解析失败5次以上，不再解析！")
            }else{
                infoString = NSLocalizedString("Parse complete.",comment:"本次解析完成。")
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "App_Running_Info"), object: nil, userInfo: ["StatusBar_String":infoString])
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "App_Running_Info"), object: nil, userInfo: ["Needs_Update_View":""])
            }
        }
    }
    
    
    /// 统计一个 CoordinateInfo数组 的 地址信息数据
    ///
    /// - Parameter coordinateInfos: CoordinateInfo数组
    /// - Returns: 地址信息数据字典，只包含名称数组，不包含层级
    class func placemarkInfoDictionary(coordinateInfos: [CoordinateInfo]) -> Dictionary<PlacemarkInfoDictionaryKey, [String]> {
        var countryArray = [String]()
        var administrativeAreaArray = [String]()
        var subAdministrativeAreaArray = [String]()
        var localityArray = [String]()
        var subLocalityArray = [String]()
        var thoroughfareArray = [String]()
        var subThoroughfareArray = [String]()
        
        for info in coordinateInfos{
            if let country_Placemark = info.country_Placemark {
                if !countryArray.contains(country_Placemark){
                    countryArray.append(country_Placemark)
                }
            }
            
            if let administrativeArea_Placemark = info.administrativeArea_Placemark{
                if !administrativeAreaArray.contains(administrativeArea_Placemark){
                    administrativeAreaArray.append(administrativeArea_Placemark)
                }
            }
            
            if let subAdministrativeArea_Placemark = info.subAdministrativeArea_Placemark{
                if !subAdministrativeAreaArray.contains(subAdministrativeArea_Placemark){
                    subAdministrativeAreaArray.append(subAdministrativeArea_Placemark)
                }
            }
            
            if let locality_Placemark = info.locality_Placemark{
                if !localityArray.contains(locality_Placemark){
                    localityArray.append(locality_Placemark)
                }
            }
            
            if let subLocality_Placemark = info.subLocality_Placemark{
                if !subLocalityArray.contains(subLocality_Placemark){
                    subLocalityArray.append(subLocality_Placemark)
                }
            }
            
            if let thoroughfare_Placemark = info.thoroughfare_Placemark{
                if !thoroughfareArray.contains(thoroughfare_Placemark){
                    thoroughfareArray.append(thoroughfare_Placemark)
                }
            }
            
            if let subThoroughfare_Placemark = info.subThoroughfare_Placemark{
                if !subThoroughfareArray.contains(subThoroughfare_Placemark){
                    subThoroughfareArray.append(subThoroughfare_Placemark)
                }
            }
        }

        return [.kCountryArray:countryArray,
                .kAdministrativeAreaArray:administrativeAreaArray,
                .kSubAdministrativeAreaArray:subAdministrativeAreaArray,
                .kLocalityArray:localityArray,
                .kSubLocalityArray:subLocalityArray,
                .kThoroughfareArray:thoroughfareArray,
                .kSubThoroughfareArray:subThoroughfareArray]
    }
    
    /// 统计一个 MediaInfo数组 的 地址信息数据
    ///
    /// - Parameter mediaInfos: MediaInfo数组
    /// - Returns: 地址信息数据字典，只包含名称数组，不包含层级
    class func placemarkInfoDictionary(mediaInfos: [MediaInfo]) -> Dictionary<PlacemarkInfoDictionaryKey, [String]> {
        var coordinateInfos = [CoordinateInfo]()
        for mediaInfo in mediaInfos {
            if let coordinateInfo = mediaInfo.coordinateInfo{
                coordinateInfos.append(coordinateInfo)
            }
        }
        return MAMCoreDataManager.placemarkInfoDictionary(coordinateInfos: coordinateInfos)
    }

    
    /// 统计一个 CoordinateInfo数组 的 地址信息数据
    ///
    /// - Parameter coordinateInfos: CoordinateInfo数组
    /// - Returns: 地址信息数据字典，包含层级，格式为 ["国家": ["省": ["市": ["县区": ["村镇街道": 村镇街道个数]]]]]
    class func placemarkHierarchicalInfoDictionary(coordinateInfos: [CoordinateInfo]) -> Dictionary<String, Dictionary<String, Dictionary<String, Dictionary<String, Dictionary<String, Int>>>>> {
        var countryDic = Dictionary<String, Dictionary<String, Dictionary<String, Dictionary<String, Dictionary<String, Int>>>>>()
        
        for info in coordinateInfos{
            if let country_Placemark = info.country_Placemark {
                if nil == countryDic[country_Placemark]{
                    // 如果不存在这个国家，创建一个
                    countryDic[country_Placemark] = Dictionary<String, Dictionary<String, Dictionary<String, Dictionary<String, Int>>>>()
                }
                
                if let administrativeArea_Placemark = info.administrativeArea_Placemark{
                    if nil == countryDic[country_Placemark]![administrativeArea_Placemark]{
                        // 如果不存在这个省，创建一个
                        countryDic[country_Placemark]![administrativeArea_Placemark] = Dictionary<String, Dictionary<String, Dictionary<String, Int>>>()
                    }
                    
                    if let locality_Placemark = info.locality_Placemark{
                        if nil == countryDic[country_Placemark]![administrativeArea_Placemark]![locality_Placemark]{
                            // 如果不存在这个市，创建一个
                             countryDic[country_Placemark]![administrativeArea_Placemark]![locality_Placemark] = Dictionary<String, Dictionary<String, Int>>()
                        }
                        
                        if let subLocality_Placemark = info.subLocality_Placemark{
                            if nil == countryDic[country_Placemark]![administrativeArea_Placemark]![locality_Placemark]![subLocality_Placemark]{
                                // 如果不存在这个县区，创建一个
                                countryDic[country_Placemark]![administrativeArea_Placemark]![locality_Placemark]![subLocality_Placemark] = Dictionary<String, Int>()
                            }
                            
                            if let thoroughfare_Placemark = info.thoroughfare_Placemark{
                                if let thoroughfareCount = countryDic[country_Placemark]![administrativeArea_Placemark]![locality_Placemark]![subLocality_Placemark]![thoroughfare_Placemark]{
                                    // 已经包含这个村镇街道，令这个的村镇街道的个数加1
                                    countryDic[country_Placemark]![administrativeArea_Placemark]![locality_Placemark]![subLocality_Placemark]![thoroughfare_Placemark] = thoroughfareCount + 1
                                }else{
                                    // 创建一个村镇街道，并将其个数设为1
                                    countryDic[country_Placemark]![administrativeArea_Placemark]![locality_Placemark]![subLocality_Placemark]![thoroughfare_Placemark] = 1
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return countryDic
    }
    
    /// 统计一个 MediaInfo数组 的 地址信息数据
    ///
    /// - Parameter mediaInfos: MediaInfo数组
    /// - Returns: 地址信息数据字典，包含层级，格式为 ["国家": ["省": ["市": ["县区": ["村镇街道": 村镇街道个数]]]]]
    class func placemarkHierarchicalInfoDictionary(mediaInfos: [MediaInfo]) -> Dictionary<String, Dictionary<String, Dictionary<String, Dictionary<String, Dictionary<String, Int>>>>> {
        var coordinateInfos = [CoordinateInfo]()
        for mediaInfo in mediaInfos {
            if let coordinateInfo = mediaInfo.coordinateInfo{
                coordinateInfos.append(coordinateInfo)
            }
        }
        return MAMCoreDataManager.placemarkHierarchicalInfoDictionary(coordinateInfos: coordinateInfos)
    }
    
    
    /// 根据 地址信息数据字典，包含层级 生成 可用于NSOutlineView的GCTreeNode
    ///
    /// - Parameter placemarkHierarchicalInfoDictionary: 地址信息数据字典，包含层级
    /// - Returns: 可用于NSOutlineView的GCTreeNode
    class func placemarkHierarchicalInfoTreeNode(placemarkHierarchicalInfoDictionary: Dictionary<String, Dictionary<String, Dictionary<String, Dictionary<String, Dictionary<String, Int>>>>>) -> GCTreeNode{
        let rootTreeNode = GCTreeNode()
        rootTreeNode.title = NSLocalizedString("全部", comment: "")
        
        var rootRO = 0
        for (countryTitle,countryDic) in placemarkHierarchicalInfoDictionary{
            let countryTN = GCTreeNode()
            countryTN.parent = rootTreeNode
            countryTN.title = countryTitle
            
            var countryRO = 0
            for (administrativeAreaTitle,administrativeAreaDic) in countryDic {
                let administrativeAreaTN = GCTreeNode()
                administrativeAreaTN.parent = countryTN
                administrativeAreaTN.title = administrativeAreaTitle
                
                var administrativeAreaRO = 0
                for (localityTitle,localityDic) in administrativeAreaDic {
                    let localityTN = GCTreeNode()
                    localityTN.parent = administrativeAreaTN
                    localityTN.title = localityTitle
                    
                    var localityRO = 0
                    for (subLocalityTitle,subLocalityDic) in localityDic {
                        let subLocalityTN = GCTreeNode()
                        subLocalityTN.parent = localityTN
                        subLocalityTN.title = subLocalityTitle
                        
                        var subLocalityRO = 0
                        for (thoroughfareTitle,thoroughfareCount) in subLocalityDic {
                            let thoroughfareTN = GCTreeNode()
                            thoroughfareTN.parent = subLocalityTN
                            thoroughfareTN.title = thoroughfareTitle
                            
                            thoroughfareTN.isLeaf = true
                            thoroughfareTN.representedObject = thoroughfareCount
                            
                            subLocalityRO += thoroughfareCount
                            
                            subLocalityTN.children.append(thoroughfareTN)
                        }
                        
                        subLocalityTN.representedObject = subLocalityRO > 0 ? subLocalityRO : 1
                        
                        localityRO += subLocalityRO
                        
                        localityTN.children.append(subLocalityTN)
                    }
                    
                    localityTN.representedObject = localityRO > 0 ? localityRO : 1
                    
                    administrativeAreaRO += localityRO
                    
                    administrativeAreaTN.children.append(localityTN)
                }
                
                administrativeAreaTN.representedObject = administrativeAreaRO > 0 ? administrativeAreaRO : 1
                
                countryRO += administrativeAreaRO
                
                countryTN.children.append(administrativeAreaTN)
            }
            
            countryTN.representedObject = countryRO > 0 ? countryRO : 1
            
            rootRO += countryRO > 0 ? countryRO : 1
            
            rootTreeNode.children.append(countryTN)
        }
        
        rootTreeNode.representedObject = rootRO > 0 ? rootRO : 1
        return rootTreeNode
    }
    
    
    /// 根据 CoordinateInfo数组 生成 可用于NSOutlineView的GCTreeNode
    ///
    /// - Parameter coordinateInfos: CoordinateInfo数组
    /// - Returns: 可用于NSOutlineView的GCTreeNode
    class func placemarkHierarchicalInfoTreeNode(coordinateInfos: [CoordinateInfo]) -> GCTreeNode{
        return MAMCoreDataManager.placemarkHierarchicalInfoTreeNode(placemarkHierarchicalInfoDictionary: MAMCoreDataManager.placemarkHierarchicalInfoDictionary(coordinateInfos: coordinateInfos))
    }
    
    /// 根据 MediaInfo数组 生成 可用于NSOutlineView的GCTreeNode
    ///
    /// - Parameter mediaInfos: MediaInfo数组
    /// - Returns: 可用于NSOutlineView的GCTreeNode
    class func placemarkHierarchicalInfoTreeNode(mediaInfos: [MediaInfo]) -> GCTreeNode{
        return MAMCoreDataManager.placemarkHierarchicalInfoTreeNode(placemarkHierarchicalInfoDictionary: MAMCoreDataManager.placemarkHierarchicalInfoDictionary(mediaInfos: mediaInfos))
    }
    
    // MARK: - FootprintsRepositoryInfo
    
    /// 添加 FootprintsRepositoryInfo
    class func addFRInfo(fr: FootprintsRepository) -> Bool {
//        if FileManager.directoryExists(directoryPath: appApplicationSupportPath, autoCreate: true) == false {
//            print("无法创建存储文件夹，添加足迹包失败！")
//            return false
//        }
        
        if let existsInfo = appContext.footprintsRepositoryInfos.first(where: { $0.identifier == fr.identifier }){
            print("已经存在相同的足迹包，添加失败！ ID:\(existsInfo.identifier)")
            return false
        }else{
            
            let filePath = appApplicationSupportPath + "/" + fr.identifier
            
            if fr.exportToMFRFile(filePath: filePath) {
                
                let info = appContext.footprintsRepositoryInfos.create()
                
                info.footprintsCount = NSNumber.init(value: fr.footprintAnnotations.count)
                info.creationDate = fr.creationDate as NSDate?
                info.radius = NSNumber.init(value: fr.radius)
                info.footprintsRepositoryType = NSNumber.init(value: fr.footprintsRepositoryType.rawValue)
                info.title = fr.title;
                info.placemarkStatisticalInfo = fr.placemarkStatisticalInfo;
                info.modificatonDate = fr.modificatonDate as NSDate?
                
                info.distance = NSNumber.init(value: fr.distance)
                info.startDate = fr.startDate as NSDate
                info.endDate = fr.endDate as NSDate
                info.duration = NSNumber.init(value: fr.duration)
                info.averageSpeed = NSNumber.init(value: fr.averageSpeed)
                
                info.identifier = fr.identifier
                
                do {
                    try appContext.save()
                    print("足迹包 \(info.title) 添加成功，存储位置：\n\(info.filePath)")
                    return true
                    
                } catch {
                    print("足迹包 \(fr.title) 添加失败！")
                    return false
                }
                
            }else{
                print("创建足迹包文件失败！")
                return false
            }
            
        }
    }
    
    /// 移除 FootprintsRepositoryInfo
    class func removeFRInfo(frInfo: FootprintsRepositoryInfo) -> Bool {
        let title = frInfo.title!
        let filePath = frInfo.filePath
        var succeeded = false
        
        appContext.delete(frInfo)
        
        do {
            try appContext.save()
            print("足迹包 \(title) 移除成功")
            succeeded = true
        } catch  {
            print("足迹包 \(title) 移除失败！")
        }
        
        if FileManager.default.fileExists(atPath: filePath) {
            do {
                try FileManager.default.removeItem(atPath: filePath)
                print("足迹包文件删除成功")
            } catch  {
                print("足迹包文件删除失败！")
            }
        }
        
        return succeeded
    }
    
    /// 移除所有 FootprintsRepositoryInfo
    ///
    /// - Returns: (成功数,总数) 元组
    class func removeAllFRInfos() -> (Int,Int) {
        let totalCount = appContext.footprintsRepositoryInfos.count()
        var succeededCount = 0
        for frInfo in appContext.footprintsRepositoryInfos{
            if MAMCoreDataManager.removeFRInfo(frInfo: frInfo){
                succeededCount += 1
            }
        }
        return (succeededCount,totalCount)
    }
}


/*
extension CoordinateInfo : MKAnnotation{
 
 
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake((self.latitude?.doubleValue)!, (self.longitude?.doubleValue)!)
    }
 
    class func truncatedValue(_ aValue:Double) -> Double {
        let truncateBase : Double = pow(10, 10)
        return floor(aValue * truncateBase) / truncateBase
    }
    
    class func fetch(_ latitude:Double , _ longitude:Double) -> CoordinateInfo? {
        var info:CoordinateInfo?
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: EntityName_CoordinateInfo)
        // 查找时，对参数值进行截取
        fetchRequest.predicate = NSPredicate.init(format: "(latitude = %@) && (longitude = %@)", NSNumber.init(value: CoordinateInfo.truncatedValue(latitude)),NSNumber.init(value: CoordinateInfo.truncatedValue(longitude)))
        
        do {
            let matches = try appContext.fetch(fetchRequest)
            if matches.count >= 1 {
                info = matches.first as? CoordinateInfo
            }
            
        } catch {
            
        }
        
        return info;
    }
    
    class func fetchAll() -> [CoordinateInfo]?{
        var matches : [CoordinateInfo]?
        
        let fetchRequest = NSFetchRequest<CoordinateInfo>(entityName: EntityName_CoordinateInfo)
        do {
            matches = try appContext.fetch(fetchRequest)
        } catch  {
            
        }
        
        if matches?.count == 0 {
            print("No CoordinateInfo Yet!")
        }
        
        return matches
    }
    
    class func deleteAll(){
        if let all = CoordinateInfo.fetchAll(){
            for info in all {
                appContext.delete(info)
            }
            
            do {
                try appContext.save()
                print("save ok")
            } catch  {
                print("save error")
            }

        }
        
    }
    
    class func create(_ latitude:Double , _ longitude:Double) -> CoordinateInfo{
        if let fetchInfo = CoordinateInfo.fetch(latitude, longitude){
            return fetchInfo
        }else{
            let newInfo = NSEntityDescription.insertNewObject(forEntityName: EntityName_CoordinateInfo, into: appContext) as! CoordinateInfo
            
            // 赋值时，对参数值进行截取
            newInfo.latitude = NSNumber.init(value: CoordinateInfo.truncatedValue(latitude))
            newInfo.longitude = NSNumber.init(value: CoordinateInfo.truncatedValue(longitude))
            
            do {
                try appContext.save()
                print("save ok")
            } catch  {
                print("save error")
            }
            
            return newInfo;
        }

    }
    
    class func create(_ location:CLLocation) -> CoordinateInfo{
        if let fetchInfo = CoordinateInfo.fetch(location.coordinate.latitude, location.coordinate.longitude){
            return fetchInfo
        }else{
            let newInfo = NSEntityDescription.insertNewObject(forEntityName: EntityName_CoordinateInfo, into: appContext) as! CoordinateInfo
            
            // 赋值时，对参数值进行截取
            newInfo.latitude = NSNumber.init(value: CoordinateInfo.truncatedValue(location.coordinate.latitude))
            newInfo.longitude = NSNumber.init(value: CoordinateInfo.truncatedValue(location.coordinate.longitude))
            newInfo.altitude = NSNumber.init(value: location.altitude)
            
            newInfo.speed = NSNumber.init(value: location.speed)
            newInfo.course = NSNumber.init(value: location.course)
            newInfo.horizontalAccuracy = NSNumber.init(value: location.horizontalAccuracy)
            newInfo.verticalAccuracy = NSNumber.init(value: location.verticalAccuracy)
            //info.level = NSNumber.init(value: location.floor?.level)
            
            do {
                try appContext.save()
                print("save ok")
            } catch  {
                print("save error")
            }
            
            return newInfo;
        }
    }
}
*/
