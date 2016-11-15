//
//  CDVBaiduMap.h
//  HelloCordova
//
//  Created by xudesong on 16/9/18.
//
//


#import <Cordova/CDVPlugin.h>



@interface CDVBaiduMap : CDVPlugin 

//  使用百度地图的key来获得使用它的权限
- (void)initBaiDu: (CDVInvokedUrlCommand *)command;

//  进入路线规划的百度地图
- (void)enterMapView: (CDVInvokedUrlCommand *)command;

//  在百度地图选择位置然后返回经纬度，和未知名称
- (void)chooseLocation: (CDVInvokedUrlCommand *)command;

//  根据传入的两个位置的经纬度来获取两地的实际距离
- (void)getRealDistanceFromTwoPlace: (CDVInvokedUrlCommand *)command;

//  正向地理编码(出入参数为位置名称)
- (void)getLocationCoordinate2DInfo: (CDVInvokedUrlCommand *)command;

//  反向地理编码(传入参数为经纬度)
- (void)getLocationInfo: (CDVInvokedUrlCommand *)command;



@end
