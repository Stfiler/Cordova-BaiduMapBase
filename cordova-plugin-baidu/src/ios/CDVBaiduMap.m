//
//  CDVBaiduMap.m
//  HelloCordova
//
//  Created by xudesong on 16/9/18.
//
//

#import "CDVBaiduMap.h"
#import <Cordova/CDV.h>

//跟百度相关的头文件
#import <BaiduMapAPI_Base/BMKMapManager.h>
#import <BaiduMapAPI_Base/BMKBaseComponent.h>
#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
//跳转页面
#import "BaseMapViewController.h"

#import "ChooseAddressVC.h"

@interface CDVBaiduMap ()<ChooseAddressDelegate, BMKGeoCodeSearchDelegate>


@end

@implementation CDVBaiduMap
{
    CDVInvokedUrlCommand *chooseCommand;
    BMKGeoCodeSearch *_search;
}


- (void)initBaiDu: (CDVInvokedUrlCommand *)command
{
     NSLog(@"获得ak：%@",[command.arguments objectAtIndex: 0]);
    
    NSString *appkey = [command.arguments objectAtIndex: 0];
    
    BMKMapManager *manager = [[BMKMapManager alloc]init];
    
    CDVPluginResult *result = nil;
    
    BOOL ret = [manager start: appkey generalDelegate: nil];
    
    if (!ret) {
        result = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString: @"百度地图初始化失败"];
    } else {
        result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: @"百度地图初始化成功"];
    }
    [self.commandDelegate sendPluginResult: result callbackId: command.callbackId];
    
}

- (void)enterMapView: (CDVInvokedUrlCommand *)command
{
    NSLog(@"获得传入过来的数据: %@",[command.arguments objectAtIndex: 0]);
    
    //  将这些数据传入到(路线规划的视图控制器里面)
    
    BaseMapViewController *mapVC = [[BaseMapViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController: mapVC];
    
    [mapVC returnValue:^(NSArray *resultArr){
        NSLog(@"原生返回结果:%@",resultArr);
        CDVPluginResult *result = nil;
        if (resultArr) {
            result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsArray: resultArr];
        } else {
            result = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString: @"获取路线信息失败"];
        }
        [self.commandDelegate sendPluginResult: result callbackId: command.callbackId];
    }];
    
    [self.viewController presentViewController: nav animated: NO completion: nil];
}

- (void)chooseLocation: (CDVInvokedUrlCommand *)command
{
//    NSLog(@"原生选择地点");
    chooseCommand = command;
    
    ChooseAddressVC *chooseVC = [[ChooseAddressVC alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController: chooseVC];
    chooseVC.delegate = self;
    [self.viewController presentViewController: nav animated: NO completion: nil];
}

- (void)reutrnCollectionInfoWithAddress:(NSString *)address LocationCoordinate:(CLLocationCoordinate2D)location
{
    CDVPluginResult *result = nil;
    if (address) {
        NSString *jindu = [NSString stringWithFormat: @"%f",location.longitude];
        NSString *weidu = [NSString stringWithFormat: @"%f",location.latitude];
        NSArray *resultArr = @[address,jindu,weidu];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray: resultArr];
        [self.commandDelegate sendPluginResult: result callbackId: chooseCommand.callbackId];
    }
}


//  根据传入的两个位置的经纬度来获取两地的实际距离
- (void)getRealDistanceFromTwoPlace: (CDVInvokedUrlCommand *)command
{
    //  这里建议传入一个数组，包括两地的经纬度来代替下面的测试数据
    NSLog(@"传入的信息:%@",[command.arguments objectAtIndex: 0]);
    
    //  这里暂时定为传入的参数作为一个数组，然后从这个数组里面提取出两个点位置的经纬度(下面的数据是我用来测试的)
    
    BMKMapPoint point1 = BMKMapPointForCoordinate(CLLocationCoordinate2DMake(39.915, 116.404));
    BMKMapPoint point2 = BMKMapPointForCoordinate(CLLocationCoordinate2DMake(39.915, 115.404));
    //  计算两地的实际距离
    CLLocationDistance distance = BMKMetersBetweenMapPoints(point1, point2);
    
    NSLog(@"两地的距离是:%f",distance);
    
    NSString *resultDistance = [NSString stringWithFormat:@"%f",distance];
    //将数据返回给JS
    CDVPluginResult *result = nil;
    if (resultDistance) {
        result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: resultDistance];
    } else {
        result = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString: @"获取距离失败"];
    }
    [self.commandDelegate sendPluginResult: result callbackId: command.callbackId];
}

//  正向地理编码(出入参数为位置名称)
- (void)getLocationCoordinate2DInfo: (CDVInvokedUrlCommand *)command
{
    //这里需要传入城市名称，以及地理位置名称,建议传入数组来代替下面的测试数据
    NSLog(@"传入的信息:%@",[command.arguments objectAtIndex: 0]);
    
    _search = [[BMKGeoCodeSearch alloc] init];
    _search.delegate = self;
    BMKGeoCodeSearchOption *geocodeSearchOption = [[BMKGeoCodeSearchOption alloc]init];
    geocodeSearchOption.city= @"北京市";
    geocodeSearchOption.address = @"海淀区上地10街10号";
    if ([_search geoCode: geocodeSearchOption]) {
        NSLog(@"geo索引发送成功");
    } else {
        NSLog(@"geo索引发送失败");
    }
}

- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == BMK_SEARCH_NO_ERROR) {
        NSLog(@"结果纬度:%f",result.location.latitude);
        NSLog(@"结果经度:%f",result.location.latitude);
        NSLog(@"位置信息:%@",result.address);
    } else {
        NSLog(@"抱歉，未找到结果");
    }
}


//  反向地理编码(传入参数为经纬度)
- (void)getLocationInfo: (CDVInvokedUrlCommand *)command
{
    NSLog(@"传入的信息:%@",[command.arguments objectAtIndex: 0]);
    //这里需要传入该地的经纬度，应该为数组数据来代替下面的测试数据
    
    _search = [[BMKGeoCodeSearch alloc] init];
    _search.delegate = self;
    CLLocationCoordinate2D pt = (CLLocationCoordinate2D){39.915, 116.404};
    BMKReverseGeoCodeOption *option = [[BMKReverseGeoCodeOption alloc] init];
    option.reverseGeoPoint = pt;
    if ([_search reverseGeoCode: option]) {
        NSLog(@"反geo索引发送成功");
    } else {
        NSLog(@"反geo索引发送失败");
    }
}

- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == BMK_SEARCH_NO_ERROR) {
        NSLog(@"结果纬度:%f",result.location.latitude);
        NSLog(@"结果经度:%f",result.location.latitude);
        NSLog(@"位置信息:%@",result.address);
    } else {
        NSLog(@"抱歉，未找到结果");
    }
}

@end
