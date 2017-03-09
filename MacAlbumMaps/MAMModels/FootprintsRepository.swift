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
    case Recorded = 3
    case Edited = 4
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
    var footprintsRepositoryType: FootprintsRepositoryType?
    
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
        if footprintsRepositoryType != 0 {
            self.footprintsRepositoryType = FootprintsRepositoryType.init(rawValue: footprintsRepositoryType)
        }
        
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
        
        if self.footprintsRepositoryType != nil {
            aCoder.encode(self.footprintsRepositoryType!.rawValue, forKey: "footprintsRepositoryType")
        }
        
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

}
