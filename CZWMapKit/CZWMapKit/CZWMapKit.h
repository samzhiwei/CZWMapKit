//
//  CZWMapKit.h
//  CZWMapKit
//
//  Created by tianqu on 16/6/30.
//  Copyright © 2016年 Tianqu. All rights reserved.
/*  PS.流程-> 
 Global设置启动baiduMap ->
 创建CZWMapView视图     ->(不需要mapView显示的话可以跳过这一步)
 启动相应服务                   ->
 */

#import <Foundation/Foundation.h>
#import "BaiduMapAPI/BaiduMapAPI_Map.framework/Headers/BMKMapComponent.h"
#import "BaiduMapAPI/BaiduMapAPI_Base.framework/Headers/BMKBaseComponent.h"
#import "BaiduMapAPI/BaiduMapAPI_Cloud.framework/Headers/BMKCloudSearchComponent.h"
#import "BaiduMapAPI/BaiduMapAPI_Radar.framework/Headers/BMKRadarComponent.h"
#import "BaiduMapAPI/BaiduMapAPI_Utils.framework/Headers/BMKUtilsComponent.h"
#import "BaiduMapAPI/BaiduMapAPI_Search.framework/Headers/BMKSearchComponent.h"
#import "BaiduMapAPI/BaiduMapAPI_Location.framework/Headers/BMKLocationComponent.h"
#import "CZWMapView.h"

#define kCZWMapKit  [CZWMapKit shareMapKit]
#define kAppMapKey @"RiBS6xnsj6Qyr9Q7rwTpyLj7"  //启动秘钥

typedef NS_ENUM(NSUInteger, CZWLocatingMode) {
    CZWLocatingOnce = 0,
    CZWLocatingAlways = 1
};
@class CZWMapKit;
@protocol CZWMapKitLocationDelegate <NSObject>
@optional
/**
 *  不实现就根据defaultMapView方法去加载mapView
 */
- (CZWMapView *)showMapViewWithMapKit:(CZWMapKit *)mapKit;

- (void)mapKit:(CZWMapKit *)mapKit didLocationPostion:(CLLocationCoordinate2D)coor;
- (void)didFinishLocationPostionWithMapKit:(CZWMapKit *)mapKit;

- (void)mapKit:(CZWMapKit *)mapKit didLocationCity:(BMKAddressComponent *)addressDetail;
- (void)mapKit:(CZWMapKit *)mapKit didLocationAddress:(NSString *)address;
- (void)didFinishGeoLocationPostionWithMapKit:(CZWMapKit *)mapKit;



@end
@interface CZWMapKit : NSObject
@property (weak, nonatomic) id <CZWMapKitLocationDelegate> locationDelegate;

@property (strong, nonatomic, readonly) CLLocation *cacheUserLocation;
@property (strong, nonatomic, readonly) NSString *cacheCity;
@property (strong, nonatomic, readonly) NSString *cacheAddress;

+ (instancetype)shareMapKit;
/**
 *  授权
 */
- (void)czw_userAuthorization:(CLAuthorizationStatus)status;
/**
 *  开启定位
 */
- (void)czw_startLocating:(id<CZWMapKitLocationDelegate>)delegate showInView:(UIView *)view locatingMode:(CZWLocatingMode)mode;
- (void)czw_stopLocating;

/**
 *  开启反地理编码
 */
- (void)czw_reverseGeoCode:(CLLocationCoordinate2D)coor;

#pragma mark - global setting
- (void)czw_setUpMapManager;
@end
