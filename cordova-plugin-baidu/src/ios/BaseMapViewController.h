//
//  BaseMapViewController.h
//  example
//
//  Created by xudesong on 16/9/19.
//
//

#import <UIKit/UIKit.h>

//创建block
typedef void (^returnValueBlock)(NSArray *contentArr);


@interface BaseMapViewController : UIViewController


@property(nonatomic, copy) returnValueBlock returnBlock;

- (void)returnValue: (returnValueBlock)returnvalueBlock;

@end
