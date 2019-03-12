//
//  CXMicroVideoManager.h
//  CXMicroVideoDemo
//
//  Created by chennq on 2019/3/12.
//  Copyright © 2019 chennq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CXMicroVideoOptions.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^CXMVRecordFinishBlock)(BOOL isSuccess, NSString *msg, NSString *filePath);

@interface CXMicroVideoManager : NSObject

/**
 单例方法
 */
+ (instancetype)shareManager;

/**
 使用默认值开始录制

 @param finishBlock 完成回调
 */
- (void)startVideoRecordFinish:(CXMVRecordFinishBlock)finishBlock;

/**
 使用自定义配置开始录制

 @param options 配置项
 @param finishBlock 完成回调
 */
- (void)startVideoRecordWithOptions:(CXMicroVideoOptions *)options finish:(CXMVRecordFinishBlock)finishBlock;

@end

NS_ASSUME_NONNULL_END
