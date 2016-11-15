//
//  BaseMapViewController.m
//  example
//
//  Created by xudesong on 16/9/19.
//
//

#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height

#define MYBUNDLE_NAME @ "mapapi.bundle"
#define MYBUNDLE_PATH [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: MYBUNDLE_NAME]
#define MYBUNDLE [NSBundle bundleWithPath: MYBUNDLE_PATH]

#import "BaseMapViewController.h"

#import <BaiduMapAPI_Location/BMKLocationComponent.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
#import <BaiduMapAPI_Base/BMKBaseComponent.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>

#import "UIImage+Rotate.h"

@interface BaseMapViewController ()<BMKLocationServiceDelegate,BMKMapViewDelegate,BMKRouteSearchDelegate>

@property (nonatomic, strong) BMKMapView *mapView;

@property (nonatomic, strong) BMKLocationService *service;

@property (nonatomic, strong) BMKRouteSearch *routeSearch;

@property (nonatomic, strong) BMKDrivingRoutePlanOption *routeOption;

@property (nonatomic, strong) UILabel *showRouteInfoLabel;

@property (nonatomic, strong) UISegmentedControl *segment;


@end


@interface RouteAnnotation :  BMKPointAnnotation
{
    int _type; //0:起点 1:终点 3:公交 4:骑乘 5:途经点
    int _degree;
}

@property (nonatomic) int degree;
@property (nonatomic) int type;

@end

@implementation RouteAnnotation

@synthesize type = _type;
@synthesize degree = _degree;

@end

@implementation BaseMapViewController
{
    NSString *showCostTime;
    NSString *showCostDistance;
}

#pragma mark ---------------------生命周期----------------------------
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear: animated];
    [self.mapView viewWillDisappear];
    self.mapView.delegate = nil;
    self.service.delegate = nil;
    self.routeSearch.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self setNavigationOptions];
    
    [self setUIOptions];
    
    [self setPlanRoute];
    
}

- (void)dealloc {
    if (_routeSearch != nil) {
        _routeSearch = nil;
    }
    if (_mapView) {
        _mapView = nil;
    }
    if (_service) {
        _service = nil;
    }
}





#pragma mark ---------------------懒加载-------------------------------
- (BMKLocationService *)service
{
    if (!_service) {
        _service = [[BMKLocationService alloc] init];
        _service.delegate = self;
    }
    return _service;
}

- (BMKRouteSearch *)routeSearch
{
    if (!_routeSearch) {
        _routeSearch = [[BMKRouteSearch alloc] init];
        _routeSearch.delegate = self;
    }
    return _routeSearch;
}

//  提示框
- (void)showAlertViewControllerWithTitle: (NSString *)title
                                 Message: (NSString *)message
                                   style: (NSInteger) style
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title message: message preferredStyle: style];
    
    UIAlertAction *aciton = [UIAlertAction actionWithTitle: @"确定" style: UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction: aciton];
    [self presentViewController: alertController animated: NO completion: nil];
}




#pragma mark ---------------------UI布局-------------------------------
- (void)setNavigationOptions
{
    //适配ios7
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0))
    {
        //        self.edgesForExtendedLayout=UIRectEdgeNone;
        self.navigationController.navigationBar.translucent = NO;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title = @"货易车路线规划";
    
    self.navigationController.navigationBar.barTintColor = [UIColor cyanColor];
    
    UIButton *btn = [UIButton buttonWithType: UIButtonTypeSystem];
    btn.frame = CGRectMake(0, 0, 40, 40);
    [btn setTitle: @"返回" forState: 0];
    [btn addTarget: self action: @selector(backAction) forControlEvents: UIControlEventTouchUpInside];
    UIBarButtonItem *leftBBI = [[UIBarButtonItem alloc] initWithCustomView: btn];
    self.navigationItem.leftBarButtonItem = leftBBI;
    
    UIBarButtonItem *rightBBI = [[UIBarButtonItem alloc] initWithTitle: @"保存" style: UIBarButtonItemStyleDone target: self action: @selector(rightBtnAction)];
    self.navigationItem.rightBarButtonItem = rightBBI;
}




- (void)setUIOptions
{
    
    [self setMapView];
    
    [self setCustomView];
}

//
- (void)setMapView
{
    self.mapView = [[BMKMapView alloc]initWithFrame: CGRectMake(0, 0, WIDTH, HEIGHT-64 - 50)];
    //  添加指南针
    [self.mapView setCompassPosition: CGPointMake(20, 20)];
    
    [self.mapView setMapType: BMKMapTypeStandard];
    [self.mapView setTrafficEnabled: YES];
    [self.mapView setZoomLevel: 16];
    self.mapView.rotateEnabled = YES;
    self.mapView.zoomEnabled = YES;
    self.mapView.scrollEnabled = YES;
    self.mapView.delegate = self;
    self.mapView.overlooking = -30;
    //  显示比例尺
    self.mapView.showMapScaleBar = YES;
    [self.view addSubview: self.mapView];
}


//
- (void)setCustomView
{
    
    //  让它自动定义一次
    [self.service startUserLocationService];
    self.mapView.showsUserLocation = NO;
    
    //  添加定位按钮
    UIButton *locationBtn = [UIButton buttonWithType: UIButtonTypeSystem];
    locationBtn.frame = CGRectMake(self.mapView.frame.size.width - 40 - 10, self.mapView.frame.size.height - 40 - 10, 40, 40);
    locationBtn.backgroundColor = [UIColor redColor];
    [locationBtn setTitle: @"定位" forState:UIControlStateNormal];
    [locationBtn setTitle: @"被点击" forState: UIControlStateSelected];
    [locationBtn addTarget: self action: @selector(locationAction:) forControlEvents: UIControlEventTouchUpInside];
    
    [self.mapView addSubview: locationBtn];
    
    //  添加底部显示部分
    UIView *bottomView = [[UIView alloc] initWithFrame: CGRectMake(0, HEIGHT -64 - 50, WIDTH, 50)];
    bottomView.alpha = 0.5;
    bottomView.backgroundColor = [UIColor cyanColor];
    [self.view addSubview: bottomView];
    
    self.showRouteInfoLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, bottomView.frame.size.width ,  bottomView.frame.size.height)];
    self.showRouteInfoLabel.text =  @"显示路径信息";
    self.showRouteInfoLabel.textAlignment = 1;
    [bottomView addSubview: self.showRouteInfoLabel];
    
    //  添加Segment部分
    NSArray *titleArr = @[@"最短时间", @"躲避拥堵", @"最短路程", @"少走高速"];
    self.segment = [[UISegmentedControl alloc] initWithItems: titleArr];
    self.segment.frame = CGRectMake(0, 0, WIDTH, 40);
    [self.segment addTarget: self action: @selector(segmentAction:) forControlEvents: UIControlEventValueChanged];
    [self.view addSubview: self.segment];
    
}



#pragma mark ---------------------触发事件-------------------------------
//  按钮事件
- (void)backAction
{
    if (self.returnBlock) {
        self.returnBlock(nil);
    }
    
    [self dismissViewControllerAnimated: NO completion: nil];
}

- (void)returnValue: (returnValueBlock)returnvalueBlock
{
    self.returnBlock = returnvalueBlock;
}

- (void)rightBtnAction
{
    if (self.returnBlock) {
        NSArray *arr = @[showCostDistance,showCostTime];
        self.returnBlock(arr);
    }
    [self dismissViewControllerAnimated: NO completion: nil];
}

- (void)segmentAction: (UISegmentedControl *)segment
{
//    NSLog(@"----%ld",(long)segment.selectedSegmentIndex);
    switch (segment.selectedSegmentIndex) {
        case 0:
        {
            self.routeOption.drivingPolicy = BMK_DRIVING_TIME_FIRST;

        }
            break;
        case 1:
        {
            self.routeOption.drivingPolicy = BMK_DRIVING_BLK_FIRST;
        }
            break;
        case 2:
        {
            self.routeOption.drivingPolicy = BMK_DRIVING_DIS_FIRST;
        }
            break;
        case 3:
        {
            self.routeOption.drivingPolicy = BMK_DRIVING_FEE_FIRST;
        }
            break;
        
        default:
            break;
    }
    
    [self driverSearchWithRouteOption: self.routeOption];
    
}

- (void)locationAction: (UIButton *)sender
{

    if (sender.selected) {
        NSLog(@"进入罗盘状态");
        self.mapView.showsUserLocation = NO;
        self.mapView.userTrackingMode = BMKUserTrackingModeFollow;
        self.mapView.showsUserLocation = YES;
        
    } else {
        NSLog(@"进入跟随状态");
        [sender setTitle: @"第一次" forState: 0];
        self.mapView.showsUserLocation = NO;
        self.mapView.userTrackingMode = BMKUserTrackingModeFollowWithHeading;
        self.mapView.showsUserLocation = YES;
        
        self.mapView.frame = CGRectMake(0, 0, WIDTH, HEIGHT - 64 - 40);
    }
    sender.selected = !sender.selected;
}

//  设置驾车路径
- (void)setPlanRoute
{
    
    //发起检索
    BMKPlanNode *startPlace = [[BMKPlanNode alloc] init];
    startPlace.name = @"凯威大厦";
    startPlace.cityName = @"西安市";
    
    BMKPlanNode *endPlace = [[BMKPlanNode alloc] init];
    endPlace.name = @"汉台区";
    endPlace.cityName = @"汉中市";
    
//    NSArray *routeArray = [NSArray arrayWithObjects:startPlace, endPlace, nil];
    
    self.routeOption = [[BMKDrivingRoutePlanOption alloc] init];
//    driveRouteOption.wayPointsArray = routeArray;
    self.routeOption.from = startPlace;
    self.routeOption.to = endPlace;
    self.routeOption.drivingRequestTrafficType = BMK_DRIVING_REQUEST_TRAFFICE_TYPE_PATH_AND_TRAFFICE;
    
    //  驾车查询

    
    //  实际距离查询
//    BMKMapPoint point1 = BMKMapPointForCoordinate(CLLocationCoordinate2DMake(39.915,116.404));
//    BMKMapPoint point2 = BMKMapPointForCoordinate(CLLocationCoordinate2DMake(38.915,115.404));
//    CLLocationDistance distance = BMKMetersBetweenMapPoints(point1,point2);
//    NSLog(@"距离:%f",distance);
    
}


//  驾车查询
- (void)driverSearchWithRouteOption: (BMKDrivingRoutePlanOption *)drivingRoutePlanOption
{
    BOOL flag = [self.routeSearch drivingSearch: drivingRoutePlanOption];
    
    if (flag) {
        NSLog(@"驾车路线索引成功");
    } else {
        NSLog(@"驾车路线索引失败");
    }
}


//根据polyline设置地图范围（作为矩形显示在当前mapview）
- (void)mapViewFitPolyLine:(BMKPolyline *) polyLine {
    CGFloat ltX, ltY, rbX, rbY;
    if (polyLine.pointCount < 1) {
        return;
    }
    BMKMapPoint pt = polyLine.points[0];
    ltX = pt.x, ltY = pt.y;
    rbX = pt.x, rbY = pt.y;
    for (int i = 1; i < polyLine.pointCount; i++) {
        BMKMapPoint pt = polyLine.points[i];
        if (pt.x < ltX) {
            ltX = pt.x;
        }
        if (pt.x > rbX) {
            rbX = pt.x;
        }
        if (pt.y > ltY) {
            ltY = pt.y;
        }
        if (pt.y < rbY) {
            rbY = pt.y;
        }
    }
    BMKMapRect rect;
    rect.origin = BMKMapPointMake(ltX , ltY);
    rect.size = BMKMapSizeMake(rbX - ltX, rbY - ltY);
    [_mapView setVisibleMapRect:rect];
    _mapView.zoomLevel = _mapView.zoomLevel - 0.3;
}

- (NSString *)getMyBundlePath: (NSString *)filename
{
    NSBundle *libBundle = MYBUNDLE;
    if (libBundle && filename) {
        NSString *path = [[libBundle resourcePath] stringByAppendingPathComponent: filename];
        return path;
    }
    return nil;
}

//  返回各个不同类型节点的大头针
- (BMKAnnotationView *)getRouteAnnotationView: (BMKMapView *)mapview viewForAnnotation: (RouteAnnotation *)routeAnnotation
{
    BMKAnnotationView *view = nil;
    switch (routeAnnotation.type) {
        case 0:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier: @"start_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc] initWithAnnotation: routeAnnotation reuseIdentifier: @"start_node"];
                view.image = [UIImage imageWithContentsOfFile: [self getMyBundlePath: @"images/icon_nav_start.png"]];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = TRUE;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 1:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier: @"end_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc] initWithAnnotation:routeAnnotation reuseIdentifier: @"end_node"];
                view.image = [UIImage imageWithContentsOfFile: [self getMyBundlePath: @"images/icon_nav_end.png"]];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = true;
                view.annotation = routeAnnotation;
            }
        }
            break;
        case 4:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"route_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"route_node"];
                view.canShowCallout = TRUE;
            } else {
                [view setNeedsDisplay];
            }
            
            UIImage* image = [UIImage imageWithContentsOfFile:[self getMyBundlePath:@"images/icon_direction.png"]];
            view.image = [image imageRotatedByDegrees:routeAnnotation.degree];
            view.annotation = routeAnnotation;
            
        }
            break;
        case 5:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"waypoint_node"];
            if (view == nil) {
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"waypoint_node"];
                view.canShowCallout = TRUE;
            } else {
                [view setNeedsDisplay];
            }
            
            UIImage* image = [UIImage imageWithContentsOfFile:[self getMyBundlePath:@"images/icon_nav_waypoint.png"]];
            view.image = [image imageRotatedByDegrees:routeAnnotation.degree];
            view.annotation = routeAnnotation;
        }
            break;
            
        default:
            break;
    }
    
    return view;
}

#pragma mark ---------------------路线查询Delegate-------------------------------
/**
 *返回驾乘搜索结果
 *@param searcher 搜索对象
 *@param result 搜索结果，类型为BMKDrivingRouteResult
 *@param error 错误号，@see BMKSearchErrorCode
 */
- (void)onGetDrivingRouteResult:(BMKRouteSearch*)searcher result:(BMKDrivingRouteResult*)result errorCode:(BMKSearchErrorCode)error
{
    [self.mapView removeAnnotations: [NSArray arrayWithArray: self.mapView.annotations]];
    [self.mapView removeOverlays: [NSArray arrayWithArray: self.mapView.overlays]];
    
    if (error == BMK_SEARCH_NO_ERROR) {
        NSLog(@"索引成功: %@",result);
        //在此处理正常结果

        BMKDrivingRouteLine *plan = (BMKDrivingRouteLine *)[result.routes objectAtIndex: 0];
        
//        NSLog(@"路径长度: %d米",plan.distance);
//        NSLog(@"耗时:%d",plan.duration.minutes);
//        NSLog(@"耗时:%d",plan.duration.hours);
//        NSLog(@"起点名称: %@",plan.starting.title);
//        NSLog(@"终点名称: %@",plan.terminal.title);
        
        //  判断路径
        if (plan.distance < 1000) {
            showCostDistance = [NSString stringWithFormat: @"%d米",plan.distance];
        } else if (plan.distance >= 1000) {
            CGFloat distance = (CGFloat)plan.distance / 1000;
            showCostDistance = [NSString stringWithFormat: @"%.1f公里",distance];
        }
        
        //  判断耗时
        if (plan.duration.hours == 0) {
            showCostTime = [NSString stringWithFormat: @"%d分钟",plan.duration.minutes];
        } else if (plan.duration.hours > 0) {
            showCostTime = [NSString stringWithFormat: @"%d小时%d分",plan.duration.hours, plan.duration.minutes];
        }
        
//        NSLog(@"真实距离: %@",showCostDistance);
//        NSLog(@"预估时长: %@",showCostTime);
        self.showRouteInfoLabel.text = [NSString stringWithFormat: @"预估时长:%@   实际距离:%@",showCostTime, showCostDistance];
        
        //  计算路线方案的路段数目
        NSInteger size = [plan.steps count];
        int planPointCounts = 0;
        for (int i = 0; i < size; i++) {
            BMKDrivingStep *transitStep = [plan.steps objectAtIndex: i];
            if (i == 0) {
                RouteAnnotation *item = [[RouteAnnotation alloc] init];
                item.coordinate = plan.starting.location;
                item.title = [NSString stringWithFormat: @"起点:%@",plan.starting.title];
                item.type = 0;
                [self.mapView addAnnotation: item];
            } else if(i == size - 1) {
                RouteAnnotation *item = [[RouteAnnotation alloc] init];
                item.coordinate = plan.terminal.location;
                item.title = [NSString stringWithFormat: @"终点:%@",plan.terminal.title];
                item.type = 1;
                [self.mapView addAnnotation: item];
            }
            
            //添加annotation节点
            RouteAnnotation *item = [[RouteAnnotation alloc] init];
            item.coordinate = transitStep.entrace.location;
            item.title = transitStep.entraceInstruction;
            NSLog(@"途径节点: %@",item.title);
            item.degree = transitStep.direction * 30;
            item.type = 4;
            [self.mapView addAnnotation: item];
            
            planPointCounts += transitStep.pointsCount;
        }
        
        //添加路径点
        if (plan.wayPoints) {
            for (BMKPlanNode *tempNode in plan.wayPoints) {
                RouteAnnotation *item = [[RouteAnnotation alloc] init];
                item.coordinate = tempNode.pt;
                item.title = tempNode.name;
                item.type = 5;
                [self.mapView addAnnotation: item];
            }
        }
        
        
        //轨迹点(这是个结构体数组)
        BMKMapPoint *temppoints = new BMKMapPoint[planPointCounts];

        int i = 0;
        for (int j = 0; j < size; j++) {
            BMKDrivingStep* transitStep = [plan.steps objectAtIndex: j];
            int k = 0;
            for (k = 0; k < transitStep.pointsCount; k++) {
                temppoints[i].x = transitStep.points[k].x;
                temppoints[i].y = transitStep.points[k].y;
//                NSLog(@"x:%f y:%f",temppoints[i].x, temppoints[i].y);
                i++;
            }
        }
        
        //通过points构建BMKPolyline
        BMKPolyline *polyLine = [BMKPolyline polylineWithPoints: temppoints count: planPointCounts];
        [self.mapView addOverlay: polyLine];
        
        delete [] temppoints;
        
        [self mapViewFitPolyLine: polyLine];
        
    } else if (error == BMK_SEARCH_AMBIGUOUS_ROURE_ADDR){
        NSLog(@"地址有歧义");
    } else{
        NSLog(@"抱歉未找到结果");
    }
}









#pragma mark ---------------------MapViewDelegate-----------------
/**
 *地图初始化完毕时会调用此接口
 *@param mapview 地图View
 */
- (void)mapViewDidFinishLoading:(BMKMapView *)mapView
{
    [self.mapView setCompassPosition: CGPointMake(20, 20)];
}

//  路径颜色
- (BMKOverlayView*)mapView:(BMKMapView *)map viewForOverlay:(id<BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        //  填充颜色
        polylineView.fillColor = [[UIColor alloc] initWithRed:0 green:1 blue:1 alpha:1];
        //  画笔颜色
        polylineView.strokeColor = [[UIColor alloc] initWithRed:0 green:0 blue:1 alpha:0.7];
        polylineView.lineWidth = 4.0;
        return polylineView;
    }
    return nil;
}

//  大头针显示
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation
{
    if ([annotation isKindOfClass: [RouteAnnotation class]]) {
        return [self getRouteAnnotationView: self.mapView viewForAnnotation: (RouteAnnotation *)annotation];
    }
    return nil;
}








#pragma mark ---------------------定位Delegate-------------------------------

- (void)didFailToLocateUserWithError:(NSError *)error
{
    NSLog(@"定位失败: %@",error);
}

- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation
{
    NSLog(@"定位方向发生变化");
    [self.mapView updateLocationData: userLocation];
//    self.mapView.centerCoordinate = userLocation.location.coordinate;

}
//  获取当前位置
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    NSLog(@"获取当前位置");

    [self.mapView updateLocationData: userLocation];
    //  显示圆圈
//    self.mapView.centerCoordinate = userLocation.location.coordinate;
//    
//    [self.service stopUserLocationService];
}

@end
