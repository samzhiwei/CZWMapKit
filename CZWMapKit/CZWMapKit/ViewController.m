//
//  ViewController.m
//  CZWMapKit
//
//  Created by tianqu on 16/6/30.
//  Copyright © 2016年 Tianqu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (strong, nonatomic) CZWMapView *mapView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [kCZWMapKit czw_userAuthorization:kCLAuthorizationStatusAuthorizedWhenInUse];
    NSLog(@"self = %p",self);
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [kCZWMapKit czw_startLocating:self showInView:self.view locatingMode:CZWLocatingOnce];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

- (CZWMapView *)showMapViewWithMapKit:(CZWMapKit *)mapKit{
    self.mapView = [[CZWMapView alloc]initWithFrame:self.view.bounds CustomType:CZWMapViewCustomTypeOne delegate:nil];
    NSLog(@"self.mapView = %@",self.mapView);
    return self.mapView;
}

- (void)mapKit:(CZWMapKit *)mapKit didLocationPostion:(CLLocationCoordinate2D)coor{
    NSLog(@"%@",kCZWMapKit);
    __weak typeof(self) weakSelf = self;
    [mapKit czw_searchWalkingRoutePlanStarting:coor endLocationCoord:CLLocationCoordinate2DMake(23.140540, 113.346151) succeedBlock:^(BMKWalkingRouteLine *aRouteLine) {
        [weakSelf.mapView czw_addWalkingRouteLine:aRouteLine];
        [weakSelf.mapView czw_moveMapViewToCenter:coor animated:YES];
    } failureBlock:^(BMKSearchErrorCode errorCode) {
        
    }];
    [mapKit czw_reverseGeoCode:coor];
    [self.mapView setCenterCoordinate:kCZWMapKit.cacheUserLocation.coordinate animated:YES];
}

- (void)mapKit:(CZWMapKit *)mapKit didLocationCity:(BMKAddressComponent *)addressDetail{
    
}
- (void)mapKit:(CZWMapKit *)mapKit didLocationAddress:(NSString *)address{
    NSLog(@"address = %@,当前线程:%@,当前方法:%s",address,[NSThread currentThread], __FUNCTION__);
//    __weak typeof(self) weakSelf = self;
//    [mapKit czw_searchPoi_BusLine:@"10路" succeedBlock:^(NSMutableArray<BMKPoiInfo *> *poiInfos) {
//        
//        for (BMKPoiInfo *aPoi in poiInfos) {
//            [mapKit czw_searchPoi_BusLineDetailWithUID:aPoi.uid succeedBlock:^(BMKBusLineResult *busLineResult) {
//                if (busLineResult) {
//                    NSMutableArray <id<BMKAnnotation>> *array = [[NSMutableArray alloc]init];
//                    for (int i = 0; i < busLineResult.busStations.count; i ++) {
//                        BMKBusStation *aStation = busLineResult.busStations[i];
//                        CZWMapAnnotationType type = 0;
//                        if (i == 0) {
//                            type = CZWMapAnnotationTypeStarting;
//                        } else if (i == busLineResult.busStations.count - 1) {
//                            type = CZWMapAnnotationTypeTerminal;
//                        } else {
//                            type = CZWMapAnnotationTypeBus;
//                        }
//                        CZWMapAnnotation *an = [[CZWMapAnnotation alloc]initWithBusStation:aStation type:type];
//                        [array addObject:an];
//                    }
//                    BMKBusStation *firstStation = [busLineResult.busStations firstObject];
//                    [weakSelf.mapView czw_addStationAnnotation:array];
//                    [weakSelf.mapView czw_addBusLine:busLineResult.busSteps];
//                    [weakSelf.mapView czw_moveMapViewToCenter:firstStation.location animated:YES];
//                }
//
//            } failureBlock:^(BMKSearchErrorCode errorCode) {
//                
//            }];
//        }
//        
//    } failureBlock:^(BMKSearchErrorCode errorCode) {
//        
//    }];
}



- (void)mapViewDidFinishLoading:(BMKMapView *)mapView{
    [mapView setCenterCoordinate:kCZWMapKit.cacheUserLocation.coordinate animated:YES];
}

@end
