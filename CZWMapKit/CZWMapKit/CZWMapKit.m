//
//  CZWMapKit.m
//  CZWMapKit
//
//  Created by tianqu on 16/6/30.
//  Copyright © 2016年 Tianqu. All rights reserved.
//
#define LOCATION_AUTHORIZATION_DENIED   10001


#import "CZWMapKit.h"
#import <objc/runtime.h>
@interface CZWMapKit () <
BMKGeneralDelegate,
CLLocationManagerDelegate,
BMKLocationServiceDelegate,
BMKGeoCodeSearchDelegate,
BMKMapViewDelegate,
UIAlertViewDelegate
>
@property (strong, nonatomic) BMKMapManager *mapManager;//服务启动类

@property (strong, nonatomic) CLLocationManager *locationManager;//系统授权定位
@property (strong, nonatomic) BMKLocationService *baiduLocService;//定位服务
@property (strong, nonatomic) BMKGeoCodeSearch *baiduGeoCodeSearch;
@property (strong, nonatomic) CZWMapView *mapView;//显示地图

@property (assign, nonatomic) CZWLocatingMode locatingMode;//用户设定,不能修改
/**
 *  地址缓存最新的
 */


@end


@implementation CZWMapKit

#pragma mark - Lazy Loading
- (CLLocationManager *)locationManager{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc]init];
        _locationManager.delegate = self;
    }
    return _locationManager;
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

#pragma mark - Api
+ (instancetype)shareMapKit{
    static dispatch_once_t once;
    static CZWMapKit *sharedInstance;
    dispatch_once(&once, ^ {
        sharedInstance = [[CZWMapKit alloc] init];
    });
    return sharedInstance;
}

- (void)czw_startLocating:(id<CZWMapKitLocationDelegate>)delegate showInView:(UIView *)view locatingMode:(CZWLocatingMode)mode{
    self.locationDelegate = delegate;
    self.locatingMode = mode;
    
    [self czw_userAuthorization:kCLAuthorizationStatusAuthorizedWhenInUse];
    
    [self baseLocatingSetup];
    
    [self requestLocationDelegate:delegate showInView:view];
    
    [self.baiduLocService startUserLocationService];
}

- (void)czw_stopLocating{
    [self.baiduLocService stopUserLocationService];
}

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

#pragma mark - Global Setting
- (void)czw_setUpMapManager{
    _mapManager = [[BMKMapManager alloc]init];
    BOOL ret = [_mapManager start:kAppMapKey generalDelegate:self];
    if (!ret) {
        NSLog(@"BMKMapManager start failed!");
    }
}

#pragma mark - Private
/**
 *  查授权
 */
- (void)baseLocatingSetup{
    if ([self checkUserAuthorization]) {
        
    }
}

- (BOOL)checkUserAuthorization{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
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
        self.mapView = [delegate showMapViewWithMapKit:self];
        
    } else {
        self.mapView = [self defaultMapView];
    }
    
    [self userTrackingMode:BMKUserTrackingModeNone];
    [view addSubview:self.mapView];
}

- (void)userTrackingMode:(BMKUserTrackingMode)mode{
    _mapView.showsUserLocation = NO;//先关闭显示的定位图层
    _mapView.userTrackingMode = mode;//设置定位的状态
    _mapView.showsUserLocation = YES;//显示定位图层
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

#pragma mark - Private - Default
- (CZWMapView *)defaultMapView{
    CZWMapView *defaultMapView = [[CZWMapView alloc]initWithCustomType:CZWMapViewCustomTypeOne delegate:self];
    return defaultMapView;
}

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
        [self.locationDelegate mapKit:self didLocationPostion:userLocation.location.coordinate];
    }
    
    
    
    [self.mapView updateLocationData:userLocation];
    
    
    
    if ([self.locationDelegate respondsToSelector:@selector(didFinishLocationPostionWithMapKit:)]) {
        [self.locationDelegate didFinishLocationPostionWithMapKit:self];
    }
    
    if (self.locatingMode == CZWLocatingOnce) {
        [self czw_stopLocating];
    }
    
}
- (void)didFailToLocateUserWithError:(NSError *)error{
    NSLog(@"定位服务失败:domain:%@,code:%ld",error.domain,error.code);
}

#pragma mark - BMKGeoCodeSearchDelegate
- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    
}

- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
        //缓存
        [self setValue:[result.addressDetail.city copy] forKey:@"cacheCity"];
        [self setValue:[result.address copy] forKey:@"cacheAddress"];
        
        if ([self.locationDelegate respondsToSelector:@selector(mapKit:didLocationCity:)]) {
            [self.locationDelegate mapKit:self didLocationCity:result.addressDetail];
        }
        if ([self.locationDelegate respondsToSelector:@selector(mapKit:didLocationAddress:)]) {
            [self.locationDelegate mapKit:self didLocationAddress:result.address];
        }
        
        if ([self.locationDelegate respondsToSelector:@selector(didFinishGeoLocationPostionWithMapKit:)]) {
            [self.locationDelegate didFinishGeoLocationPostionWithMapKit:self];
        }
        
    } else {
        NSLog(@"error = %d 当前线程:%@,当前方法:%s", error,[NSThread currentThread], __FUNCTION__);
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

@end
