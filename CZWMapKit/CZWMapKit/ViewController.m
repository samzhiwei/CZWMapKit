//
//  ViewController.m
//  CZWMapKit
//
//  Created by tianqu on 16/6/30.
//  Copyright © 2016年 Tianqu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <BMKOfflineMapDelegate>
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (strong, nonatomic) NSArray *hotCity;
@property (strong, nonatomic) NSArray *offlineCity;
@property (strong, nonatomic) BMKOfflineMap *map;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [kCZWMapKit czw_userAuthorization:kCLAuthorizationStatusAuthorizedWhenInUse];
    
    NSLog(@"self = %p",self);
    
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
//    [kCZWMapKit czw_loadingMapView:self];
//    [kCZWMapKit czw_searchPoi_BusLine:@"77路" succeedBlock:^(NSMutableArray<BMKPoiInfo *> *poiInfos ,CZWMapKit *mapKit) {
//        for (BMKPoiInfo *aPoi in poiInfos) {
//            [mapKit czw_searchPoi_BusLineDetailWithUID:aPoi.uid succeedBlock:^(BMKBusLineResult *busLineResult ,CZWMapView *mapView ,CZWMapKit *mapKit) {
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
//                    [mapView czw_addStationAnnotation:array];
//                    [mapView czw_addBusLine:busLineResult.busSteps];
//                    [mapView czw_moveMapViewToCenter:firstStation.location animated:YES];
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
    
//    _hotCity = [kCZWMapKit czw_startOffLineMapService:^NSArray *(BMKOfflineMap *offlineMap) {
//        return [offlineMap getHotCityList];
//    }];
//    
//    [kCZWMapKit czw_offlineMapHandler:^(BMKOfflineMap *offlineMap) {
//        
//        [offlineMap start:257];
//    }];
    self.map = [[BMKOfflineMap alloc]init];
    self.map.delegate = self;
    NSLog(@"map = %p",self.map);
    _hotCity = [self.map getHotCityList];
    //获取支持离线下载城市列表
    _offlineCity = [self.map getOfflineCityList];
    [self.map start:257];
    
    [self.view bringSubviewToFront:self.deleteBtn];
    [self.view bringSubviewToFront:self.button];
    [self.view bringSubviewToFront:self.addBtn];
}
- (IBAction)clickDelete:(UIButton *)sender {
    [kCZWMapKit removeAllService];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [kCZWMapKit czw_startLocatingDelegate:self locatingMode:CZWLocatingOnce];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}


- (CZWMapView *)showMapViewWithMapKit:(CZWMapKit *)mapKit{
    return [[CZWMapView alloc]initWithFrame:self.view.bounds CustomType:CZWMapViewCustomTypeOne delegate:mapKit];
}

- (void)addMapInView:(CZWMapView *)mapView{
    [self.view addSubview:mapView];
}



- (void)mapKit:(CZWMapKit *)mapKit didLocationPostion:(CLLocationCoordinate2D)coor{
    NSLog(@"%@",kCZWMapKit);
    [mapKit czw_reverseGeoCode:coor];
    [mapKit.mapView setCenterCoordinate:kCZWMapKit.cacheUserLocation.coordinate animated:YES];
}

- (void)mapKit:(CZWMapKit *)mapKit didLocationCity:(BMKAddressComponent *)addressDetail{
    
}
- (void)mapKit:(CZWMapKit *)mapKit didLocationAddress:(NSString *)address{
    NSLog(@"address = %@,当前线程:%@,当前方法:%s",address,[NSThread currentThread], __FUNCTION__);

}
- (void)onGetOfflineMapState:(int)type withState:(int)state{
    
}
@end
