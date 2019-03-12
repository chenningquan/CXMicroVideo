//
//  CXRecordVideoViewController.h
//  NIM
//
//  Created by chennq on 2018/4/13.
//  Copyright © 2018年 chennq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CXMicroVideoManager.h"

@interface CXRecordVideoViewController : UIViewController

/**
 初始化录制控制器

 @param options 录制参数配置
 */
- (instancetype)initWithOptions:(CXMicroVideoOptions *)options;

/**
 录制完成回调
 */
@property (nonatomic, copy) CXMVRecordFinishBlock finishBlock;

@end
