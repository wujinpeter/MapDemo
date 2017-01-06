//
//  CustomCalloutView.m
//  MapDemo
//
//  Created by wujin on 16/9/22.
//  Copyright © 2016年 Individual Developer. All rights reserved.
//

#import "CustomCalloutView.h"
#import "POIDetailViewController.h"

#define kArrorHeight        10

#define kPortraitMargin     5
#define kPortraitWidth      70
#define kPortraitHeight     50

#define kTitleWidth         120
#define kTitleHeight        20


@interface CustomCalloutView ()

@property (nonatomic, strong) UIImageView *portraitView;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *calloutButton;

@end

@implementation CustomCalloutView

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self){
        self.backgroundColor = [UIColor clearColor];
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews{
    // 添加图片
    self.portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(kPortraitMargin, kPortraitMargin, kPortraitWidth, kPortraitHeight)];
    
    self.portraitView.backgroundColor = [UIColor blackColor];
    [self addSubview:self.portraitView];
    
    // 添加标题
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kPortraitMargin*2 + kPortraitWidth, kPortraitMargin, kTitleWidth, kTitleHeight)];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    self.titleLabel.textColor = [UIColor whiteColor];
    // self.titleLabel.text = @"title";
    [self addSubview:self.titleLabel];
    
    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kPortraitMargin*2 + kPortraitWidth, kPortraitMargin*2 + kTitleHeight, kTitleWidth, kTitleHeight)];
    self.subtitleLabel.font = [UIFont systemFontOfSize:12];
    self.subtitleLabel.textColor = [UIColor lightGrayColor];
    // self.subtitleLabel.text = @"subtitle";
    [self addSubview:self.subtitleLabel];
    
    self.calloutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.calloutButton.frame = CGRectMake(kPortraitMargin*3 + kPortraitWidth+kTitleWidth, kPortraitMargin, 45, 45);
    self.calloutButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.calloutButton.backgroundColor = [UIColor whiteColor];
    self.calloutButton.layer.cornerRadius = 5;
    
    [self.calloutButton addTarget:self action:@selector(calloutButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.calloutButton setTitle:@"POI" forState:UIControlStateNormal];
    [self.calloutButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self addSubview:self.calloutButton];
}

- (void)calloutButtonAction:(id)sender{
    if(self.delegate!=nil){
        [self.delegate goPOIDetail];
    }
}

#pragma mark - Override

- (void)setTitle:(NSString *)title{
    self.titleLabel.text = title;
}

- (void)setSubtitle:(NSString *)subtitle{
    self.subtitleLabel.text = subtitle;
}

- (void)setImage:(UIImage *)image{
    self.portraitView.image = image;
}

#pragma mark - draw rect

- (void)drawRect:(CGRect)rect{
    
    [self drawInContext:UIGraphicsGetCurrentContext()];
    
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    
}

- (void)drawInContext:(CGContextRef)context{
    
    CGContextSetLineWidth(context, 2.0);
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8].CGColor);
    
    [self getDrawPath:context];
    CGContextFillPath(context);
    
}

- (void)getDrawPath:(CGContextRef)context{
    CGRect rrect = self.bounds;
    CGFloat radius = 6.0;
    CGFloat minx = CGRectGetMinX(rrect),
    midx = CGRectGetMidX(rrect),
    maxx = CGRectGetMaxX(rrect);
    CGFloat miny = CGRectGetMinY(rrect),
    maxy = CGRectGetMaxY(rrect)-kArrorHeight;
    
    CGContextMoveToPoint(context, midx+kArrorHeight, maxy);
    CGContextAddLineToPoint(context,midx, maxy+kArrorHeight);
    CGContextAddLineToPoint(context,midx-kArrorHeight, maxy);
    
    CGContextAddArcToPoint(context, minx, maxy, minx, miny, radius);
    CGContextAddArcToPoint(context, minx, minx, maxx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, maxx, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextClosePath(context);
}

@end
