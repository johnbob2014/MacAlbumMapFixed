//
//  GCCoordinateTransformer.h
//  Everywhere
//
//  Created by 张保国 on 16/8/18.
//  Copyright © 2016年 ZhangBaoGuo. All rights reserved.
//

@import CoreLocation;

/**
 *  地球坐标、火星坐标、百度坐标 之间相互转化
 *
 *  1.地球坐标（WGS84座标基准）: CLLocationManager
 *
 *  2.火星坐标（GCJ02座标基准）: MKMapView , 高德地图 , 国内Google地图 , 阿里云地图 , 腾讯搜搜地图 , 灵图51ditu地图
 *
 *  3.百度坐标 : 百度地图
 *
 *  @Note 不支持 搜狗坐标 : 搜狐搜狗地图 , 图吧坐标 : 图吧MapBar地图
 *
 */
@interface GCCoordinateTransformer : NSObject

/**
 *  从地球坐标转化到火星坐标
 *
 *  @param earth 地球坐标
 *
 *  @return 火星坐标
 */
+ (CLLocationCoordinate2D)transformToMarsFromEarth:(CLLocationCoordinate2D)earth;

/**
 *  从百度坐标到火星坐标
 *
 *  @param baidu 百度坐标
 *
 *  @return 火星坐标
 */
+ (CLLocationCoordinate2D)transformToMarsFromBaidu:(CLLocationCoordinate2D)baidu;

/**
 *  从火星坐标到地球坐标
 *
 *  @param mars 火星坐标
 *
 *  @return 地球坐标
 */
+ (CLLocationCoordinate2D)transformToEarthFromMars:(CLLocationCoordinate2D)mars;

/**
 *  从百度坐标到地球坐标
 *
 *  @param baidu 百度坐标
 *
 *  @return 地球坐标
 */
+ (CLLocationCoordinate2D)transformToEarthFromBaidu:(CLLocationCoordinate2D)baidu;

/**
 *  从火星坐标转化到百度坐标
 *
 *  @param mars 火星坐标
 *
 *  @return 百度坐标
 */
+ (CLLocationCoordinate2D)transformToBaiduFromMars:(CLLocationCoordinate2D)mars;

/**
 *  从地球坐标转化到百度坐标
 *
 *  @param earth 地球坐标
 *
 *  @return 百度坐标
 */
+ (CLLocationCoordinate2D)transformToBaiduFromEarth:(CLLocationCoordinate2D)earth;

@end
