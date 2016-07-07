//
//  CZWMapView.m
//  CZWMapKit
//
//  Created by tianqu on 16/6/30.
//  Copyright © 2016年 Tianqu. All rights reserved.
//
#define DEFAULT_TEXT nil//@"暂无显示内容"
#import "CZWMapView.h"

@implementation CZWMapAnnotation
@synthesize degree = _degree;

- (instancetype)initWithCoor:(CLLocationCoordinate2D)coor title:(NSString *)title subtitle:(NSString *)subtitle type:(CZWMapAnnotationType)type{
    self = [super init];
    if (self) {
        self.title = title;
        self.subtitle = subtitle;
        self.coordinate = coor;
        self.type = type;
    }
    return self;
}

- (instancetype)initWithBusStation:(BMKBusStation *)busStation type:(CZWMapAnnotationType)type{
    self = [super init];
    if ( self) {
        self.title = busStation.title;
        self.subtitle = DEFAULT_TEXT;
        self.coordinate = busStation.location;
        self.type = type;
    }
    return self;
}

@end

@implementation CZWMapView
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)setupWithCustomType:(CZWMapViewCustomType)type delegate:(id<BMKMapViewDelegate>)delegate{
    switch (type) {
        case CZWMapViewCustomTypeTwo :{
            
            break;
        }
        default:{//CZWMapViewCustomTypeOne 默认
            self.zoomLevel = 16;
            self.showMapScaleBar = YES;
            self.buildingsEnabled = YES;
            self.mapScaleBarPosition = CGPointMake(10, 10);
            [self updateLocationViewWithParam:[self customLocationAccuracyCircle]];
            self.delegate = delegate;
            
            break;
        }
    }
}

- (instancetype)initWithCustomType:(CZWMapViewCustomType)type delegate:(id<BMKMapViewDelegate>)delegate{
    self = [self init];
    if (self) {
        [self setupWithCustomType:(CZWMapViewCustomType)type delegate:delegate];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame CustomType:(CZWMapViewCustomType)type delegate:(id<BMKMapViewDelegate>)delegate{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupWithCustomType:type delegate:delegate];
        self.compassPosition = CGPointMake(frame.size.width - 10, 10);
    }
    return self;
}

/**
 *  自定义精度圈
 */
- (BMKLocationViewDisplayParam *)customLocationAccuracyCircle {
    BMKLocationViewDisplayParam *param = [[BMKLocationViewDisplayParam alloc] init];
    param.isAccuracyCircleShow = NO;
    param.accuracyCircleStrokeColor = [UIColor yellowColor];
    param.accuracyCircleFillColor = [UIColor redColor];
    return param;
}

- (void)czw_moveMapViewToCenter:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated{
    [self setCenterCoordinate:coordinate animated:animated];
}

- (void)czw_addStationAnnotation:(NSMutableArray <id<BMKAnnotation>>*)stations{
    //清空
    if (self.annotations) {
        if (self.annotations.count > 0) {
            [self removeAnnotations:self.annotations];
        }
    }
    //添加
    
    [self addAnnotations:stations];
    NSLog(@"添加站点成功");
}

- (void)czw_addBusLine:(NSArray <BMKBusStep *>*)lineStep{
    //清空
    if (self.overlays) {
        if (self.overlays.count > 0) {
            [self removeOverlays:self.overlays];
        }
    }
    //添加
    //路段信息

    NSInteger index = 0;
    //累加index为下面声明数组temppoints时用
    for (NSInteger j = 0; j < lineStep.count; j++) {
        BMKBusStep* step = [lineStep objectAtIndex:j];
        index += step.pointsCount;
    }
    //直角坐标划线
    BMKMapPoint * temppoints = new BMKMapPoint[index];
    NSInteger k=0;
    for (NSInteger i = 0; i < lineStep.count ; i++) {
        BMKBusStep* step = [lineStep objectAtIndex:i];
        for (NSInteger j = 0; j < step.pointsCount; j++) {
            BMKMapPoint pointarray;
            pointarray.x = step.points[j].x;
            pointarray.y = step.points[j].y;
            //NSLog(@"第%d个 x = %f,y = %f",j, pointarray.x,pointarray.y);
            temppoints[k] = pointarray;
            k++;
        }
    }
    
    BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:index];
    [self addOverlay:polyLine];
    NSLog(@"添加线路成功");
    delete[] temppoints;
}

- (void)czw_addBusLine_selfData:(NSArray <CLLocation *>*)lineStep{
    NSUInteger count = lineStep.count;
    CLLocationCoordinate2D *coorArray = new CLLocationCoordinate2D[count];
    NSLog(@"自己的站点:");
    for (int i = 0 ;i < lineStep.count ; i ++) {
        CLLocation *aStation = lineStep[i];
        CLLocationCoordinate2D point;
        point.latitude = aStation.coordinate.latitude;
        point.longitude= aStation.coordinate.longitude;
        coorArray[i] = point;
    }
    
    BMKPolyline* polyLine = [BMKPolyline polylineWithCoordinates:coorArray count:count];
    [self addOverlay:polyLine];// 添加路线overlay
    delete []coorArray;
}

/**
 *  画走路方案(百度返回数据画)
 */
- (void)czw_addWalkingRouteLine:(BMKWalkingRouteLine *)aRouteLine{
    int planPointCounts = 0;
    for (int i = 0; i < aRouteLine.steps.count; i++) {
        BMKWalkingStep *aStep = aRouteLine.steps[i];
        if (i == 0) {//起点
            CZWMapAnnotation *an = [[CZWMapAnnotation alloc]initWithCoor:aRouteLine.starting.location title:@"起点" subtitle:DEFAULT_TEXT type:CZWMapAnnotationTypeStarting];
            [self addAnnotation:an];
        } else if (i == aRouteLine.steps.count - 1) {//终点
            CZWMapAnnotation *an = [[CZWMapAnnotation alloc]initWithCoor:aRouteLine.terminal.location title:@"终点" subtitle:DEFAULT_TEXT type:CZWMapAnnotationTypeTerminal];
            [self addAnnotation:an];
        } else {//途径
            CZWMapAnnotation *an = [[CZWMapAnnotation alloc]initWithCoor:aStep.entrace.location title:aStep.entraceInstruction subtitle:DEFAULT_TEXT type:CZWMapAnnotationTypeWalking];
            an.degree = aStep.direction * 30;
            [self addAnnotation:an];
        }
        planPointCounts += aStep.pointsCount;
    }
    
    //轨迹点(画线)
    BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
    int i = 0;
    for (int j = 0; j < aRouteLine.steps.count; j++) {
        BMKWalkingStep* transitStep = [aRouteLine.steps objectAtIndex:j];
        int k=0;
        for(k=0;k<transitStep.pointsCount;k++) {
            temppoints[i].x = transitStep.points[k].x;
            temppoints[i].y = transitStep.points[k].y;
            i++;
        }
    }
    // 通过points构建BMKPolyline
    BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
    [self addOverlay:polyLine]; // 添加路线overlay
    delete []temppoints;
}



@end
