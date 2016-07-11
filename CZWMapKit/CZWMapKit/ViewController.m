//
//  ViewController.m
//  CZWMapKit
//
//  Created by tianqu on 16/6/30.
//  Copyright © 2016年 Tianqu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () //<BMKOfflineMapDelegate>
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (strong, nonatomic) NSArray *hotCity;
@property (strong, nonatomic) NSArray *offlineCity;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [kCZWMapKit czw_userAuthorization:kCLAuthorizationStatusAuthorizedWhenInUse];
    __weak typeof(self) weakSelf = self;
    [kCZWMapKit czw_setDelegate:self buildMapView:^CZWMapView *(CZWMapKit *mapKit) {
        return [[CZWMapView alloc]initWithFrame:weakSelf.view.bounds CustomType:CZWMapViewCustomTypeOne delegate:mapKit];
    } handler:^(CZWMapView *mapView) {
        [weakSelf.view addSubview:mapView];
    }];
}
- (IBAction)clickBtn:(UIButton *)sender {
//    [kCZWMapKit czw_searchWalkingRoutePlanStarting:kCZWMapKit.cacheUserLocation.coordinate endLocationCoord:CLLocationCoordinate2DMake(23.140540, 113.346151) succeedBlock:^(BMKWalkingRouteLine *aRouteLine ,CZWMapView *mapView ,CZWMapKit *mapKit) {
//        
//        [mapView czw_addWalkingRouteLine:aRouteLine];
//        [mapView czw_moveMapViewToCenter:kCZWMapKit.cacheUserLocation.coordinate animated:YES];
//        
//    } failureBlock:^(BMKSearchErrorCode errorCode) {
//
//    }];
    
    
//    [kCZWMapKit czw_startLocatingWithMode:CZWLocatingOnce succeedBlock:^(CLLocationCoordinate2D coor, CZWMapKit *mapKit) {
//        [mapKit czw_reverseGeoCode:coor succeedBlock:^(BMKReverseGeoCodeResult *geoResult, CZWMapKit *mapKit) {
//            NSLog(@"%@",geoResult);
//            return YES;
//        } failureBlock:^(BMKSearchErrorCode errorCode) {
//            
//        }];
//    } failureBlock:^(NSError *errorCode) {
//        
//    }];
    __weak typeof(self) weakSelf = self;
    [kCZWMapKit czw_startLocatingSucceedBlock:^BOOL(CLLocationCoordinate2D coor, CZWMapKit *mapKit) {
        NSLog(@"定位成功,我的位置:(%f, %f)",coor.latitude, coor.longitude);
        [mapKit.mapView czw_moveMapViewToCenter:coor animated:YES];
        [mapKit czw_reverseGeoCode:coor succeedBlock:^void(BMKReverseGeoCodeResult *geoResult, CZWMapKit *mapKit) {
            weakSelf.label.text = geoResult.address;
        } failureBlock:^(BMKSearchErrorCode errorCode) {
            
        }];
        return YES;
    } failureBlock:^(NSError *errorCode) {
        
    }];
    
    [self.view bringSubviewToFront:self.deleteBtn];
    [self.view bringSubviewToFront:self.button];
    [self.view bringSubviewToFront:self.addBtn];
}
- (IBAction)clickDelete:(UIButton *)sender {
    [kCZWMapKit removeAllService];
}
- (IBAction)addBtn:(UIButton *)sender {
        [kCZWMapKit czw_searchPoi_BusLine:@"256路" succeedBlock:^(NSMutableArray<BMKPoiInfo *> *poiInfos ,CZWMapKit *mapKit) {
            for (BMKPoiInfo *aPoi in poiInfos) {
                [mapKit czw_searchPoi_BusLineDetailWithUID:aPoi.uid succeedBlock:^(BMKBusLineResult *busLineResult ,CZWMapView *mapView ,CZWMapKit *mapKit) {
                    if (busLineResult) {
                        NSMutableArray <id<BMKAnnotation>> *array = [[NSMutableArray alloc]init];
                        for (int i = 0; i < busLineResult.busStations.count; i ++) {
                            BMKBusStation *aStation = busLineResult.busStations[i];
                            CZWMapAnnotationType type = 0;
                            if (i == 0) {
                                type = CZWMapAnnotationTypeStarting;
                            } else if (i == busLineResult.busStations.count - 1) {
                                type = CZWMapAnnotationTypeTerminal;
                            } else {
                                type = CZWMapAnnotationTypeBus;
                            }
                            CZWMapAnnotation *an = [[CZWMapAnnotation alloc]initWithBusStation:aStation type:type];
                            [array addObject:an];
                        }
                        BMKBusStation *firstStation = [busLineResult.busStations firstObject];
                        [mapView czw_addStationAnnotation:array];
                        [mapView czw_addBusLine:busLineResult.busSteps];
                        [mapView czw_moveMapViewToCenter:firstStation.location animated:YES];
                    }
    
                } failureBlock:^(BMKSearchErrorCode errorCode) {
    
                }];
            }
            
        } failureBlock:^(BMKSearchErrorCode errorCode) {
            
        }];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //[kCZWMapKit czw_startLocatingDelegate:self locatingMode:CZWLocatingOnce];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}


- (void)czw_mapView:(CZWMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    __weak typeof(self) weakSelf = self;
    [kCZWMapKit czw_reverseGeoCode:kCZWMapKit.mapView.centerCoordinate succeedBlock:^(BMKReverseGeoCodeResult *geoResult, CZWMapKit *mapKit) {
        weakSelf.label.text = geoResult.address;
    } failureBlock:^(BMKSearchErrorCode errorCode) {
        
    }];
}
@end
