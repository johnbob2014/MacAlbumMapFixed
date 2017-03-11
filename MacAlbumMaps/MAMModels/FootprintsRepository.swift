//
//  FootprintsRepository.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/3/8.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa

enum FootprintsRepositoryType: Int {
    case Unknown = 0
    case Sent = 1
    case Received = 2
    case Recorded = 4
    case Edited = 8
}

class FootprintsRepository: NSObject,NSCoding {
    override init() {
        super.init()
    }
    
    /// 必须，包含的足迹点数组
    var footprintAnnotations = [FootprintAnnotation]()
    
    /// 必须，创建日期
    var creationDate = Date.init(timeIntervalSinceNow: 0.0)
    
    /// 范围半径
    var radius = 0.0
    
    /// 类型
    var footprintsRepositoryType = FootprintsRepositoryType.Unknown
    
    /// 标题
    var title = ""
    
    /// 地点统计信息字符串
    var placemarkStatisticalInfo = ""
    
    /// 修改日期
    var modificatonDate: Date?
    
    /// 只读，唯一标识符
    var identifier: String{
        get{
            return (NSKeyedArchiver.archivedData(withRootObject: self.footprintAnnotations) as NSData).md5String() as String
        }
    }
    
    /// 只读，缩略图数量
    var thumbnailCount: Int{
        get{
            var count = 0
            for anno in self.footprintAnnotations {
                count += anno.thumbnailArray.count
            }
            return count
        }
    }
    
    // MARK: - 只读属性，仅 radius == 0 时有才有意义
    
    /// 只读，总长度
    var distance: Double{
        get{
            if self.footprintAnnotations.count <= 1 {
                return 0
            }
            
            var totalDistance = 0.0
            for (annoIndex,anno) in self.footprintAnnotations.enumerated() {
                if annoIndex > 0 {
                    totalDistance += anno.location.distance(from: self.footprintAnnotations[annoIndex - 1].location)
                }
            }
            return totalDistance
        }
    }
    
    /// 开始时间
    var startDate: Date{
        get{
            if let start = self.footprintAnnotations.first?.startDate{
                return start
            }else{
                return Date.init(timeIntervalSinceReferenceDate: 0.0)
            }
        }
    }
    
    /// 结束时间
    var endDate: Date{
        get{
            if let end = self.footprintAnnotations.last?.startDate{
                return end
            }else{
                return Date.init(timeIntervalSinceReferenceDate: 0.0)
            }
        }
    }
    
    /// 持续时间
    var duration: TimeInterval{
        get{
            return self.endDate.timeIntervalSince(self.startDate)
        }
    }
    
    /// 平均速度
    var averageSpeed: Double{
        get{
            return self.distance/self.duration
        }
    }
    
    // MARK: - NSCoding
    required init?(coder aDecoder: NSCoder) {
        super.init()
        
        self.footprintAnnotations = aDecoder.decodeObject(forKey:"footprintAnnotations") as! [FootprintAnnotation]
        
        self.radius = aDecoder.decodeDouble(forKey:"radius")
        
        self.title = aDecoder.decodeObject(forKey:"title") as! String
        
        self.creationDate = aDecoder.decodeObject(forKey: "creationDate") as! Date
        
        if let modificatonDate = aDecoder.decodeObject(forKey:"modificatonDate"){
            self.modificatonDate = modificatonDate as? Date
        }
        
        let footprintsRepositoryType = aDecoder.decodeInteger(forKey:"footprintsRepositoryType")
        self.footprintsRepositoryType = FootprintsRepositoryType.init(rawValue: footprintsRepositoryType)!
        
        self.placemarkStatisticalInfo = aDecoder.decodeObject(forKey:"placemarkStatisticalInfo") as! String
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.footprintAnnotations, forKey: "footprintAnnotations")
        aCoder.encode(self.radius, forKey: "radius")
        aCoder.encode(self.title, forKey: "title")
        aCoder.encode(self.creationDate, forKey: "creationDate")
        
        if self.modificatonDate != nil {
            aCoder.encode(self.modificatonDate, forKey: "modificatonDate")
        }
        
        aCoder.encode(self.footprintsRepositoryType.rawValue, forKey: "footprintsRepositoryType")
        aCoder.encode(self.placemarkStatisticalInfo, forKey: "placemarkStatisticalInfo")
    }
    
    // MARK: - Export To and Import From MFR File
    func exportToMFRFile(filePath: String) -> Bool {
        return NSKeyedArchiver.archiveRootObject(self, toFile: filePath)
    }
    
    class func importFromMFRFile(filePath: String) -> FootprintsRepository? {
        if FileManager.default.fileExists(atPath: filePath) == false {
            print("MFR文件不存在，从MFR文件生成足迹包失败！")
            return nil
        }
        
        if let obj = NSKeyedUnarchiver.unarchiveObject(withFile: filePath){
            return obj as? FootprintsRepository
        }else{
            print("数据解析错误，从MFR文件生成足迹包失败！")
            return nil
        }
    }
    
    // MARK: - Export To and Import From GPX File
    
    func exportToGPXFile(filePath: String) -> Bool{
        var gpx_String = ""
        
        // xml版本及编码
        gpx_String += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        
        // gpx头
        gpx_String += "\n<gpx"
        gpx_String += "\n    version=\"1.0\""
        gpx_String += "\n    creator=\"GPSBabel - http://www.gpsbabel.org\""
        gpx_String += "\n    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\""
        gpx_String += "\n    xmlns=\"http://www.topografix.com/GPX/1/0\""
        gpx_String += "\n    xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd\">"
        
        // 缩进1层
        // 日期
        gpx_String += String.init(format:"\n    <time>%@T%@Z</time>", self.creationDate.stringWithFormat(format: "yyyy-MM-dd"),self.creationDate.stringWithFormat(format: "hh:mm:ss"))
        
        // 名称
        gpx_String += String.init(format:"\n    <name>%@</name>",self.title)
        
        // 座标范围
        if let firstFP = footprintAnnotations.first{
            var minlat = firstFP.coordinateWGS84.latitude
            var minlon = firstFP.coordinateWGS84.longitude
            var maxlat = minlat
            var maxlon = minlon
            
            for fp in footprintAnnotations {
                let currentLatitude = fp.coordinateWGS84.latitude
                if currentLatitude < minlat {
                    minlat = currentLatitude
                }
                if currentLatitude > maxlat {
                    maxlat = currentLatitude
                }
                
                let currentLongitude = fp.coordinateWGS84.longitude
                if currentLongitude < minlon {
                    minlon = currentLongitude
                }
                if currentLongitude > maxlon{
                    maxlon = currentLongitude
                }
            }
            
            gpx_String += String.init(format:"\n    <bounds minlat=\"%.9f\" minlon=\"%.9f\" maxlat=\"%.9f\" maxlon=\"%.9f\"/>",minlat,minlon,maxlat,maxlon)
        }
        
        // AlbumMaps特有属性 足迹包类型
        gpx_String += String.init(format:"\n    <footprintsRepositoryType>%lu</footprintsRepositoryType>",footprintsRepositoryType.rawValue)
        
        // AlbumMaps特有属性 足迹包半径
        gpx_String += String.init(format:"\n    <radius>%.2f</radius>",radius)
        
        // 添加wpt
        for fp in footprintAnnotations {
            if fp.isUserManuallyAdded {
                gpx_String += fp.gpx_wpt_String()
            }
        }
        
        // 添加trk
        gpx_String += "\n    <trk>"
        
        // 缩进2层
        gpx_String += "\n        <name>AlbumMaps Line Track</name>"
        gpx_String += "\n        <trkseg>"
        
        // 添加trkpt
        for fp in footprintAnnotations {
            gpx_String += fp.gpx_trk_trkseg_trkpt_String()
        }
        
        // 回缩，结束trkseg
        gpx_String += "\n        </trkseg>"
        
        // 回缩，结束trk
        gpx_String += "\n    </trk>"
        
        // 回缩，结束gpx
        gpx_String += "\n</gpx>"
        
        // 写入文件
        if let gpx_Data = gpx_String.data(using: .utf8){
            let fileURL = URL.init(fileURLWithPath: filePath)
            do {
                try gpx_Data.write(to: fileURL)
                return true
            } catch  {
                return false
            }
        }else{
            return false
        }
    }
    
    class func importFromGPXFile(filePath: String) -> FootprintsRepository? {
        // 使用XMLDictionary解析gpx文件
        let gpxFileDic = NSDictionary.init(xmlFile: filePath)
        if gpxFileDic == nil{
            return nil
        }
        
        let footprintsRepository = FootprintsRepository()
        
        var userManuallyAddedFootprintArray = [FootprintAnnotation]()
        var footprintArray = [FootprintAnnotation]()
        for (key,value) in gpxFileDic! {
            var keyString = ""
            if key is String || key is NSString{
                keyString = key as! String
            }
            
            switch keyString{
            case "name":
                if value is String || value is NSString { footprintsRepository.title = value as! String }
            case "time":
                if value is String || value is NSString { footprintsRepository.creationDate = Date.dateFromGPXTimeString(timeString: value as! String) }
            case "footprintsRepositoryType":
                if value is String || value is NSString { footprintsRepository.footprintsRepositoryType = FootprintsRepositoryType(rawValue: Int((value as! NSString).intValue))! }
            case "radius":
                if value is String || value is NSString { footprintsRepository.radius = (value as! NSString).doubleValue }
            case "wpt":
                // 添加wpt
                var wptNSDicArray = NSArray.init()
                // 如果只有一个点，wptDicArray会被XMLDictionary解析成字典，这时候，需要将wptDicArray转化为数组
                if value is NSArray {
                    wptNSDicArray = value as! NSArray
                }else if value is NSDictionary{
                    wptNSDicArray = NSArray.init(object: value)
                }
                
                for wptNSDic in wptNSDicArray {
                    if wptNSDic is NSDictionary{
                        let wptDic = wptNSDic as! Dictionary<String,String>
                        let fp = FootprintAnnotation.footprintAnnotationFromGPXPointDictionary(pointDictionary: wptDic, isUserManuallyAdded: true)
                        userManuallyAddedFootprintArray.append(fp)
                    }
                }
            case "trk":
                // 添加trkpt
                if value is NSDictionary {
                    let trkNSDic = value as! NSDictionary
                    
                    if trkNSDic.allKeys.contains(where: { (key) -> Bool in
                        (key as! String) == "trkseg"
                    }) {
                        // trksegDic
                        let trksegNSDic = trkNSDic["trkseg"] as! NSDictionary
                        
                        if trksegNSDic.allKeys.contains(where: { (key) -> Bool in
                            (key as! String) == "trkpt"
                        }) {
                            let trkObject = trksegNSDic["trkpt"]
                            
                            var trkptNSDicArray = NSArray.init()
                            if trkObject is NSArray {
                                trkptNSDicArray = trkObject as! NSArray
                            }else if trkObject is NSDictionary{
                                if trkObject != nil {
                                    trkptNSDicArray = NSArray.init(object: trkObject!)
                                }
                            }
                            
                            for trkptNSDic in trkptNSDicArray {
                                if trkptNSDic is NSDictionary {
                                    let trkptDic = trkptNSDic as! Dictionary<String,String>
                                    let fp = FootprintAnnotation.footprintAnnotationFromGPXPointDictionary(pointDictionary: trkptDic, isUserManuallyAdded: false)
                                    footprintArray.append(fp)
                                }
                            }
                            
                        }
                        
                    }
                }
            default:
                break
            }
        }
        
        footprintArray.append(contentsOf: userManuallyAddedFootprintArray)
        
        // 按时间排序
        footprintArray.sort(by: {$0.0.startDate.compare($0.1.startDate) == ComparisonResult.orderedAscending})
        
        footprintsRepository.footprintAnnotations = footprintArray
        
        return footprintsRepository
    }

}
