//
//  ViewController.m
//  CZWMapKit
//
//  Created by tianqu on 16/6/30.
//  Copyright © 2016年 Tianqu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (strong, nonatomic) BMKMapView *mapView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [kCZWMapKit czw_userAuthorization:kCLAuthorizationStatusAuthorizedWhenInUse];
    [kCZWMapKit czw_startLocating:self showInView:self.view locatingMode:CZWLocatingOnce];
    
}

- (CZWMapView *)showMapViewWithMapKit:(CZWMapKit *)mapKit{
    CZWMapView *defaultMapView = [[CZWMapView alloc]initWithFrame:self.view.bounds CustomType:CZWMapViewCustomTypeOne delegate:self];
    return defaultMapView;
}

- (void)mapKit:(CZWMapKit *)mapKit didLocationPostion:(CLLocationCoordinate2D)coor{
    [mapKit czw_reverseGeoCode:coor];
}

- (void)mapKit:(CZWMapKit *)mapKit didLocationCity:(BMKAddressComponent *)addressDetail{
    NSLog(@"当前线程:%@,当前方法:%s",[NSThread currentThread], __FUNCTION__);
}
- (void)mapKit:(CZWMapKit *)mapKit didLocationAddress:(NSString *)address{
    NSLog(@"address = %@,当前线程:%@,当前方法:%s",address,[NSThread currentThread], __FUNCTION__);
}

- (void)mapViewDidFinishLoading:(BMKMapView *)mapView{
    //[mapView setCenterCoordinate:kCZWMapKit.cacheUserLocation.coordinate animated:YES];
}

@end
