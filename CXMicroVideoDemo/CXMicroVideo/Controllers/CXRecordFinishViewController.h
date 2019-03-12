//
//  CXRecordFinishViewController.h
//  NIM
//
//  Created by chennq on 2018/4/16.
//  Copyright © 2018年 chennq. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "CXMicroVideoManager.h"

@interface CXRecordFinishViewController : UIViewController

//本地视频路径
@property (nonatomic, copy) NSURL *videoUrl;

@property (nonatomic, copy) CXMVRecordFinishBlock finishBlock;

@end
