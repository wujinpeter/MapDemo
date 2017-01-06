//
//  CustomAnnotationView.h
//  MapDemo
//
//  Created by wujin on 16/9/22.
//  Copyright © 2016年 Individual Developer. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
#import "CustomCalloutView.h"
#import <AMapSearchKit/AMapSearchKit.h>

@interface CustomAnnotationView : MAAnnotationView

@property (nonatomic, strong) CustomCalloutView *calloutView;

@end
