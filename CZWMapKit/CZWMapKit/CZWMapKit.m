//
//  CZWMapKit.m
//  CZWMapKit
//
//  Created by tianqu on 16/6/30.
//  Copyright © 2016年 Tianqu. All rights reserved.
//
#define LOCATION_AUTHORIZATION_DENIED   10001
#define POI_SEARCH_CITY  @"广州市"
#define POI_SEARCH_PAGE_INDEX 0
#define POI_SEARCH_PAGE_CAPACITY 10

#import "CZWMapKit.h"
#import <objc/runtime.h>
#import "UIImage+Rotate.h"

@interface CZWMapKit () <
BMKGeneralDelegate,
CLLocationManagerDelegate,
BMKLocationServiceDelegate,
BMKGeoCodeSearchDelegate,
BMKMapViewDelegate,
BMKPoiSearchDelegate,
BMKBusLineSearchDelegate,
BMKRouteSearchDelegate,
BMKOfflineMapDelegate,
UIAlertViewDelegate
>
@property (strong, nonatomic) BMKMapManager *mapManager;//服务启动类

@property (strong, nonatomic) CLLocationManager *locationManager;//系统授权定位
@property (strong, nonatomic) BMKLocationService *baiduLocService;//定位服务
@property (strong, nonatomic) BMKGeoCodeSearch *baiduGeoCodeSearch;//地理编码
@property (strong, nonatomic) BMKPoiSearch *baiduPoiSearch;//poi搜索
@property (strong, nonatomic) BMKBusLineSearch *baiduBusLineSearch;//汽车路线详情搜索
@property (strong, nonatomic) BMKRouteSearch *baiduRouteSearch;//百度公交路径规划方案 搜索

@property (assign, nonatomic) BOOL stopLocating;//默认NO,是否持续定位锁

#pragma mark - 回调block
//成功
typedef BOOL(^SucceedLocationBlock)(CLLocationCoordinate2D ,CZWMapKit *);
/**
 *  定位回调block,返回YES就停止定位,
 */
@property (copy, nonatomic) SucceedLocationBlock locationBlock;
typedef void(^SucceedReverseGeoCodeBlock)(BMKReverseGeoCodeResult * ,CZWMapKit *);
/**
 *  反地理编码回调block
 */
@property (copy, nonatomic) SucceedReverseGeoCodeBlock reverseGeoCodeBlock;

typedef void(^SucceedBusLineBlock)(NSMutableArray <BMKPoiInfo *>* ,CZWMapKit *);
/**
 *  BusLine信息回调block
 */
@property (copy, nonatomic) SucceedBusLineBlock busLineBlock;
typedef void(^SucceedBusLineDetailBlock)(BMKBusLineResult * ,CZWMapView *,CZWMapKit *);
/**
 *  BusLine详情信息回调Block
 */
@property (copy, nonatomic) SucceedBusLineDetailBlock busLineDetailBlock;
typedef void(^SucceedWalkingRouteBlock)(BMKWalkingRouteLine * ,CZWMapView * ,CZWMapKit *);
/**
 *  走路线路详情信息回调Block
 */
@property (copy, nonatomic) SucceedWalkingRouteBlock walkingRouteBlock;

//失败
typedef void(^FailureBlock)(BMKSearchErrorCode);
/**
 *  回调失败共用Block
 */
@property (copy, nonatomic) FailureBlock failureBlock;

typedef void(^FailureLocationBlock)(NSError *);
/**
 *  定位失败用回调Block
 */
@property (copy, nonatomic) FailureLocationBlock failureLocationBlock;





@end


@implementation CZWMapKit
@synthesize baiduOfflineMap = _baiduOfflineMap;
#pragma mark - ====BaseSetting====
#pragma mark - Api - BaseSetting
- (instancetype)init{
    self = [super init];
    if (self) {
        self.stopLocating = NO;
    }
    return self;
}

+ (instancetype)shareMapKit{
    static dispatch_once_t once;
    static CZWMapKit *sharedInstance;
    dispatch_once(&once, ^ {
        sharedInstance = [[CZWMapKit alloc] init];
        //NSLog(@"shared = %p",sharedInstance);
    });
    return sharedInstance;
}
/**
 *  清除私有block缓存;
 */
- (void)removeAllService{
    [self.mapView removeFromSuperview];
    [self setValue:nil forKey:@"mapView"];
    
    _locationBlock = nil;
    _reverseGeoCodeBlock = nil;
    _busLineBlock = nil;
    _busLineDetailBlock = nil;
    _walkingRouteBlock = nil;
    _failureBlock = nil;
    _failureLocationBlock = nil;
    
    _locationManager.delegate = nil;
    _locationManager = nil;
    
    _baiduLocService.delegate = nil;
    _baiduLocService = nil;
    
    _baiduGeoCodeSearch.delegate = nil;
    _baiduGeoCodeSearch = nil;
    
    _baiduPoiSearch.delegate = nil;
    _baiduPoiSearch = nil;
    
    _baiduBusLineSearch.delegate = nil;
    _baiduBusLineSearch = nil;
    
    _baiduRouteSearch.delegate = nil;
    _baiduRouteSearch = nil;
    
}
/**
 *  global setting
 */
- (void)czw_setUpMapManager{
    
    BOOL ret = [self.mapManager start:kAppMapKey generalDelegate:self];
    
    if (!ret) {
        NSLog(@"BMKMapManager start failed!");
    }
}
/**
 *  授权
 */
- (void)czw_userAuthorization:(CLAuthorizationStatus)status{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8) {
        switch (status) {
            case kCLAuthorizationStatusAuthorizedAlways :{
                [self.locationManager requestAlwaysAuthorization];
                break;
            }
            case kCLAuthorizationStatusAuthorizedWhenInUse :{
                [self.locationManager requestWhenInUseAuthorization];
                break;
            }
            default:{
                NSLog(@"授权参数有误：只能是kCLAuthorizationStatusAuthorizedAlways,kCLAuthorizationStatusAuthorizedWhenInUse");
                break;
            }
        }
    }
}
/**
 *  加载地图
 */
- (void)czw_setDelegate:(id<CZWMapViewDelegate>)delegate buildMapView:(CZWMapView * (^)(CZWMapKit *mapKit))maker handler:(void (^)(CZWMapView *mapView))handler{
    _mapViewDelegate = delegate;
    [self czw_buildMapView:^CZWMapView *(CZWMapKit *mapKit) {
        return maker(mapKit);
    } handler:^(CZWMapView *mapView) {
        handler(mapView);
    }];
}

- (void)czw_buildMapView:(CZWMapView * (^)(CZWMapKit *mapKit))maker handler:(void (^)(CZWMapView *mapView))handler{
    __weak typeof(self) weakSelf = self;
    CZWMapView *mapView = maker(weakSelf);
    [self setValue:mapView forKey:@"mapView"];
    [self userTrackingMode:BMKUserTrackingModeNone];
    handler(mapView);
    mapView = nil;
}

#pragma mark - Private - BaseSetting
/**
 *  查授权
 */
- (BOOL)baseLocatingSetup{
    if ([self checkUserAuthorization]) {
        return YES;
    } else{
        return NO;
    }
}

- (BOOL)checkUserAuthorization{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    _authorizationStatus = status;
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"请允许定位" message:@"以便我们提供更好的服务" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"去打开", nil];
        alert.tag = LOCATION_AUTHORIZATION_DENIED;
        [alert show];
        return NO;
    } else {
        return YES;
    }
}


#pragma mark - ====LocationService====
#pragma mark - Api - Location Service
/**
 *  开启定位
 */
- (void)czw_startLocatingSucceedBlock:(BOOL (^)(CLLocationCoordinate2D coor ,CZWMapKit *mapKit))succeedBlock failureBlock:(void (^)(NSError *errorCode))failureBlock{
    [self baseLocatingSetup];
    
    self.locationBlock = succeedBlock;
    self.failureLocationBlock = failureBlock;
    
    [self.baiduLocService startUserLocationService];
    
}
/**
 *  停止定位
 */
- (void)czw_stopLocating{
    [self.baiduLocService stopUserLocationService];
}
/**
 *  开启反地理编码
 */

- (void)czw_reverseGeoCode:(CLLocationCoordinate2D)coor succeedBlock:(void (^)(BMKReverseGeoCodeResult *geoResult ,CZWMapKit *mapKit))succeedBlock failureBlock:(void (^)(BMKSearchErrorCode errorCode))failureBlock{
    self.reverseGeoCodeBlock = succeedBlock;
    self.failureBlock = failureBlock;
    
    //NSLog(@"开始反地理编码:位置(%f, %f)",coor.latitude, coor.longitude);
    BMKReverseGeoCodeOption* reverseOp = [[BMKReverseGeoCodeOption alloc]init];
    reverseOp.reverseGeoPoint = coor;
    [self.baiduGeoCodeSearch reverseGeoCode:reverseOp];
}

#pragma mark - Private - Location Service

- (void)userTrackingMode:(BMKUserTrackingMode)mode{
    _mapView.showsUserLocation = NO;//先关闭显示的定位图层
    _mapView.userTrackingMode = mode;//设置定位的状态
    _mapView.showsUserLocation = YES;//显示定位图层
}


#pragma mark - ====SearchPOI====
#pragma mark - Api - SearchPOI
/**
 *  poi查询线路
 */
- (void)czw_searchPoi_BusLine:(NSString *)keyword succeedBlock:(void (^)(NSMutableArray <BMKPoiInfo *>*poiInfos ,CZWMapKit *mapKit))succeedBlock failureBlock:(void (^)(BMKSearchErrorCode errorCode))failureBlock{
    
    self.busLineBlock = succeedBlock;
    self.failureBlock = failureBlock;
    
    BMKCitySearchOption *citySearchOption = [[BMKCitySearchOption alloc]init];
    citySearchOption.pageIndex = POI_SEARCH_PAGE_INDEX;
    citySearchOption.pageCapacity = POI_SEARCH_PAGE_CAPACITY;
    citySearchOption.city= POI_SEARCH_CITY;
    citySearchOption.keyword = keyword;
    BOOL flag = [self.baiduPoiSearch poiSearchInCity:citySearchOption];
    if(flag)
    {
        NSLog(@"城市内poi检索发送成功");
    }
    else
    {
        NSLog(@"城市内poi检索发送失败");
    }
}
/**
 *  poi查询线路详情
 */
- (void)czw_searchPoi_BusLineDetailWithUID:(NSString *)uid succeedBlock:(void (^)(BMKBusLineResult*aBusLineResult ,CZWMapView *mapView ,CZWMapKit *mapKit))succeedBlock failureBlock:(void (^)(BMKSearchErrorCode errorCode))failureBlock{
    
    self.busLineDetailBlock = succeedBlock;
    self.failureBlock = failureBlock;
    
    BMKBusLineSearchOption *buslineSearchOption = [[BMKBusLineSearchOption alloc]init];
    buslineSearchOption.city= POI_SEARCH_CITY;
    buslineSearchOption.busLineUid= uid;
    BOOL flag = [self.baiduBusLineSearch busLineSearch:buslineSearchOption];
    if(flag)
    {
        NSLog(@"busline详情检索发送成功");
    }
    else
    {
        NSLog(@"busline详情检索发送失败");
    }
    
}

- (void)czw_searchWalkingRoutePlanStarting:(CLLocationCoordinate2D)startLocationCoord endLocationCoord:(CLLocationCoordinate2D)endLocationCoord succeedBlock:(void (^)(BMKWalkingRouteLine *aRouteLine ,CZWMapView*mapView ,CZWMapKit *mapKit))succeedBlock failureBlock:(void (^)(BMKSearchErrorCode errorCode))failureBlock{
    
    self.walkingRouteBlock = succeedBlock;
    self.failureBlock = failureBlock;
    
    BMKPlanNode *start = [[BMKPlanNode alloc] init];
    start.pt = startLocationCoord;
    start.cityName = POI_SEARCH_CITY;
    BMKPlanNode *end = [[BMKPlanNode alloc] init];
    end.pt = endLocationCoord;
    end.cityName = POI_SEARCH_CITY;
    BMKWalkingRoutePlanOption *walking = [[BMKWalkingRoutePlanOption alloc] init];
    walking.from = start;
    walking.to = end;
    BOOL flag = [self.baiduRouteSearch walkingSearch:walking];
    if (flag) {
        NSLog(@"walkingRoute检索发送成功");
    }
    else
    {
        NSLog(@"walkingRoute检索发送失败");
    }
}

#pragma mark - ====OffLineMap====
- (NSArray *)czw_startOffLineMapService:(NSArray* (^)(BMKOfflineMap *offlineMap))succeedBlock{
    BMKOfflineMap *offlineMap = self.baiduOfflineMap;
    return succeedBlock(offlineMap);
}

- (void)czw_offlineMapHandler:(void (^)(BMKOfflineMap *offlineMap))handler{
    BMKOfflineMap *offlineMap = self.baiduOfflineMap;
    return handler(offlineMap);
}


#pragma mark - +++++++++++++++++++++++++++++++DELEGATE+++++++++++++++++++++++++++++++
#pragma mark - ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#pragma mark - BMKLocationServiceDelegate
- (void)willStartLocatingUser{
    NSLog(@"定位服务开始");
}

- (void)didStopLocatingUser{
    NSLog(@"定位服务停止");
}

- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation{
    [self.mapView updateLocationData:userLocation];
}

- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{
    //NSLog(@"定位成功,我的位置:(%f, %f)",userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
    //缓存
    [self setValue:[userLocation.location copy] forKey:@"cacheUserLocation"];
    //call block
    __weak typeof(self) weakSelf = self;
    if (self.locationBlock) {
        self.stopLocating = self.locationBlock(userLocation.location.coordinate ,weakSelf);
    }
    
    
    [self.mapView updateLocationData:userLocation];
    if (self.stopLocating) {
        [self czw_stopLocating];
    }
    
}
- (void)didFailToLocateUserWithError:(NSError *)error{
    if (self.failureLocationBlock) {
        self.failureLocationBlock(error);
    }
    NSLog(@"定位服务失败:domain:%@,code:%ld",error.domain,(long)error.code);
}

#pragma mark - BMKGeoCodeSearchDelegate
- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    
}

- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    
    if (error == BMK_SEARCH_NO_ERROR) {
        NSLog(@"反地理编码成功地址：%@",result.address);
        //缓存
        [self setValue:[result.addressDetail.city copy] forKey:@"cacheCity"];
        [self setValue:[result.address copy] forKey:@"cacheAddress"];
        //call block
        __weak typeof(self) weakSelf = self;
        if (self.reverseGeoCodeBlock) {
            self.reverseGeoCodeBlock(result ,weakSelf);
        }
        
    } else {
        NSLog(@"error = %d 当前线程:%@,当前方法:%s", error,[NSThread currentThread], __FUNCTION__);
        if (self.failureBlock) {
            self.failureBlock(error);
        }
    }
    
}

#pragma mark - BMKPoiSearchDelegate
- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPoiResult*)poiResult errorCode:(BMKSearchErrorCode)errorCode{
    
    if (errorCode == BMK_SEARCH_NO_ERROR) {
        NSMutableArray *busPoiArray = nil;
        NSMutableArray *keywordPoiArray = nil;
        for (BMKPoiInfo *aPoi in poiResult.poiInfoList) {//遍历筛选
            if (aPoi.epoitype == 2 || aPoi.epoitype == 4) {///POI类型，0:普通点 1:公交站 2:公交线路 3:地铁站 4:地铁线路
                if (!busPoiArray) {
                    busPoiArray = [[NSMutableArray alloc]init];
                    NSLog(@"bus = %p",busPoiArray);
                }
                [busPoiArray addObject:aPoi];
            } else {
                if (!keywordPoiArray) {
                    keywordPoiArray = [[NSMutableArray alloc]init];
                }
                [keywordPoiArray addObject:aPoi];
            }
        }
        //call block
        if (self.busLineBlock && busPoiArray) {
            __weak typeof(self) weakSelf = self;
            self.busLineBlock(busPoiArray,weakSelf);
        }
#warning todo:非公交线路poi处理
        
    } else {
        if (self.failureBlock) {
            self.failureBlock(errorCode);
        }
    }
}

#pragma mark - BMKBusLineSearchDelegate
- (void)onGetBusDetailResult:(BMKBusLineSearch*)searcher result:(BMKBusLineResult*)busLineResult errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
        if (self.busLineDetailBlock) {
            __weak typeof(self) weakSelf = self;
            self.busLineDetailBlock(busLineResult, weakSelf.mapView, weakSelf);
        }
    } else {
        if (self.failureBlock) {
            self.failureBlock(error);
        }
    }
}

#pragma mark - BMKRouteSearchDelegate
- (void)onGetWalkingRouteResult:(BMKRouteSearch*)searcher result:(BMKWalkingRouteResult*)result errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
        for (BMKWalkingRouteLine *aRouteLine in result.routes) {
            if (self.walkingRouteBlock) {
                __weak typeof(self) weakSelf = self;
                self.walkingRouteBlock(aRouteLine ,weakSelf.mapView ,weakSelf);
            }
        }
    } else {
        NSLog(@"路线返回码：%d",error);
        if (self.failureBlock) {
            self.failureBlock(error);
        }
    }
}

- (void)onGetDrivingRouteResult:(BMKRouteSearch *)searcher result:(BMKDrivingRouteResult *)result errorCode:(BMKSearchErrorCode)error
{
//    int price = 0;
//    if (error == BMK_SEARCH_NO_ERROR) {
//        BMKDrivingRouteLine * plan = (BMKDrivingRouteLine*)result.routes[0];
//        float distance = plan.distance /1000.0f;//换算成公里
//        //计算车费: (总距离-3公里）*3（每公里收费）+10元（起步费）
//        distance = distance<3?3:distance;
//        price = (distance-3)*3 + 10;
//    }
}

#pragma mark -  BMKOfflineMapDelegate

- (void)onGetOfflineMapState:(int)type withState:(int)state{
    NSLog(@"离线地图事件接收：type:%d,state:%d",type,state);
    
}

#pragma mark - BMKMapViewDelegate
- (void)mapViewDidFinishLoading:(CZWMapView *)mapView{
    //[mapView setCenterCoordinate:kCZWMapKit.cacheUserLocation.coordinate animated:YES];
    //NSLog(@"完成load");
    
    if ([_mapViewDelegate respondsToSelector:@selector(czw_mapViewDidFinishLoading:)]) {
        [_mapViewDelegate czw_mapViewDidFinishLoading:mapView];
    }
}

- (void)mapView:(CZWMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view{
    [mapView setCenterCoordinate:view.annotation.coordinate animated:YES];
    
    if ([_mapViewDelegate respondsToSelector:@selector(czw_mapView:didSelectAnnotationView:)]) {
        [_mapViewDelegate czw_mapView:mapView didSelectAnnotationView:view];
    }
}

- (void)mapView:(CZWMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    //NSLog(@"地图移动了");
    if ([_mapViewDelegate respondsToSelector:@selector(czw_mapView:regionDidChangeAnimated:)]) {
        [_mapViewDelegate czw_mapView:mapView regionDidChangeAnimated:animated];
    }
}

#pragma mark - 集中处理显示的Annotation
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation{
    BMKAnnotationView *av = nil;
    if ([annotation isKindOfClass:[CZWMapAnnotation class]]) {
        CZWMapAnnotation *czwAnnotation = (CZWMapAnnotation *)annotation;
        av = [mapView dequeueReusableAnnotationViewWithIdentifier:NSStringFromClass([CZWMapAnnotation class])];
        if (!av) {
            av = [[BMKAnnotationView alloc]initWithAnnotation:czwAnnotation reuseIdentifier:NSStringFromClass([CZWMapAnnotation class])];
        }
        
        switch (czwAnnotation.type) {
            case CZWMapAnnotationTypeStarting :{
                av.image = [UIImage imageNamed:@"icon_line_start"];
                av.centerOffset = CGPointMake(0, -10);
                break;
            }
            case CZWMapAnnotationTypeTerminal :{
                av.image = [UIImage imageNamed:@"icon_line_end"];
                av.centerOffset = CGPointMake(0, -10);
                break;
            }
            case CZWMapAnnotationTypeBus :{
                av.image = [UIImage  imageNamed:@"ic_position"];
                av.centerOffset = CGPointMake(0, -10);
                UISwitch *sw = [[UISwitch alloc]init];
                //view.backgroundColor = [UIColor redColor];
                av.paopaoView.frame = CGRectMake(0, 0, av.paopaoView.frame.size.width + 30, av.paopaoView.frame.size.height);
                av.paopaoView.backgroundColor = [UIColor grayColor];
                av.rightCalloutAccessoryView = [[BMKActionPaopaoView alloc]initWithCustomView:sw];
                av.leftCalloutAccessoryView.backgroundColor = [UIColor yellowColor];
                break;
            }
            case CZWMapAnnotationTypeMetro :{
                break;
            }
            case CZWMapAnnotationTypeDrivingCar :{
                break;
            }
            case CZWMapAnnotationTypeWalking :{
                UIImage *image = [UIImage imageNamed:@"icon_direction"];
                av.image = [image imageRotatedByDegrees:czwAnnotation.degree];
                av.centerOffset = CGPointMake(0, 0);
                break;
            }
            case CZWMapAnnotationTypeUnknow:{
                break;
            }
        }
    }
    return av;
}

#pragma mark - 集中处理显示的覆盖物（线路）
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.fillColor = [[UIColor colorWithRed:24/255.0 green:150/255.0 blue:214/255.0 alpha:1] colorWithAlphaComponent:1];
        polylineView.strokeColor = [[UIColor colorWithRed:24/255.0 green:150/255.0 blue:214/255.0 alpha:1] colorWithAlphaComponent:1];
        polylineView.lineWidth = 3.50;
        return polylineView;
    }
    return nil;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == LOCATION_AUTHORIZATION_DENIED) {
        if (buttonIndex == 1) {
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"prefs:root=privacy"]]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=privacy"]];
                NSLog(@"打开prefs:root=privacy成功");
            } else {
                NSLog(@"打开prefs:root=privacy失败");
            }
        }
    }
}

#pragma mark - BMKGeneralDelegate
/**
 *返回网络错误
 *@param iError 错误号
 */
- (void)onGetNetworkState:(int)iError{
    if (iError == BMK_SEARCH_NO_ERROR) {
        NSLog(@"BaiduMap网路正常");
    } else {
        NSLog(@"BaiduMap网络错误号%d，当前方法:%s",iError, __FUNCTION__);
    }
    
}

/**
 *返回授权验证错误
 *@param iError 错误号 : 为0时验证通过，具体参加BMKPermissionCheckResultCode
 */
- (void)onGetPermissionState:(int)iError{
    if (iError == BMK_SEARCH_NO_ERROR) {
        NSLog(@"BaiduMap授权验证正常");
        
    } else {
        NSLog(@"BaiduMap授权验证错误号%d，当前方法:%s",iError, __FUNCTION__);
    }
    
}


#pragma mark - CLLocationManagerDelegate
/**
 *  用户签名状态改变
 */
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    [self checkUserAuthorization];
}

#pragma mark - Lazy Loading
- (CLLocationManager *)locationManager{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc]init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (BMKMapManager *)mapManager{
    if (!_mapManager) {
        _mapManager = [[BMKMapManager alloc]init];
    }
    return _mapManager;
}

- (BMKLocationService *)baiduLocService{
    if (!_baiduLocService) {
        _baiduLocService = [[BMKLocationService alloc]init];
        _baiduLocService.delegate = self;
    }
    return _baiduLocService;
}

- (BMKGeoCodeSearch *)baiduGeoCodeSearch{
    if (!_baiduGeoCodeSearch) {
        _baiduGeoCodeSearch = [[BMKGeoCodeSearch alloc]init];
        _baiduGeoCodeSearch.delegate = self;
    }
    return _baiduGeoCodeSearch;
}

- (BMKPoiSearch *)baiduPoiSearch{
    if (!_baiduPoiSearch) {
        _baiduPoiSearch = [[BMKPoiSearch alloc]init];
        _baiduPoiSearch.delegate = self;
    }
    return _baiduPoiSearch;
}

- (BMKBusLineSearch *)baiduBusLineSearch{
    if (!_baiduBusLineSearch) {
        _baiduBusLineSearch = [[BMKBusLineSearch alloc]init];
        _baiduBusLineSearch.delegate = self;
    }
    return _baiduBusLineSearch;
}

- (BMKRouteSearch *)baiduRouteSearch{
    if (!_baiduRouteSearch) {
        _baiduRouteSearch = [[BMKRouteSearch alloc]init];
        _baiduRouteSearch.delegate = self;
    }
    return _baiduRouteSearch;
}

- (BMKOfflineMap *)baiduOfflineMap{
    if (!_baiduOfflineMap) {
        _baiduOfflineMap = [[BMKOfflineMap alloc]init];
        _baiduOfflineMap.delegate = self;
    }
    return _baiduOfflineMap;
}

#pragma mark - Set/Get
- (void)setCacheAddress:(NSString *)cacheAddress{
    _cacheAddress = cacheAddress;
    [[NSNotificationCenter defaultCenter] postNotificationName:kCZWCacheAddressDidChange object:nil userInfo:@{kCZWCacheAddressDidChange : cacheAddress}];
}

- (void)setCacheCity:(NSString *)cacheCity{
    _cacheCity = cacheCity;
    [[NSNotificationCenter defaultCenter] postNotificationName:kCZWCacheCityDidChange object:nil userInfo:@{kCZWCacheCityDidChange : cacheCity}];
}

- (void)setCacheUserLocation:(CLLocation *)cacheUserLocation{
    _cacheUserLocation = cacheUserLocation;
    [[NSNotificationCenter defaultCenter] postNotificationName:kCZWCacheUserLocationDidChange object:nil userInfo:@{kCZWCacheUserLocationDidChange : cacheUserLocation}];
}

- (NSNumber *)totalSendFlaxLength{
    return [NSNumber numberWithInt:[self.mapManager getTotalSendFlaxLength]];
}

- (NSNumber *)totalRecvFlaxLength{
    return [NSNumber numberWithInt:[self.mapManager getTotalRecvFlaxLength]];
}

#pragma mark - ====Calculate Method====
//百度地图提供
- (BOOL)confirmCoor:(CLLocationCoordinate2D)coor insideRoundCenter:(CLLocationCoordinate2D)center radius:(double)radius{
    return BMKCircleContainsCoordinate(coor, center, radius);
}

- (int)measureDistanceFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to{
    return BMKMetersBetweenMapPoints(BMKMapPointForCoordinate(from), BMKMapPointForCoordinate(to));
}

- (CLLocationCoordinate2D)transformMapPointToCoor:(BMKMapPoint)mapPoint{
    return BMKCoordinateForMapPoint(mapPoint);
}

- (BMKMapPoint)transformCoorToMapPoint:(CLLocationCoordinate2D)coor{
    return BMKMapPointForCoordinate(coor);
}

@end
