//
//  CZWMapKit.h
//  CZWMapKit
//
//  Created by tianqu on 16/6/30.
//  Copyright © 2016年 Tianqu. All rights reserved.
/*  
 
 
 PS.流程->
 Global设置启动baiduMap ->
 创建CZWMapView视图     ->(不需要mapView显示的话可以跳过这一步)
 启动相应服务                   ->
 
 
 每次定位成功，反编码成功，就会刷新UserDefault数据持久缓存
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

//所有通知
#define ntkDidUpdateUserLocation @"ntkDidUpdateUserLocation"
#define ntkCZWCacheAddressDidChange @"CZWCacheAddressDidChange"
#define ntkCZWCacheCityDidChange @"CZWCacheCityDidChange"
#define ntkCZWCacheUserLocationDidChange @"CZWCacheUserLocationDidChange"
#define ntkCZWCacheCityPinyinDidChange @"CZWCacheCityPinyinDidChange"


#define kCZWMapKit  [CZWMapKit shareMapKit]
#define kAppMapKey @"Huguh0KNzNP1RCkHKfG5wKywywxaSTDF"  //启动秘钥
#define udkCachePosition @"cachePosition" //缓存经纬度
#define udkCacheLocation @"cacheLocation"  //原先userDefault中的地址缓存信息
#define udkCacheCity @"mcity" //城市缓存
#define udkCacheCityPinyin @"ecity"  //城市拼音缓存

@class CZWMapKit;

@protocol CZWMapViewDelegate <NSObject>

@optional

- (void)czw_mapViewDidFinishLoading:(CZWMapView *)mapView;
- (void)czw_mapView:(CZWMapView *)mapView regionDidChangeAnimated:(BOOL)animated;
- (void)czw_mapView:(CZWMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view;

@end

@interface CZWMapKit : NSObject <BMKMapViewDelegate>


#pragma mark - ====BaseSetting====
//@property (weak, nonatomic) id <CZWMapKitLocationDelegate> locationDelegate;
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
 *  加载地图(maker创建mapView handler添加进父视图)
 */
- (void)czw_setDelegate:(id<CZWMapViewDelegate>)delegate buildMapView:(CZWMapView * (^)(CZWMapKit *mapKit))maker handler:(void (^)(CZWMapView *mapView))handler;
- (void)czw_buildMapView:(CZWMapView * (^)(CZWMapKit *mapKit))maker handler:(void (^)(CZWMapView *mapView))handler;
/**
 *  移除self.mapView,清除私有block和百度服务类引用(除BMKMapManager外);
 */
- (void)removeAllService;

- (void)removeMapView;



#pragma mark - ====LocationService====
/**
 *  地址缓存最新的（只缓存用户所在）
 */

@property (strong, nonatomic, readonly) NSString *cacheUserPostion;//逗号隔开
@property (strong, nonatomic, readonly) NSString *cacheCity;
@property (strong, nonatomic, readonly) NSString *cacheCityPinyin;//百度返回的数据并没有拼音的数据，方案待定（用自己返回的数据）
@property (strong, nonatomic, readonly) NSString *cacheAddress;
/**
 *  开启持续定位，通过通知ntkDidUpdateUserLocation发送位置信息，需要手动停止定位
 */
- (void)czw_startLocating;

/**
 *  开启定位,可以持续定位,succeedBlock返回YSE就停止定位,,定位结果会缓存
 */
- (void)czw_startLocatingSucceedBlock:(BOOL (^)(CLLocationCoordinate2D coor ,CZWMapKit *mapKit))succeedBlock failureBlock:(void (^)(NSError *errorCode))failureBlock;
/**
 *  强制停止定位
 */
- (void)czw_stopLocating;

/**
 *  开启反地理编码
 */
- (void)czw_reverseGeoCode:(CLLocationCoordinate2D)coor succeedBlock:(void (^)(BMKReverseGeoCodeResult *geoResult ,CZWMapKit *mapKit))succeedBlock failureBlock:(void (^)(BMKSearchErrorCode errorCode))failureBlock;


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
@property (strong, nonatomic, readonly) BMKOfflineMap *baiduOfflineMap;
- (void)czw_startDownLoadCity:(int)cityId succeedBlock:(void (^)(BMKOLUpdateElement *))succeedBlock finishBlock:(void (^)(BOOL finish))finishBlock;
- (void)czw_startUpdateCity:(int)cityId succeedBlock:(void (^)(BMKOLUpdateElement *))succeedBlock finishBlock:(void (^)(BOOL finish))finishBlock;


#pragma mark - ====Calculate Method====
//百度地图提供
- (BOOL)confirmCoor:(CLLocationCoordinate2D)coor insideRoundCenter:(CLLocationCoordinate2D)center radius:(double)radius;

- (int)measureDistanceFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to;

- (CLLocationCoordinate2D)transformMapPointToCoor:(BMKMapPoint)mapPoint;

- (BMKMapPoint)transformCoorToMapPoint:(CLLocationCoordinate2D)coor;
@end


