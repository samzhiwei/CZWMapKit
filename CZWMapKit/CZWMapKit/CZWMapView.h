//
//  CZWMapView.h
//  CZWMapKit
//
//  Created by tianqu on 16/6/30.
//  Copyright © 2016年 Tianqu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
typedef NS_ENUM(NSUInteger, CZWMapViewCustomType) {
    CZWMapViewCustomTypeOne = 1,
    CZWMapViewCustomTypeTwo = 2
};

@interface CZWMapView : BMKMapView;
- (instancetype)initWithFrame:(CGRect)frame CustomType:(CZWMapViewCustomType)type delegate:(id<BMKMapViewDelegate>)delegate;
- (instancetype)initWithCustomType:(CZWMapViewCustomType)type delegate:(id<BMKMapViewDelegate>)delegate;
@end
