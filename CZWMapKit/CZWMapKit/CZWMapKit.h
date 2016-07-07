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

#define kCZWCacheAddressDidChange @"CZWCacheAddressDidChange"
#define kCZWCacheCityDidChange @"CZWCacheCityDidChange"
#define kCZWCacheUserLocationDidChange @"CZWCacheUserLocationDidChange"


#define kCZWMapKit  [CZWMapKit shareMapKit]
#define kAppMapKey @"Huguh0KNzNP1RCkHKfG5wKywywxaSTDF"  //启动秘钥

typedef NS_ENUM(NSUInteger, CZWLocatingMode) {
    CZWLocatingOnce = 0,
    CZWLocatingAlways = 1
};
@class CZWMapKit;

@protocol CZWMapViewDelegate <NSObject>
@required
/**
 *  返回地图
 */
- (CZWMapView *)showMapViewWithMapKit:(CZWMapKit *)mapKit;
/**
 *  将地图加载到你指定的区域
 */
- (void)addMapInView:(CZWMapView *)mapView;
@end

@protocol CZWMapKitLocationDelegate <NSObject>
@optional

- (void)mapKit:(CZWMapKit *)mapKit didLocationPostion:(CLLocationCoordinate2D)coor;
- (void)didFinishLocationPostionWithMapKit:(CZWMapKit *)mapKit;
- (void)mapKit:(CZWMapKit *)mapKit didLocationCity:(BMKAddressComponent *)addressDetail;
- (void)mapKit:(CZWMapKit *)mapKit didLocationAddress:(NSString *)address;
- (void)didFinishGeoLocationPostionWithMapKit:(CZWMapKit *)mapKit;

@end
@interface CZWMapKit : NSObject <BMKMapViewDelegate>


#pragma mark - ====BaseSetting====
@property (weak, nonatomic) id <CZWMapKitLocationDelegate> locationDelegate;
@property (weak, nonatomic) id <CZWMapViewDelegate> mapViewDelegate;
@property (strong, nonatomic, readonly) CZWMapView *mapView;//显示地图
@property (assign, nonatomic, readonly) CLAuthorizationStatus authorizationStatus;
@property (strong, nonatomic, readonly) NSNumber *totalSendFlaxLength;
@property (strong, nonatomic, readonly) NSNumber *totalRecvFlaxLength;

+ (instancetype)shareMapKit;
/**
 *  global setting
 */
- (void)czw_setUpMapManager;
/**
 *  授权
 */
- (void)czw_userAuthorization:(CLAuthorizationStatus)status;
/**
 *  加载地图
 */
- (void)czw_loadingMapView:(id<CZWMapViewDelegate>)delegate;
/**
 *  移除self.mapView,清除私有block和百度服务类引用(除BMKMapManager外);
 */
- (void)removeAllService;



#pragma mark - ====LocationService====
@property (strong, nonatomic, readonly) CLLocation *cacheUserLocation;
@property (strong, nonatomic, readonly) NSString *cacheCity;
@property (strong, nonatomic, readonly) NSString *cacheAddress;
/**
 *  开启定位
 */
- (void)czw_startLocatingDelegate:(id<CZWMapKitLocationDelegate>)delegate locatingMode:(CZWLocatingMode)mode;
/**
 *  当CZWLocatingMode是CZWLocatingAlways时要手动停止
 */
- (void)czw_stopLocating;

/**
 *  开启反地理编码
 */
- (void)czw_reverseGeoCode:(CLLocationCoordinate2D)coor;


#pragma mark - ====SearchPOI====
/**
 *  poi查询线路
 */
- (void)czw_searchPoi_BusLine:(NSString *)keyword succeedBlock:(void (^)(NSMutableArray <BMKPoiInfo *>*poiInfos ,CZWMapKit *mapKit))succeedBlock failureBlock:(void (^)(BMKSearchErrorCode errorCode))failureBlock;
/**
 *  poi查询线路详情
 */
- (void)czw_searchPoi_BusLineDetailWithUID:(NSString *)uid succeedBlock:(void (^)(BMKBusLineResult*aBusLineResult ,CZWMapView *mapView ,CZWMapKit *mapKit))succeedBlock failureBlock:(void (^)(BMKSearchErrorCode errorCode))failureBlock;
/**
 *  走路路线方案查询(点到点)
 */
- (void)czw_searchWalkingRoutePlanStarting:(CLLocationCoordinate2D)startLocationCoord endLocationCoord:(CLLocationCoordinate2D)endLocationCoord succeedBlock:(void (^)(BMKWalkingRouteLine *aRouteLine ,CZWMapView*mapView ,CZWMapKit *mapKit))succeedBlock failureBlock:(void (^)(BMKSearchErrorCode errorCode))failureBlock;


#pragma mark - ====OffLineMap====
@property (strong, nonatomic, readonly) BMKOfflineMap *baiduOfflineMap;//离线地图服务
//- (NSArray *)czw_startOffLineMapService:(NSArray* (^)(BMKOfflineMap *offlineMap))succeedBlock;
//- (void)czw_offlineMapHandler:(void (^)(BMKOfflineMap *offlineMap))handler;
@end


