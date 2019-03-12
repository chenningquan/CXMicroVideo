//
//  CXMicroVideoOptions.m
//  CXMicroVideoDemo
//
//  Created by chennq on 2019/3/12.
//  Copyright © 2019 chennq. All rights reserved.
//

#import "CXMicroVideoOptions.h"

@implementation CXMicroVideoOptions

- (instancetype)init {
    if (self = [super init]) {
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *defaultDirPath = [documentPath stringByAppendingString:@"/CXMicroVideo"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:defaultDirPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:defaultDirPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        self.outPutDirPath = defaultDirPath;
        self.maxRecordTime = 10;
        self.preset = AVCaptureSessionPreset1280x720;
        self.videoWidth = 720;
        self.videoHeight = 1280;
        self.videoBitsAndFrameRateSettings = @{
                                               AVVideoAverageBitRateKey : @(5 * self.videoWidth * self.videoHeight),
                                               AVVideoExpectedSourceFrameRateKey : @(15),
                                               AVVideoMaxKeyFrameIntervalKey : @(15),
                                               AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
        self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                           AVVideoWidthKey : @(self.videoWidth),
                                           AVVideoHeightKey : @(self.videoHeight),
                                           AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                           AVVideoCompressionPropertiesKey : self.videoBitsAndFrameRateSettings };
        self.audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
                                           AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                           AVNumberOfChannelsKey : @(1),
                                           AVSampleRateKey : @(22050) };
    }
    return self;
}
@end
