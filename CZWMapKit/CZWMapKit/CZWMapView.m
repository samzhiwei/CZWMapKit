//
//  CZWMapView.m
//  CZWMapKit
//
//  Created by tianqu on 16/6/30.
//  Copyright © 2016年 Tianqu. All rights reserved.
//

#import "CZWMapView.h"

@implementation CZWMapView
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)setupWIthCustomType:(CZWMapViewCustomType)type delegate:(id<BMKMapViewDelegate>)delegate{
    switch (type) {
        case CZWMapViewCustomTypeTwo :{
            
            break;
        }
        default:{//CZWMapViewCustomTypeOne 默认
            self.zoomLevel = 16;
            self.showMapScaleBar = YES;
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
        [self setupWIthCustomType:(CZWMapViewCustomType)type delegate:delegate];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame CustomType:(CZWMapViewCustomType)type delegate:(id<BMKMapViewDelegate>)delegate{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupWIthCustomType:type delegate:delegate];
    }
    return self;
}

/**
 *  自定义精度圈(暂时没效果)
 */
- (BMKLocationViewDisplayParam *)customLocationAccuracyCircle {
    BMKLocationViewDisplayParam *param = [[BMKLocationViewDisplayParam alloc] init];
    param.accuracyCircleStrokeColor = [UIColor yellowColor];
    param.accuracyCircleFillColor = [UIColor redColor];
    return param;
}

- (void)czw_addAnnotations:(NSMutableArray *)annotations{
   //[ self addAnnotation:<#(id<BMKAnnotation>)#>];
}
@end
