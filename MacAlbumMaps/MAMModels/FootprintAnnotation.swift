//
//  FootprintAnnotation.swift
//  MacAlbumMaps
//
//  Created by BobZhang on 2017/2/23.
//  Copyright © 2017年 ZhangBaoGuo. All rights reserved.
//

import Cocoa
import MapKit

/// 足迹点
class FootprintAnnotation: NSObject,MKAnnotation,NSCoding,GCLocationAnalyserProtocol{
    
    /// 必需，coordinateWGS84
    var coordinateWGS84: CLLocationCoordinate2D = CLLocationCoordinate2D.init(latitude: 0.0, longitude: 0.0)
    
    /// 必需，开始时间
    var startDate: Date = Date.init(timeIntervalSinceNow: 0.0)
    
    /// 结束时间
    var endDate: Date?
    
    /// 高度
    var altitude: CLLocationDistance = 0.0
    
    /// 速度
    var speed: CLLocationSpeed = 0.0
    
    /// 自定义标题
    var customTitle = ""
    
    /// 标记该FootprintAnnotation是否为用户手动添加，主要用于记录和编辑
    var isUserManuallyAdded: Bool = false
    
    /// 缩略图数据数组
    var thumbnailArray = [Data]()
    
    override init(){
        super.init()
    }
    
    // MARK: - MKAnnotation
    var coordinate: CLLocationCoordinate2D{
        return GCCoordinateTransformer.transformToMars(fromEarth:self.coordinateWGS84)
    }
    
    var title: String?{
        if self.customTitle.isEmpty{
            return subtitle
        }else{
            return self.customTitle
        }
    }
    
    var subtitle: String?{
        return dateString
    }
    
    var dateString: String{
        if let end = endDate {
            return startDate.stringWithFormat(format: "yyyy-MM-dd") + " ~ " + end.stringWithFormat(format: "yyyy-MM-dd")
        }else{
            return startDate.stringWithDefaultFormat()
        }
    }
    
    // MARK: - GCLocationAnalyserProtocol
    var location: CLLocation{
        return CLLocation.init(latitude: self.coordinateWGS84.latitude, longitude: self.coordinateWGS84.longitude)
    }
    
    // MARK: - NSCoding
    required init?(coder aDecoder: NSCoder) {
        super.init()
        
        let coordinateWGS84Point = aDecoder.decodePoint(forKey: "coordinateWGS84Point")
        self.coordinateWGS84 = CLLocationCoordinate2D.init(latitude: CLLocationDegrees(coordinateWGS84Point.x), longitude: CLLocationDegrees(coordinateWGS84Point.y))
        
        self.startDate = aDecoder.decodeObject(forKey: "startDate") as! Date
        
        if let endDate = aDecoder.decodeObject(forKey:"endDate"){
            self.endDate = endDate as? Date
        }
        
        self.customTitle = aDecoder.decodeObject(forKey: "customTitle") as! String
        
        self.isUserManuallyAdded = aDecoder.decodeBool(forKey: "isUserManuallyAdded")
        
        self.altitude = aDecoder.decodeDouble(forKey: "altitude")
        
        self.speed = aDecoder.decodeDouble(forKey: "speed")
        
        self.thumbnailArray = aDecoder.decodeObject(forKey: "thumbnailArray") as! [Data]
    }
    
    func encode(with aCoder: NSCoder) {
        let coordinateWGS84Point = NSPoint.init(x: self.coordinateWGS84.latitude, y: self.coordinateWGS84.longitude)
        aCoder.encode(coordinateWGS84Point, forKey: "coordinateWGS84Point")
        
        aCoder.encode(self.startDate, forKey: "startDate")
        
        if self.endDate != nil {
            aCoder.encode(self.endDate, forKey: "endDate")
        }
        
        aCoder.encode(self.customTitle, forKey: "customTitle")
        
        aCoder.encode(self.isUserManuallyAdded, forKey: "isUserManuallyAdded")
        
        aCoder.encode(self.altitude, forKey: "altitude")
        
        aCoder.encode(self.speed, forKey: "speed")
        
        aCoder.encode(self.thumbnailArray, forKey: "thumbnailArray")
    }
    
    // MARK: - Export To and Import From GPX File
    
    func gpx_wpt_String() -> String {
        var gpx_wpt_String = ""
        
        gpx_wpt_String += String.init(format:"\n    <wpt lat=\"%.9f\" lon=\"%.9f\">",self.coordinateWGS84.latitude,self.coordinateWGS84.longitude)
        gpx_wpt_String += String.init(format:"\n    <ele>%.2f</ele>",self.altitude)
        gpx_wpt_String += String.init(format:"\n    <name>%@</name>",self.customTitle)
        gpx_wpt_String += String.init(format:"\n    <time>%@T%@Z</time>",self.startDate.stringWithFormat(format: "yyyy-MM-dd"),self.startDate.stringWithFormat(format: "hh:mm:ss"))
        if let end = self.endDate{
            gpx_wpt_String += String.init(format:"\n    <endtime>%@T%@Z</endtime>",end.stringWithFormat(format: "yyyy-MM-dd"),end.stringWithFormat(format: "hh:mm:ss"))
        }
        gpx_wpt_String += "\n    </wpt>"
        
        return gpx_wpt_String
    }
    
    func gpx_trk_trkseg_trkpt_String() -> String {
        var gpx_trk_trkseg_trkpt_String = ""
        
        gpx_trk_trkseg_trkpt_String += String.init(format:"\n            <trkpt lat=\"%.9f\" lon=\"%.9f\">",self.coordinateWGS84.latitude,self.coordinateWGS84.longitude)
        gpx_trk_trkseg_trkpt_String += String.init(format:"\n            <ele>%.2f</ele>",self.altitude)
        gpx_trk_trkseg_trkpt_String += String.init(format:"\n            <time>%@T%@Z</time>",self.startDate.stringWithFormat(format: "yyyy-MM-dd"),self.startDate.stringWithFormat(format: "hh:mm:ss"))
        if let end = self.endDate{
            gpx_trk_trkseg_trkpt_String  += String.init(format:"\n            <endtime>%@T%@Z</endtime>",end.stringWithFormat(format: "yyyy-MM-dd"),end.stringWithFormat(format: "hh:mm:ss"))
        }
        gpx_trk_trkseg_trkpt_String += "\n            </trkpt>"
        
        return gpx_trk_trkseg_trkpt_String
    }
    
    class func footprintAnnotationFromGPXPointDictionary(pointDictionary: Dictionary<String,String>,isUserManuallyAdded: Bool) -> FootprintAnnotation {
        
        let footprintAnnotation = FootprintAnnotation()
        footprintAnnotation.isUserManuallyAdded = isUserManuallyAdded
        
        for (key,value) in pointDictionary {
            switch key {
            case "name":
                footprintAnnotation.customTitle = value
            case "_lat":
                footprintAnnotation.coordinateWGS84.latitude = (value as NSString).doubleValue
            case "_lon":
                footprintAnnotation.coordinateWGS84.longitude = (value as NSString).doubleValue
            case "ele":
                footprintAnnotation.altitude = (value as NSString).doubleValue
            case "time":
                footprintAnnotation.startDate = Date.dateFromGPXTimeString(timeString: value)
            case "endtime":
                // AlbumMaps特有属性 endtime endDate
                footprintAnnotation.endDate = Date.dateFromGPXTimeString(timeString: value)
            default:
                break
            }
        }
        
        return footprintAnnotation
    }

}
