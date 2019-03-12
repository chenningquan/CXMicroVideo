//
//  CXMicroVideoOptions.h
//  CXMicroVideoDemo
//
//  Created by chennq on 2019/3/12.
//  Copyright © 2019 chennq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface CXMicroVideoOptions : NSObject

/**
 输出文件路径(默认Document/CXMicroVideo目录)
 */
@property (nonatomic, copy) NSString *outPutDirPath;

/**
 输出文件名称(默认文件MD5)
 */
@property (nonatomic, copy) NSString *fileName;

/**
 最长录制时间(默认十秒)
 */
@property (nonatomic, assign) NSInteger maxRecordTime;

/**
 录制视频的分辨率(默认AVCaptureSessionPreset1280x720)
 */
@property (nonatomic, assign) AVCaptureSessionPreset preset;

/**
 录制视频宽度(默认720)
 */
@property (nonatomic, assign) NSInteger videoWidth;

/**
 录制视频高度(默认1280)
 */
@property (nonatomic, assign) NSInteger videoHeight;

/**
 视频码率和帧率设置 默认设置如下：
 @{
 AVVideoAverageBitRateKey : @(5 * videoWidth * videoHeight),
 AVVideoExpectedSourceFrameRateKey : @(15),
 AVVideoMaxKeyFrameIntervalKey : @(15),
 AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel }
 */
@property (nonatomic, copy) NSDictionary *videoBitsAndFrameRateSettings;

/**
 视频压缩设置 默认配置如下：
 @{ AVVideoCodecKey : AVVideoCodecH264,
 AVVideoWidthKey : @(videoWidth),
 AVVideoHeightKey : @(videoHeight),
 AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
 AVVideoCompressionPropertiesKey : videoBitsAndFrameRateSettings }
 */
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;

/**
 音频压缩配置 默认配置如下:
 @{ AVEncoderBitRatePerChannelKey : @(28000),
 AVFormatIDKey : @(kAudioFormatMPEG4AAC),
 AVNumberOfChannelsKey : @(1),
 AVSampleRateKey : @(22050) }
 */
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;
@end

