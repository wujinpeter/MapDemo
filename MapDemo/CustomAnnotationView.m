//
//  CustomAnnotationView.m
//  MapDemo
//
//  Created by wujin on 16/9/22.
//  Copyright © 2016年 Individual Developer. All rights reserved.
//

#import "CustomAnnotationView.h"

#define kCalloutWidth       260.0
#define kCalloutHeight      70.0

@interface CustomAnnotationView ()

@end

@implementation CustomAnnotationView

- (id)initWithAnnotation:(id <MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if(self){
        self.calloutView = [[CustomCalloutView alloc] initWithFrame:CGRectMake(0, 0, kCalloutWidth, kCalloutHeight)];
        self.calloutView.center = CGPointMake(CGRectGetWidth(self.bounds) / 2.f + self.calloutOffset.x,
                                              -CGRectGetHeight(self.calloutView.bounds) / 2.f + self.calloutOffset.y);
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected{
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
    if (self.selected == selected){
        return;
    }
    
    if (selected){
        //        if (self.calloutView == nil){
        //            self.calloutView = [[CustomCalloutView alloc] initWithFrame:CGRectMake(0, 0, kCalloutWidth, kCalloutHeight)];
        //            self.calloutView.center = CGPointMake(CGRectGetWidth(self.bounds) / 2.f + self.calloutOffset.x,
        //                                                  -CGRectGetHeight(self.calloutView.bounds) / 2.f + self.calloutOffset.y);
        //        }
        
        self.calloutView.image = [UIImage imageNamed:@"building"];
        self.calloutView.title = self.annotation.title;
        self.calloutView.subtitle = self.annotation.subtitle;
        
        [self addSubview:self.calloutView];
    }else{
        [self.calloutView removeFromSuperview];
    }
    
    [super setSelected:selected animated:animated];
}

// 重写此函数 用以实现点击calloutView判断为点击该annotationView -- 未起作用???
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    BOOL inside = [super pointInside:point withEvent:event];
    
    if (!inside && self.selected){
        inside = [self.calloutView pointInside:[self convertPoint:point toView:self.calloutView] withEvent:event];
    }
    return inside;
}


@end
