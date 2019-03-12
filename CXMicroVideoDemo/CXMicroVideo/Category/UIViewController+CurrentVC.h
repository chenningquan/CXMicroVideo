//
//  UIViewController+CurrentVC.h
//  CXMicroVideoDemo
//
//  Created by chennq on 2019/3/12.
//  Copyright © 2019 chennq. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (CurrentVC)

/**
 获取当前显示的控制器
 */
+ (UIViewController *)getCurrentVC;

@end

NS_ASSUME_NONNULL_END
