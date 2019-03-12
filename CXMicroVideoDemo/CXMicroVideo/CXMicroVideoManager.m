//
//  CXMicroVideoManager.m
//  CXMicroVideoDemo
//
//  Created by chennq on 2019/3/12.
//  Copyright © 2019 chennq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CXMicroVideoManager.h"
#import "UIViewController+CurrentVC.h"
#import "CXRecordVideoViewController.h"
#import "CXPresentTransitionAnimated.h"

@interface CXMicroVideoManager()<UIViewControllerTransitioningDelegate>

@end

@implementation CXMicroVideoManager

#pragma mark - init
+ (instancetype)shareManager {
    static CXMicroVideoManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CXMicroVideoManager new];
    });
    return manager;
}

#pragma mark - Actions
/**
 使用默认值开始录制
 
 @param finishBlock 完成回调
 */
- (void)startVideoRecordFinish:(CXMVRecordFinishBlock)finishBlock {
    CXMicroVideoOptions *defaultOptions = [[CXMicroVideoOptions alloc] init];
    [self startVideoRecordWithOptions:defaultOptions finish:finishBlock];
}

/**
 使用自定义配置开始录制
 
 @param options 配置项
 @param finishBlock 完成回调
 */
- (void)startVideoRecordWithOptions:(CXMicroVideoOptions *)options finish:(CXMVRecordFinishBlock)finishBlock {
#if TARGET_IPHONE_SIMULATOR
#else
    UIViewController *currentVC = [UIViewController getCurrentVC];
    CXRecordVideoViewController *recordVC = [[CXRecordVideoViewController alloc] initWithOptions:options];
    recordVC.finishBlock = finishBlock;
    UINavigationController *recordNav = [[UINavigationController alloc] initWithRootViewController:recordVC];
    recordNav.transitioningDelegate = self;
    [currentVC presentViewController:recordNav animated:YES completion:nil];
#endif
}

#pragma Mark - UIViewControllerTransitioningDelegate
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [[CXPresentTransitionAnimated alloc] init];
}

@end
