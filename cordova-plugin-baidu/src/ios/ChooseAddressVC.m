//
//  ChooseAddressVC.m
//  FangZheBa
//
//  Created by lesong on 16/6/22.
//  Copyright © 2016年 LeSongKeJi. All rights reserved.
//

#import "ChooseAddressVC.h"


#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Base/BMKBaseComponent.h>
#import <BaiduMapAPI_Location/BMKLocationComponent.h>
// 大头针
#import <BaiduMapAPI_Map/BMKPointAnnotation.h>
#import <BaiduMapAPI_Map/BMKPinAnnotationView.h>
#import <BaiduMapAPI_Map/BMKAnnotation.h>
#import <BaiduMapAPI_Search/BMKGeocodeSearchOption.h>
#import <BaiduMapAPI_Search/BMKGeocodeSearch.h>

#define ZhuSe [UIColor whiteColor]
#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height


@interface ChooseAddressVC ()<BMKMapViewDelegate, BMKLocationServiceDelegate, BMKGeoCodeSearchDelegate>

@property (nonatomic, strong) BMKMapView *mapView;

@property (nonatomic, strong) BMKLocationService *service;

@property (nonatomic, strong) BMKGeoCodeSearch *serach;

@property (nonatomic, strong) UILabel *showLabel;

@end



@implementation ChooseAddressVC
{
    NSString *chooseAddress;
    CLLocationCoordinate2D addressCoordinate;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNavigationOptions];
//
    [self setMapUIOptions];
    
    [self setOtherUIOptions];
    
    [self createAlertController];
}

- (void)createAlertController
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"标记提示" message: @"请长按地图位置确定位置" preferredStyle: 1];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle: @"确定" style: 1 handler: nil];
    [alert addAction: action];
    [self presentViewController: alert animated: NO completion: nil];
}


#pragma mark 设置UINavigationItem的属性
- (void)setNavigationOptions
{
    self.title = @"位置选择";
    
    self.navigationController.navigationBar.barTintColor = ZhuSe;
    
    UIButton *backBtn = [UIButton buttonWithType: UIButtonTypeCustom];
//    [backBtn setBackgroundImage: [UIImage imageNamed: @"back_icon"] forState: UIControlStateNormal];
    [backBtn setTitle: @"返回" forState: 0];
    [backBtn setTitleColor: [UIColor cyanColor] forState: 0];
    backBtn.frame = CGRectMake(0, 0, 40, 40);
    [backBtn addTarget: self action: @selector(backBtnAction) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *leftBBI = [[UIBarButtonItem alloc]initWithCustomView: backBtn];
    self.navigationItem.leftBarButtonItem = leftBBI;
    
    UIButton *chooseBtn = [UIButton buttonWithType: UIButtonTypeCustom];
//    [chooseBtn setBackgroundImage: [UIImage imageNamed: @"ok_icon"] forState: UIControlStateNormal];
    [chooseBtn setTitle: @"保存" forState: 0];
    [chooseBtn setTitleColor: [UIColor cyanColor] forState: 0];
    chooseBtn.frame = CGRectMake(0, 0, 40, 40);
    [chooseBtn addTarget: self action: @selector(chooseBtnAction) forControlEvents: UIControlEventTouchUpInside];
    
    UIBarButtonItem *rightBBI = [[UIBarButtonItem alloc] initWithCustomView: chooseBtn];
    self.navigationItem.rightBarButtonItem = rightBBI;
    
}

//  左按钮
- (void)backBtnAction
{
    [self dismissViewControllerAnimated: NO completion: nil];
//    [self.navigationController popViewControllerAnimated: NO];
}

//  右按钮
- (void)chooseBtnAction
{
    if (chooseAddress.length > 0) {
        [self.delegate reutrnCollectionInfoWithAddress: chooseAddress LocationCoordinate: addressCoordinate];
        [self backBtnAction];
    } else {
        [self createAlertControllerwithTitle: @"选择地址有误" message: nil style: 1];
    }
}




#pragma mark 创建UI
- (void)setMapUIOptions
{
    self.mapView = [[BMKMapView alloc] initWithFrame: CGRectMake(0, 64, WIDTH, HEIGHT - 64)];
    [self.view addSubview: self.mapView];
    
    self.mapView.delegate = self;
    [self.mapView setMapType: BMKMapTypeStandard];
    [self.mapView setTrafficEnabled: YES];
    self.mapView.zoomLevel = 16;    //200米
    self.mapView.rotateEnabled = YES;
    self.mapView.zoomLevel = YES;
    self.mapView.scrollEnabled = YES;
    self.mapView.showMapScaleBar = YES;
    
//  获取一次当前的位置
    self.service = [[BMKLocationService alloc] init];
    self.service.delegate = self;
    [self.service startUserLocationService];
    
//  添加手势
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(longPressAction:)];
    [self.mapView addGestureRecognizer: longPress];
}


#pragma mark service的代理方法
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    NSLog(@"获取当前位置");
    self.mapView.userTrackingMode = BMKUserTrackingModeNone;
    self.mapView.showsUserLocation = YES;
    [self.mapView updateLocationData: userLocation];
    self.mapView.centerCoordinate = userLocation.location.coordinate;
    self.mapView.zoomLevel = 16;
    [self.service stopUserLocationService];
}



#pragma mark 添加其他控件
- (void)setOtherUIOptions
{
//  定位按钮
    UIButton *locationBtn = [UIButton buttonWithType: UIButtonTypeCustom];
    [locationBtn setBackgroundImage: [UIImage imageNamed: @"location_my_local_icon"] forState: 0];
    locationBtn.frame =  CGRectMake(WIDTH - 60, HEIGHT - 60, 50, 50);
    [locationBtn addTarget: self action: @selector(locationAction) forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview: locationBtn];
    
    UIView *view = [[UIView alloc] initWithFrame: CGRectMake(0, 64, WIDTH, 1)];
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview: view];
    
//  显示
    self.showLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 65, WIDTH, 40)];
    self.showLabel.backgroundColor = ZhuSe;
    self.showLabel.textAlignment = 1;
    self.showLabel.textColor = [UIColor grayColor];
    self.showLabel.font = [UIFont systemFontOfSize: 16];
    self.showLabel.text = @"您选择的位置";
    [self.view addSubview: self.showLabel];
}
//  定位按钮
- (void)locationAction
{
    [self.service startUserLocationService];
}



#pragma mark 长按手势
- (void)longPressAction: (UILongPressGestureRecognizer *)longPress
{
//  取消原来的大头针
    [self.mapView removeAnnotations: self.mapView.annotations];
    
    CGPoint touchPoint = [longPress locationInView: self.mapView];
    //将视图上的长按点转化为经纬度
    CLLocationCoordinate2D touchMapViewCoordinate = [self.mapView convertPoint: touchPoint toCoordinateFromView: self.mapView];
    
    //添加大头针
    BMKPointAnnotation *anno = [[BMKPointAnnotation alloc] init];
    anno.coordinate = touchMapViewCoordinate;
    anno.title = @"您选中的位置";
    [self.mapView addAnnotation: anno];
    
//  geo反向地理编码索引
    if (longPress.state == UIGestureRecognizerStateEnded) {
        [self searchGeoAddressWithCoodrinate: touchMapViewCoordinate];
    }
}


#pragma mark MapView的代理方法
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation
{
    BMKPinAnnotationView *annotationView = [[BMKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: nil];
    annotationView.pinColor = BMKPinAnnotationColorRed;
    annotationView.canShowCallout = YES;
    return annotationView;
}

#pragma mark 反向地理编码
- (void)searchGeoAddressWithCoodrinate: (CLLocationCoordinate2D) pt
{
    _serach = [[BMKGeoCodeSearch alloc] init];
    _serach.delegate = self;
    
    BMKReverseGeoCodeOption *option = [[BMKReverseGeoCodeOption alloc] init];
    option.reverseGeoPoint = pt;
    BOOL flag = [_serach reverseGeoCode: option];
    
    if (flag) {
        NSLog(@"反geo检索发送成功");
    } else {
        NSLog(@"反geo检索失败");
    }
}

#pragma mark 反地理编码代理方法
- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == BMK_SEARCH_NO_ERROR) {
        NSLog(@"结果地理位置: %@",result.address);
        chooseAddress = result.address;
        addressCoordinate = result.location;
        self.showLabel.text = result.address;
    } else {
        NSLog(@"抱歉，未找到结果");
    }
}


// 工具方法============================================================
#pragma mark 显示提示框
- (void)createAlertControllerwithTitle: (NSString *)title
                               message: (NSString *)message
                                 style: (NSInteger )style
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title message: message preferredStyle: style];
    [self presentViewController: alertController animated: NO completion: nil];
    //多线程添加延迟
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated: NO completion: nil];
    });
}


@end
