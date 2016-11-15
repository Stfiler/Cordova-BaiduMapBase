//
//  ChooseAddressVC.h
//  FangZheBa
//
//  Created by lesong on 16/6/22.
//  Copyright © 2016年 LeSongKeJi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@protocol ChooseAddressDelegate <NSObject>

- (void)reutrnCollectionInfoWithAddress: (NSString *)address LocationCoordinate: (CLLocationCoordinate2D )location;

@end

@interface ChooseAddressVC : UIViewController

@property (nonatomic, assign) id <ChooseAddressDelegate> delegate;

@end
