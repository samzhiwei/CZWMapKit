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


@interface CZWMapKit () <
BMKGeneralDelegate,
CLLocationManagerDelegate,
BMKLocationServiceDelegate,
BMKGeoCodeSearchDelegate,
BMKMapViewDelegate,
BMKPoiSearchDelegate,
BMKBusLineSearchDelegate,
BMKRouteSearchDelegate,
UIAlertViewDelegate
>
@property (strong, nonatomic) BMKMapManager *mapManager;//服务启动类

@property (strong, nonatomic) CLLocationManager *locationManager;//系统授权定位
@property (strong, nonatomic) BMKLocationService *baiduLocService;//定位服务
@property (strong, nonatomic) BMKGeoCodeSearch *baiduGeoCodeSearch;//地理编码
@property (strong, nonatomic) BMKPoiSearch *baiduPoiSearch;//poi搜索
@property (strong, nonatomic) BMKBusLineSearch *baiduBusLineSearch;//汽车路线详情搜索
@property (strong, nonatomic) BMKRouteSearch *baiduRouteSearch;//百度公交路径规划方案 搜索


/**
 *  临时存poi数据
 */
//@property (strong, nonatomic) NSMutableArray <BMKPoiInfo *>*busPoiArray;
//@property (strong, nonatomic) NSMutableArray <BMKPoiInfo *>*keywordPoiArray;

#pragma mark - 回调block
//成功
typedef void(^SucceedBusLineBlock)(NSMutableArray <BMKPoiInfo *>*);
@property (copy, nonatomic) SucceedBusLineBlock busLineBlock;
typedef void(^SucceedBusLineDetailBlock)(BMKBusLineResult *);
@property (copy, nonatomic) SucceedBusLineDetailBlock busLineDetailBlock;
typedef void(^SucceedWalkingRouteBlock)(BMKWalkingRouteLine *);
@property (copy, nonatomic) SucceedWalkingRouteBlock walkingRouteBlock;
//失败
typedef void(^FailureBlock)(BMKSearchErrorCode);
@property (copy, nonatomic) FailureBlock failureBlock;

@property (assign, nonatomic) CZWLocatingMode locatingMode;//用户设定,不能修改
/**
 *  地址缓存最新的
 */


@end


@implementation CZWMapKit

#pragma mark - Api
+ (instancetype)shareMapKit{
    static dispatch_once_t once;
    static CZWMapKit *sharedInstance;
    dispatch_once(&once, ^ {
        sharedInstance = [[CZWMapKit alloc] init];
    });
    return sharedInstance;
}
/**
 *  清除私有block缓存;
 */
- (void)clearPrivateBlockAndAllBaiduServiceClass{
    self.busLineBlock = nil;
    self.busLineDetailBlock = nil;
    self.walkingRouteBlock = nil;
    self.failureBlock = nil;
    
    self.locationManager = nil;
    self.locationManager.delegate = nil;
    
    self.baiduLocService = nil;
    self.baiduLocService.delegate = nil;
    
    self.baiduGeoCodeSearch = nil;
    self.baiduGeoCodeSearch.delegate = nil;
    
    self.baiduPoiSearch = nil;
    self.baiduPoiSearch.delegate = nil;
    
    self.baiduBusLineSearch = nil;
    self.baiduBusLineSearch.delegate = nil;
    
    self.baiduRouteSearch = nil;
    self.baiduRouteSearch.delegate = nil;
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
 *  开启定位
 */
- (void)czw_startLocating:(id<CZWMapKitLocationDelegate>)delegate showInView:(UIView *)view locatingMode:(CZWLocatingMode)mode{
    [self baseLocatingSetup];
    self.locationDelegate = delegate;
    self.locatingMode = mode;
    
    //[self czw_userAuthorization:kCLAuthorizationStatusAuthorizedWhenInUse];
    [self requestLocationDelegate:delegate showInView:view];
    
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
- (void)czw_reverseGeoCode:(CLLocationCoordinate2D)coor{
    NSLog(@"开始反地理编码:位置(%f, %f)",coor.latitude, coor.longitude);
    BMKReverseGeoCodeOption* reverseOp = [[BMKReverseGeoCodeOption alloc]init];
    reverseOp.reverseGeoPoint = coor;
    [self.baiduGeoCodeSearch reverseGeoCode:reverseOp];
}
/**
 *  poi查询线路
 */
- (void)czw_searchPoi_BusLine:(NSString *)keyword succeedBlock:(void (^)(NSMutableArray <BMKPoiInfo *>*poiInfos))succeedBlock failureBlock:(void (^)(BMKSearchErrorCode errorCode))failureBlock{
    [self baseLocatingSetup];
    
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
- (void)czw_searchPoi_BusLineDetailWithUID:(NSString *)uid succeedBlock:(void (^)(BMKBusLineResult*aBusLineResult))succeedBlock failureBlock:(void (^)(BMKSearchErrorCode errorCode))failureBlock{
    [self baseLocatingSetup];
    
    self.busLineDetailBlock = succeedBlock;
    self.failureBlock = failureBlock;
    
    BMKBusLineSearchOption *buslineSearchOption = [[BMKBusLineSearchOption alloc]init];
    buslineSearchOption.city= POI_SEARCH_CITY;
    buslineSearchOption.busLineUid= uid;
    BOOL flag = [self.baiduBusLineSearch busLineSearch:buslineSearchOption];
    if(flag)
    {
        NSLog(@"busline检索发送成功");
    }
    else
    {
        NSLog(@"busline检索发送失败");
    }
    
}

- (void)czw_searchWalkingRoutePlanStarting:(CLLocationCoordinate2D)startLocationCoord endLocationCoord:(CLLocationCoordinate2D)endLocationCoord succeedBlock:(void (^)(BMKWalkingRouteLine *aRouteLine))succeedBlock failureBlock:(void (^)(BMKSearchErrorCode errorCode))failureBlock{
    
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
        NSLog(@"transfer检索发送成功");
    }
    else
    {
        NSLog(@"transfer检索发送失败");
    }
}

#pragma mark - Api Global Setting
- (void)czw_setUpMapManager{
    
    BOOL ret = [self.mapManager start:kAppMapKey generalDelegate:self];
    
    if (!ret) {
        NSLog(@"BMKMapManager start failed!");
    } 
}

#pragma mark - Private
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

#pragma mark - Private - Location Service
/**
 *  设置mapView
 */
- (void)requestLocationDelegate:(id <CZWMapKitLocationDelegate>)delegate showInView:(UIView *)view{
    if ([delegate respondsToSelector:@selector(showMapViewWithMapKit:)]) {
        __weak typeof(self) weakSelf = self;
        [self setValue:[delegate showMapViewWithMapKit:weakSelf] forKey:@"mapView"];
        
    } else {
        //[self setValue:[self defaultMapView] forKey:@"mapView"];
    }
    
    [self userTrackingMode:BMKUserTrackingModeNone];
    [view addSubview:self.mapView];
}

- (void)userTrackingMode:(BMKUserTrackingMode)mode{
    _mapView.showsUserLocation = NO;//先关闭显示的定位图层
    _mapView.userTrackingMode = mode;//设置定位的状态
    _mapView.showsUserLocation = YES;//显示定位图层
}

#pragma mark - Private - Default
//- (CZWMapView *)defaultMapView{
//    CZWMapView *defaultMapView = [[CZWMapView alloc]initWithCustomType:CZWMapViewCustomTypeOne delegate:self];
//    return defaultMapView;
//}




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
    NSLog(@"定位成功,我的位置:(%f, %f)",userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
    [self setValue:[userLocation.location copy] forKey:@"cacheUserLocation"];
    
    if ([self.locationDelegate respondsToSelector:@selector(mapKit:didLocationPostion:)]) {
        __weak typeof(self) weakSelf = self;
        [self.locationDelegate mapKit:weakSelf didLocationPostion:userLocation.location.coordinate];
    }
    
    [self.mapView updateLocationData:userLocation];
    
    if ([self.locationDelegate respondsToSelector:@selector(didFinishLocationPostionWithMapKit:)]) {
        __weak typeof(self) weakSelf = self;
        [self.locationDelegate didFinishLocationPostionWithMapKit:weakSelf];
    }
    
    if (self.locatingMode == CZWLocatingOnce) {
        [self czw_stopLocating];
    }
    
}
- (void)didFailToLocateUserWithError:(NSError *)error{
    NSLog(@"定位服务失败:domain:%@,code:%ld",error.domain,(long)error.code);
}

#pragma mark - BMKGeoCodeSearchDelegate
- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    
}

- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    
    if (error == BMK_SEARCH_NO_ERROR) {
        //缓存
        [self setValue:[result.addressDetail.city copy] forKey:@"cacheCity"];
        [self setValue:[result.address copy] forKey:@"cacheAddress"];
        __weak typeof(self) weakSelf = self;
        if ([self.locationDelegate respondsToSelector:@selector(mapKit:didLocationCity:)]) {
            [self.locationDelegate mapKit:weakSelf didLocationCity:result.addressDetail];
        }
        if ([self.locationDelegate respondsToSelector:@selector(mapKit:didLocationAddress:)]) {
            [self.locationDelegate mapKit:weakSelf didLocationAddress:result.address];
        }
        
        if ([self.locationDelegate respondsToSelector:@selector(didFinishGeoLocationPostionWithMapKit:)]) {
            [self.locationDelegate didFinishGeoLocationPostionWithMapKit:weakSelf];
        }
        
    } else {
        NSLog(@"error = %d 当前线程:%@,当前方法:%s", error,[NSThread currentThread], __FUNCTION__);
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
        //发送
        if (self.busLineBlock && busPoiArray) {
            self.busLineBlock(busPoiArray);
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
            self.busLineDetailBlock(busLineResult);
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
                self.walkingRouteBlock(aRouteLine);
            }
        }
    } else {
        if (self.failureBlock) {
            self.failureBlock(error);
        }
    }
}

- (void)onGetDrivingRouteResult:(BMKRouteSearch *)searcher result:(BMKDrivingRouteResult *)result errorCode:(BMKSearchErrorCode)error
{
    int price = 0;
    if (error == BMK_SEARCH_NO_ERROR) {
        BMKDrivingRouteLine * plan = (BMKDrivingRouteLine*)result.routes[0];
        float distance = plan.distance /1000.0f;//换算成公里
        //计算车费: (总距离-3公里）*3（每公里收费）+10元（起步费）
        distance = distance<3?3:distance;
        price = (distance-3)*3 + 10;
    }
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

//- (NSMutableArray *)busPoiArray{
//    if (!_busPoiArray) {
//        _busPoiArray = [[NSMutableArray alloc]init];
//    }
//    return _busPoiArray;
//}
//
//- (NSMutableArray *)keywordPoiArray{
//    if (!_keywordPoiArray) {
//        _keywordPoiArray = [[NSMutableArray alloc]init];
//    }
//    return _keywordPoiArray;
//}

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

@end
