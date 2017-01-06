//
//  CustomCalloutView.h
//  MapDemo
//
//  Created by wujin on 16/9/22.
//  Copyright © 2016年 Individual Developer. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CustomCalloutViewDelegate

- (void)goPOIDetail;

@end

@interface CustomCalloutView : UIView

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic,assign) id<CustomCalloutViewDelegate> delegate;

@end
