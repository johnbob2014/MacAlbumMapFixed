//
//  GCCoordinateTransformer.m
//  Everywhere
//
//  Created by 张保国 on 16/8/18.
//  Copyright © 2016年 ZhangBaoGuo. All rights reserved.
//

#import "GCCoordinateTransformer.h"

// --- transform_earth_from_mars ---
// 参考来源：https://on4wp7.codeplex.com/SourceControl/changeset/view/21483#353936
// Krasovsky 1940
//
// a = 6378245.0, 1/f = 298.3
// b = a * (1 - f)
// ee = (a^2 - b^2) / a^2;
const double a = 6378245.0;
const double ee = 0.00669342162296594323;

bool transform_sino_out_china(double lat, double lon)
{
    if (lon < 72.004 || lon > 137.8347)
        return true;
    if (lat < 0.8293 || lat > 55.8271)
        return true;
    return false;
}

double transform_earth_from_mars_lat(double x, double y)
{
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * M_PI) + 40.0 * sin(y / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * M_PI) + 320 * sin(y * M_PI / 30.0)) * 2.0 / 3.0;
    return ret;
}

double transform_earth_from_mars_lng(double x, double y)
{
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * M_PI) + 40.0 * sin(x / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * M_PI) + 300.0 * sin(x / 30.0 * M_PI)) * 2.0 / 3.0;
    return ret;
}

void transform_earth_from_mars(double lat, double lng, double* tarLat, double* tarLng)
{
    if (transform_sino_out_china(lat, lng))
    {
        *tarLat = lat;
        *tarLng = lng;
        return;
    }
    double dLat = transform_earth_from_mars_lat(lng - 105.0, lat - 35.0);
    double dLon = transform_earth_from_mars_lng(lng - 105.0, lat - 35.0);
    double radLat = lat / 180.0 * M_PI;
    double magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * M_PI);
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * M_PI);
    *tarLat = dLat;
    *tarLng = dLon;
}

// --- transform_earth_from_mars end ---

// --- transform_mars_vs_bear_paw ---
// 参考来源：http://blog.woodbunny.com/post-68.html
const double x_pi = M_PI * 3000.0 / 180.0;

void transform_mars_from_baidu(double gg_lat, double gg_lon, double *bd_lat, double *bd_lon)
{
    double x = gg_lon, y = gg_lat;
    double z = sqrt(x * x + y * y) + 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) + 0.000003 * cos(x * x_pi);
    *bd_lon = z * cos(theta) + 0.0065;
    *bd_lat = z * sin(theta) + 0.006;
}

void transform_baidu_from_mars(double bd_lat, double bd_lon, double *gg_lat, double *gg_lon)
{
    double x = bd_lon - 0.0065, y = bd_lat - 0.006;
    double z = sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) - 0.000003 * cos(x * x_pi);
    *gg_lon = z * cos(theta);
    *gg_lat = z * sin(theta);
}
// --- transform_mars_vs_bear_paw end ---

@implementation GCCoordinateTransformer

+ (CLLocationCoordinate2D)transformToMarsFromEarth:(CLLocationCoordinate2D)earth{
    double lat = 0.0;
    double lng = 0.0;
    transform_earth_from_mars(earth.latitude, earth.longitude, &lat, &lng);
    CLLocationCoordinate2D result = CLLocationCoordinate2DMake(earth.latitude + lat, earth.longitude + lng);
    
    if ([GCCoordinateTransformer checkIsValidCoordinate:result]) {
        return result;
    }else{
        return earth;
    }
}

+ (CLLocationCoordinate2D)transformToMarsFromBaidu:(CLLocationCoordinate2D)baidu{
    double lat = 0.0;
    double lng = 0.0;
    transform_baidu_from_mars(baidu.latitude, baidu.longitude, &lat, &lng);
    CLLocationCoordinate2D result = CLLocationCoordinate2DMake(lat, lng);
    
    if ([GCCoordinateTransformer checkIsValidCoordinate:result]) {
        return result;
    }else{
        return baidu;
    }
}

+ (CLLocationCoordinate2D)transformToEarthFromMars:(CLLocationCoordinate2D)mars{
    double lat = 0.0;
    double lng = 0.0;
    transform_earth_from_mars(mars.latitude, mars.longitude, &lat, &lng);
    CLLocationCoordinate2D result =  CLLocationCoordinate2DMake(mars.latitude - lat, mars.longitude - lng);
    
    if ([GCCoordinateTransformer checkIsValidCoordinate:result]) {
        return result;
    }else{
        return mars;
    }
}

+ (CLLocationCoordinate2D)transformToEarthFromBaidu:(CLLocationCoordinate2D)baidu{
    CLLocationCoordinate2D mars = [GCCoordinateTransformer transformToMarsFromBaidu:baidu];
    return [GCCoordinateTransformer transformToEarthFromMars:mars];
}

+ (CLLocationCoordinate2D)transformToBaiduFromMars:(CLLocationCoordinate2D)mars{
    double lat = 0.0;
    double lng = 0.0;
    transform_mars_from_baidu(mars.latitude, mars.longitude, &lat, &lng);
    CLLocationCoordinate2D result = CLLocationCoordinate2DMake(lat, lng);
    
    if ([GCCoordinateTransformer checkIsValidCoordinate:result]) {
        return result;
    }else{
        return mars;
    }
}

+ (CLLocationCoordinate2D)transformToBaiduFromEarth:(CLLocationCoordinate2D)earth{
    CLLocationCoordinate2D mars = [GCCoordinateTransformer transformToMarsFromEarth:earth];
    return [GCCoordinateTransformer transformToBaiduFromMars:mars];
}

+ (BOOL)checkIsValidCoordinate:(CLLocationCoordinate2D)coordinate{
    BOOL valid = NO;
    if (coordinate.latitude > -90 && coordinate.latitude < 90 && coordinate.latitude != 0 && coordinate.longitude > -180 && coordinate.longitude < 180 && coordinate.longitude != 0) {
        valid = YES;
    }
    return valid;
}

@end

