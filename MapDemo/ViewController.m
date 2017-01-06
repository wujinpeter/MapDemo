//
//  ViewController.m
//  MapDemo
//
//  Created by wujin on 16/9/19.
//  Copyright © 2016年 Individual Developer. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "CustomAnnotationView.h"
#import "POIDetailViewController.h"

#define APIKey @"6a3f70ce43b270359f6db2440eee60d4"

@interface ViewController ()<MAMapViewDelegate,AMapSearchDelegate,UITableViewDelegate,UITableViewDataSource,CustomCalloutViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,strong) MAMapView *mapView;
@property (nonatomic,strong) UIButton *locationButton;
@property (nonatomic,strong) UIButton *searchButton;
@property (nonatomic,strong) AMapSearchAPI *search;
@property (nonatomic,strong) CLLocation *currentLocation;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSArray *pois;
@property (nonatomic,strong) NSMutableArray *annotations;
@property (nonatomic,strong) AMapPOI *poiChoose;
@property (nonatomic,strong) UILongPressGestureRecognizer *longPressGesture;
@property (nonatomic,strong) MAPointAnnotation *destinationPoint;
@property (nonatomic,strong) NSArray *pathPolylines;
@property (nonatomic,strong) NSMutableArray *polylinesLengthArray;
@property (nonatomic,strong) UILabel *polylinesLengthLabel;
@property (nonatomic,assign) Boolean flagOfLocationToFirstPolyline;
@property (nonatomic, strong) UILabel *navigationLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Bar的模糊效果 默认为YES iOS7及以上对导航栏（工具栏亦同）有高斯模糊处理
    self.navigationController.navigationBar.translucent = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setNavigationLabelTitle:@"MapDemo"];
    [self initMapView];
    [self initControls];
    [self initSearch];
    [self initAttributes];
    [self initTableView];
}

/**
 *  设置NavigationLabel
 *
 *  @param title title
 */
-(void)setNavigationLabelTitle:(NSString *)title{
    self.navigationLabel.text = title;
}

-(UILabel *)navigationLabel{
    if(!_navigationLabel){
        _navigationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, 100, 20)];
        _navigationLabel.font = [UIFont systemFontOfSize:18];
        _navigationLabel.textAlignment = NSTextAlignmentCenter;
        _navigationLabel.textColor = [UIColor blackColor];
        self.navigationItem.titleView = _navigationLabel;
        
    }
    return _navigationLabel;
}

// ----------------------------------------- Day4 -------------------------------------------

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture{
    _flagOfLocationToFirstPolyline = true;
    
    if (gesture.state == UIGestureRecognizerStateBegan){
        CLLocationCoordinate2D coordinate = [_mapView convertPoint:[gesture locationInView:_mapView]
                                              toCoordinateFromView:_mapView];
        
        // 添加标注
        if (_destinationPoint != nil){
            // 清理
            [_mapView removeAnnotation:_destinationPoint];
            _destinationPoint = nil;
            
            // [_mapView removeOverlays:_pathPolylines];
            // _pathPolylines = nil;
        }
        
        _destinationPoint = [[MAPointAnnotation alloc] init];
        _destinationPoint.coordinate = coordinate;
        _destinationPoint.title = @"Destination";
        
        [_mapView addAnnotation:_destinationPoint];
    }
    
}

- (void)pathAction:(id)sender{
    _polylinesLengthArray = [[NSMutableArray alloc] init];
    if (_destinationPoint == nil || _currentLocation == nil || _search == nil){
        NSLog(@"path search failed");
        return;
    }
    // 设置为步行路径规划
    AMapWalkingRouteSearchRequest *request = [[AMapWalkingRouteSearchRequest alloc] init];
    
    request.origin = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    request.destination = [AMapGeoPoint locationWithLatitude:_destinationPoint.coordinate.latitude longitude:_destinationPoint.coordinate.longitude];
    
    [_search AMapWalkingRouteSearch:request];
}

- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response{
    //    NSLog(@"request: %@", request);
    //    NSLog(@"response: %@", response);
    if (response.count > 0){
        [_mapView removeOverlays:_pathPolylines];
        _pathPolylines = nil;
        
        // 只显示第一条
        _pathPolylines = [self polylinesForPath:response.route.paths[0]];
        
        [_mapView addOverlays:_pathPolylines];
        [_mapView showAnnotations:@[_destinationPoint, _mapView.userLocation] animated:YES];
        
        double polylinesLength = [self caculatePolylinesLength];
        _polylinesLengthLabel = [[UILabel alloc] initWithFrame:CGRectMake(200, CGRectGetHeight(_mapView.bounds)-80, 150, 40)];
        _polylinesLengthLabel.text = [NSString stringWithFormat:@"   D:%f",polylinesLength];
        _polylinesLengthLabel.textColor = [UIColor blackColor];
        _polylinesLengthLabel.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_polylinesLengthLabel];
    }
}

- (double)caculatePolylinesLength{
    // 作业4 计算总距离
    double length = 0;
    for(int i=0;i<_polylinesLengthArray.count;i++){
        length += [_polylinesLengthArray[i] doubleValue];
    }
    NSLog(@"all:%f",length);
    return length;
}

- (NSArray *)polylinesForPath:(AMapPath *)path{
    if (path == nil || path.steps.count == 0){
        return nil;
    }
    
    NSMutableArray *polylines = [NSMutableArray array];
    [path.steps enumerateObjectsUsingBlock:^(AMapStep *step, NSUInteger idx, BOOL *stop) {
        NSUInteger count = 0;
        CLLocationCoordinate2D *coordinates = [self coordinatesForString:step.polyline
                                                         coordinateCount:&count
                                                              parseToken:@";"];
        
        MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coordinates count:count];
        [polylines addObject:polyline];
        
        free(coordinates), coordinates = NULL;
    }];
    
    return polylines;
}

- (CLLocationCoordinate2D *)coordinatesForString:(NSString *)string
                                 coordinateCount:(NSUInteger *)coordinateCount
                                      parseToken:(NSString *)token{
    if (string == nil){
        return NULL;
    }
    
    if (token == nil){
        token = @",";
    }
    
    NSString *str = @"";
    if (![token isEqualToString:@","]){
        str = [string stringByReplacingOccurrencesOfString:token withString:@","];
    }else{
        str = [NSString stringWithString:string];
    }
    
    NSArray *components = [str componentsSeparatedByString:@","];
    NSUInteger count = [components count] / 2;
    if (coordinateCount != NULL){
        *coordinateCount = count;
    }
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D*)malloc(count * sizeof(CLLocationCoordinate2D));
    
    // ??????????????????????????
    double polylineLength = 0;
    for (int i = 0; i < count; i++){
        coordinates[i].longitude = [[components objectAtIndex:2 * i]     doubleValue];
        coordinates[i].latitude  = [[components objectAtIndex:2 * i + 1] doubleValue];
        // ---------------------
        // 计算location与polyline第一次定位的长度
        if(i==0&&_flagOfLocationToFirstPolyline){
            MAMapPoint pointFrom = MAMapPointForCoordinate(CLLocationCoordinate2DMake(_currentLocation.coordinate.latitude,_currentLocation.coordinate.longitude));
            MAMapPoint pointTo = MAMapPointForCoordinate(CLLocationCoordinate2DMake(coordinates[i].latitude,coordinates[i].longitude));
            CLLocationDistance distance = MAMetersBetweenMapPoints(pointFrom,pointTo);
            polylineLength += distance;
            NSLog(@"location to polyline:%f",distance);
            _flagOfLocationToFirstPolyline = false;
        }
        if(i>0){
            // 作业4 计算polyline长度
            MAMapPoint pointFrom = MAMapPointForCoordinate(CLLocationCoordinate2DMake(coordinates[i-1].latitude,coordinates[i-1].longitude));
            MAMapPoint pointTo = MAMapPointForCoordinate(CLLocationCoordinate2DMake(coordinates[i].latitude,coordinates[i].longitude));
            CLLocationDistance distance = MAMetersBetweenMapPoints(pointFrom,pointTo);
            polylineLength += distance;
        }
    }
    NSLog(@"%f",polylineLength);
    [_polylinesLengthArray addObject:[NSNumber numberWithDouble:polylineLength]];
    
    return coordinates;
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay{
    if ([overlay isKindOfClass:[MAPolyline class]]){
        //初始化一个路线类型的view
        MAPolylineRenderer *polygonView = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        //设置线宽颜色等
        polygonView.lineWidth = 4;
        polygonView.strokeColor = [UIColor blackColor];
        polygonView.lineJoinType = kMALineJoinRound;//连接类型
        //返回view，就进行了添加
        return polygonView;
    }
    return nil;
    
}

// ----------------------------------------- Day3 -------------------------------------------

// 作业3 点击按钮页面跳转
- (void)goPOIDetail{
    POIDetailViewController *poiDetailVC = [[POIDetailViewController alloc] init];
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    [tempArray addObject:_poiChoose.name];
    [tempArray addObject:_poiChoose.address];
    [tempArray addObject:_poiChoose.city];
    [tempArray addObject:_poiChoose.citycode];
    [tempArray addObject:_poiChoose.tel];
    
    poiDetailVC.poiDetailArray = tempArray;
    [self.navigationController pushViewController:poiDetailVC animated:YES];
}

// ----------------------------------------- Day2 -------------------------------------------

- (void)initTableView{
    CGFloat halfHeight = CGRectGetHeight(self.view.bounds) * 0.5;
    _tableView=[[UITableView alloc] initWithFrame:CGRectMake(0, halfHeight-64, CGRectGetWidth(self.view.bounds), halfHeight) style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    // 隐藏滑动条
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.separatorStyle = NO;
    [self.view addSubview:_tableView];
    
}

#pragma mark table view delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _pois.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = (UITableViewCell*)[tableView  dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    AMapPOI *poi = _pois[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = poi.name;
    cell.detailTextLabel.text = poi.address;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // 为点击的poi点添加标注
    AMapPOI *poi = _pois[indexPath.row];
    
    MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
    annotation.coordinate = CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude);
    annotation.title = poi.name;
    annotation.subtitle = poi.address;
    _poiChoose = poi;
    
    // 作业2 设置点击TableViewCell后 大头针在mapView中心位置
    [self.mapView setCenterCoordinate:[annotation coordinate]];
    
    // 作业2 避免重复的annotation
    Boolean flag = true;
    for(int i=0;i<_annotations.count;i++){
        MAPointAnnotation *tempAnnotation = _annotations[i];
        if([tempAnnotation.title isEqualToString: annotation.title]&&
           [tempAnnotation.subtitle isEqualToString: annotation.subtitle]){
            flag = false;
        }
    }
    
    if(flag){
        [_mapView addAnnotation:annotation];
        [_annotations addObject:annotation];
    }
}

-(void)initAttributes{
    _annotations = [[NSMutableArray alloc] init];
    _pois = [[NSArray alloc] init];
    
    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    _longPressGesture.delegate = self;
    [_mapView addGestureRecognizer:_longPressGesture];
}

-(void)searchAction:(id)sender{
    if(_currentLocation == nil || _search == nil){
        NSLog(@"search failed");
        return;
    }
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    request.keywords = @"餐厅";
    request.sortrule = 0;
    request.requireExtension = YES;
    [_search AMapPOIAroundSearch:request];
}

/* POI 搜索回调. */
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if (response.pois.count == 0){
        return;
    }
    //    NSLog(@"%@",request);
    //    NSLog(@"%@",response);
    _pois = response.pois;
    [_tableView reloadData];
    
    // 清空标注
    [_mapView removeAnnotations:_annotations];
    [_annotations removeAllObjects];
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation{
    if (annotation == _destinationPoint){
        static NSString *reuseIndetifier = @"startAnnotationReuseIndetifier";
        MAPinAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
        }
        
        annotationView.canShowCallout = YES;
        annotationView.animatesDrop = YES;
        
        return annotationView;
    }
    
    if ([annotation isKindOfClass:[MAPointAnnotation class]]){
        static NSString *reuseIndetifier = @"annotationReuseIndetifier";
        CustomAnnotationView *annotationView = (CustomAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationView == nil){
            annotationView = [[CustomAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
        }
        annotationView.image = [UIImage imageNamed:@"restaurant"];
        annotationView.canShowCallout = NO;
        annotationView.calloutView.delegate = self;
        
        return annotationView;
    }
    return nil;
}

// ----------------------------------------- Day1 -------------------------------------------

-(void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view{
    if([view.annotation isKindOfClass:[MAUserLocation class]]){
        [self reGeoAction];
    }
}

-(void)reGeoAction{
    if(_currentLocation){
        AMapReGeocodeSearchRequest *request = [[AMapReGeocodeSearchRequest alloc] init];
        request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
        // 逆地址编码查询接口
        [_search AMapReGoecodeSearch:request];
    }
}

// 逆地理编码查询回调
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response{
    // NSLog(@"%@",response);
    
    NSString *title = response.regeocode.addressComponent.city;
    if(title.length == 0){
        title = response.regeocode.addressComponent.province;
    }
    _mapView.userLocation.title = title;
    _mapView.userLocation.subtitle = response.regeocode.formattedAddress;
}

- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error{
    NSLog(@"request :%@, error :%@", request, error);
}

// 位置或者设备方向更新后，会调用此函数
-(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation{
    // NSLog(@"userLocation:%@",userLocation.location);
    _currentLocation = [userLocation.location copy];
}

-(void)initSearch{
    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;
}

// 定位按钮切换 当userTrackingMode改变时，调用此接口
-(void)mapView:(MAMapView *)mapView didChangeUserTrackingMode:(MAUserTrackingMode)mode animated:(BOOL)animated{
    if(mode == MAUserTrackingModeNone){
        [_locationButton setImage:[UIImage imageNamed:@"location_no"] forState:UIControlStateNormal];
    }else if(mode == MAUserTrackingModeFollow){
        [_locationButton setImage:[UIImage imageNamed:@"location_yes"] forState:UIControlStateNormal];
    }else if(MAUserTrackingModeFollowWithHeading){
        [_locationButton setImage:[UIImage imageNamed:@"location_heading"] forState:UIControlStateNormal];
    }
}

// 按钮
-(void)initControls{
    _locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _locationButton.frame = CGRectMake(20, CGRectGetHeight(_mapView.bounds)-80, 40, 40);
    _locationButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _locationButton.backgroundColor = [UIColor whiteColor];
    _locationButton.layer.cornerRadius = 5;
    
    [_locationButton addTarget:self action:@selector(locateAction:) forControlEvents:UIControlEventTouchUpInside];
    [_locationButton setImage:[UIImage imageNamed:@"location_no"] forState:UIControlStateNormal];
    [self.view addSubview:_locationButton];
    
    _searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _searchButton.frame = CGRectMake(80, CGRectGetHeight(_mapView.bounds)-80, 40, 40);
    _searchButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _searchButton.backgroundColor = [UIColor whiteColor];
    _searchButton.layer.cornerRadius = 5;
    
    [_searchButton addTarget:self action:@selector(searchAction:) forControlEvents:UIControlEventTouchUpInside];
    [_searchButton setImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    [self.view addSubview:_searchButton];
    
    UIButton *pathButton = [UIButton buttonWithType:UIButtonTypeCustom];
    pathButton.frame = CGRectMake(140, CGRectGetHeight(_mapView.bounds)-80, 40, 40);
    pathButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    pathButton.backgroundColor = [UIColor whiteColor];
    pathButton.layer.cornerRadius = 5;
    [pathButton setImage:[UIImage imageNamed:@"path"] forState:UIControlStateNormal];
    
    [pathButton addTarget:self action:@selector(pathAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:pathButton];
    
}

-(void)locateAction:(id)sender{
    if(_mapView.userTrackingMode == MAUserTrackingModeNone){
        [_mapView setUserTrackingMode:MAUserTrackingModeFollow animated:YES];
    }else if(_mapView.userTrackingMode == MAUserTrackingModeFollow){
        [_mapView setUserTrackingMode:MAUserTrackingModeFollowWithHeading animated:YES];
    }else if(_mapView.userTrackingMode == MAUserTrackingModeFollowWithHeading){
        // 作业1 增加定位模式
        [_mapView setUserTrackingMode:MAUserTrackingModeNone animated:YES];
    }
}

// 显示地图
-(void)initMapView{
    [AMapServices sharedServices].apiKey = APIKey;
    
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)*0.5)];
    _mapView.delegate = self;
    _mapView.compassOrigin = CGPointMake(_mapView.compassOrigin.x, 22);
    _mapView.scaleOrigin = CGPointMake(_mapView.scaleOrigin.x, 22);
    [_mapView setZoomLevel:13.5 animated:YES];
    
    [self.view addSubview:_mapView];
    
    _mapView.showsUserLocation = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
