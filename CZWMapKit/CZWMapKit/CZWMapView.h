//
//  CZWMapView.h
//  CZWMapKit
//
//  Created by tianqu on 16/6/30.
//  Copyright © 2016年 Tianqu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
typedef NS_ENUM(NSUInteger, CZWMapViewCustomType) {
    CZWMapViewCustomTypeOne = 1,
    CZWMapViewCustomTypeTwo = 2
};

@interface CZWMapAnnotation : BMKPointAnnotation
typedef NS_ENUM(NSUInteger, CZWMapAnnotationType) {
    CZWMapAnnotationTypeUnknow = 0,
    CZWMapAnnotationTypeStarting,
    CZWMapAnnotationTypeTerminal,
    CZWMapAnnotationTypeBus,
    CZWMapAnnotationTypeMetro,
    CZWMapAnnotationTypeDrivingCar,
    CZWMapAnnotationTypeWalking
};
//@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
//@property (copy, nonatomic) NSString *title;
//@property (copy, nonatomic) NSString *subtitle;
@property (assign, nonatomic) CZWMapAnnotationType type;
@property (assign, nonatomic) int degree;
- (instancetype)initWithCoor:(CLLocationCoordinate2D)coor title:(NSString *)title subtitle:(NSString *)subtitle type:(CZWMapAnnotationType)type;
- (instancetype)initWithBusStation:(BMKBusStation *)busStation type:(CZWMapAnnotationType)type;

@end

@interface CZWMapView : BMKMapView

/**
 *  delegate尽量为kCZWMapKit,在hander中要调用setupWithCustomType;
 */
- (instancetype)initWithDelegate:(id<BMKMapViewDelegate>)delegate;

/**
 *  进入setupWithCustomType方法中可以添加自定义新的地图样式,不需手动在hander中调用
 */
- (instancetype)initWithFrame:(CGRect)frame CustomType:(CZWMapViewCustomType)type delegate:(id<BMKMapViewDelegate>)delegate;

- (void)setupWithCustomType:(CZWMapViewCustomType)type;

/**
 *  移动中心
 */
- (void)czw_moveMapViewToCenter:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;

/**
 *  加站点针
 */
- (void)czw_addStationAnnotation:(NSMutableArray <id<BMKAnnotation>>*)stations;
/**
 *  加线路(百度返回数据画)
 */
- (void)czw_addBusLine:(NSArray <BMKBusStep *>*)lineStep;
/**
 *  自己根据站点画
 */
- (void)czw_addBusLine_selfData:(NSArray <CLLocation *>*)lineStep;
/**
 *  画走路方案(百度返回数据画)
 */
- (void)czw_addWalkingRouteLine:(BMKWalkingRouteLine *)aRouteLine;
@end
