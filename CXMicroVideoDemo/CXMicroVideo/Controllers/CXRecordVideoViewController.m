//
//  CXRecordVideoViewController.m
//  NIM
//
//  Created by chennq on 2018/4/13.
//  Copyright © 2018年 chennq. All rights reserved.
//

#import "CXRecordVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CXRecordFinishViewController.h"
#import <Masonry.h>

@interface CXRecordVideoViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
//视频录制相关属性
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureDevice *audioDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

//视频录制相关UI
@property (nonatomic, strong) UIView *bottomView; //底部View
@property (nonatomic, strong) UIView *recordView; //录像View
@property (nonatomic, strong) UIButton *recordButton; //录像按钮
@property (nonatomic, strong) UIButton *cancelButton; //取消按钮
@property (nonatomic, strong) UIButton *overTurnButton; //翻转摄像头按钮
@property (nonatomic, strong) UILabel *videoTypeLabel; //录制视频类型（默认显示小视频）
@property (nonatomic, strong) UILabel *recordToolLabel; //录像View上的label


//视频录制相关配置
@property (nonatomic, strong) CXMicroVideoOptions *options; //录制参数配置
@property (nonatomic, assign) float currentZoomFactor; //当前的摄像焦距
@property (nonatomic, assign) BOOL isRecording; //录制状态
@property (nonatomic, assign) NSInteger residueRecordTime; //剩余最大录制时间
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;
@property (nonatomic, assign) BOOL canWrite;
@property (nonatomic, strong) dispatch_queue_t videoQueue;

@end

@implementation CXRecordVideoViewController

#pragma mark - init
/**
 初始化录制控制器
 
 @param options 录制参数配置
 */
- (instancetype)initWithOptions:(CXMicroVideoOptions *)options {
    CXRecordVideoViewController *recordVC = [CXRecordVideoViewController new];
    recordVC.options = options;
    recordVC.currentZoomFactor = 1.0;
    recordVC.residueRecordTime = options.maxRecordTime;
    return recordVC;
}

#pragma mark - life Circle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    [self setupAVCapture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.isRecording = NO;
    [self.captureSession startRunning];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.captureSession stopRunning];
    [self updateStateOriginal];
    [self.recordButton setEnabled:YES];
    [self.cancelButton setEnabled:YES];
}

#pragma mark - function

- (void)setupAVCapture {
    [self addSubView];
    [self addSession];
    [self.captureSession beginConfiguration];
    
    [self addVideo];
    [self addAudio];
    [self addPreviewLayer];
    
    [self.captureSession commitConfiguration];
    
    //开启会话-->注意,不等于开始录制
    [self.captureSession startRunning];
}

- (void)addSession {
    self.captureSession = [[AVCaptureSession alloc] init];
    //设置视频分辨率
    /*  通常支持如下格式
     (
     AVCaptureSessionPresetLowQuality,
     AVCaptureSessionPreset640x480,
     AVCaptureSessionPresetMediumQuality,
     AVCaptureSessionPreset1920x1080,
     AVCaptureSessionPreset1280x720,
     AVAssetExportPresetHighestQuality,
     AVAssetExportPresetAppleM4A
     )
     */
    //注意,这个地方设置的模式/分辨率大小将影响你后面拍摄照片/视频的大小,
    
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [self.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    
    
    
}

- (void)addVideo {
    
    self.videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
    
    [self addVideoInput];
    [self addMovieOutput];
}

//获取摄像头-->前/后
- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

- (void)addVideoInput {
    NSError *videoError;
    
    // 视频输入对象
    // 根据输入设备初始化输入对象，用户获取输入数据
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoDevice error:&videoError];
    if (videoError) {
        NSLog(@"---- 取得摄像头设备时出错 ------ %@",videoError);
        return;
    }
    
    // 将视频输入对象添加到会话 (AVCaptureSession) 中
    if ([self.captureSession canAddInput:self.videoInput]) {
        [self.captureSession addInput:self.videoInput];
    }
}

- (void)addMovieOutput {
    // 拍摄视频输出对象
    // 初始化输出设备对象，用户获取输出数据
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES; //立即丢弃旧帧，节省内存，默认YES
    
    [self.videoOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if ([self.captureSession canAddOutput:self.videoOutput])
    {
        [self.captureSession addOutput:self.videoOutput];
    }
    
    AVCaptureConnection *videoConn = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([videoConn isVideoOrientationSupported]) {
        [videoConn setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if([self.captureSession canAddOutput:self.audioOutput])
    {
        [self.captureSession addOutput:self.audioOutput];
    }
}

- (void)addAudio {
    NSError *audioError;
    // 添加一个音频输入设备
    self.audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    //  音频输入对象
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.audioDevice error:&audioError];
    if (audioError) {
        NSLog(@"取得录音设备时出错 ------ %@",audioError);
        return;
    }
    // 将音频输入对象添加到会话 (AVCaptureSession) 中
    if ([self.captureSession canAddInput:self.audioInput]) {
        [self.captureSession addInput:self.audioInput];
    }
}


- (void)addPreviewLayer {
    
    //    [self.view layoutIfNeeded];
    
    // 通过会话 (AVCaptureSession) 创建预览层
    self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    self.captureVideoPreviewLayer.frame = self.view.bounds;
    /* 填充模式
     Options are AVLayerVideoGravityResize, AVLayerVideoGravityResizeAspect and AVLayerVideoGravityResizeAspectFill. AVLayerVideoGravityResizeAspect is default.
     */
    //有时候需要拍摄完整屏幕大小的时候可以修改这个
    self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.captureVideoPreviewLayer.position = CGPointMake(self.view.frame.size.width*0.5,self.view.frame.size.height*0.5);
    
    // 显示在视图表面的图层
    CALayer *layer = self.recordView.layer;
    layer.masksToBounds = true;
    [self.view layoutIfNeeded];
    [layer addSublayer:self.captureVideoPreviewLayer];
}


#pragma mark - lazyloading


- (dispatch_queue_t)videoQueue
{
    if (!_videoQueue)
    {
        _videoQueue = dispatch_queue_create("CXRecordVideoViewController", DISPATCH_QUEUE_SERIAL); // dispatch_get_main_queue();
    }
    
    return _videoQueue;
}
//底部View
- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor clearColor];
        [_bottomView addSubview:self.cancelButton];
        [_cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(20);
            make.bottom.equalTo(_bottomView).with.offset(-30);//底部距离_bottomView为30
        }];
        
        [_bottomView addSubview:self.recordButton];
        [self.recordButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(_bottomView).with.offset(-14);//底部距离_bottomView为14
            make.centerX.equalTo(_bottomView);
            make.size.mas_equalTo(CGSizeMake(67, 67));
        }];
        
        [_bottomView addSubview:self.overTurnButton];
        [self.overTurnButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(_bottomView).with.offset(-30);//底部距离_bottomView为30
            make.right.equalTo(_bottomView).with.offset(-20);
        }];
        
        [_bottomView addSubview:self.videoTypeLabel];
        [self.videoTypeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(_bottomView);
            make.height.mas_equalTo(20);
            make.top.equalTo(_bottomView.mas_top).offset(10);
        }];
    }
    return _bottomView;
}

//取消按钮
- (UIButton *)cancelButton{
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_cancelButton setBackgroundColor:[UIColor clearColor]];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [_cancelButton sizeToFit];
        [_cancelButton addTarget:self action:@selector(touchCancelButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

//录像按钮
- (UIButton *)recordButton {
    if (!_recordButton) {
        _recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_recordButton addTarget:self action:@selector(touchRecordButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _recordButton;
}

//录像View
- (UIView *)recordView {
    if (!_recordView) {
        _recordView = [[UIView alloc] initWithFrame:self.view.frame];
//        _recordView.backgroundColor = [UIColor redColor];
        //添加双击放大 拉伸放大
        UITapGestureRecognizer *doubleTapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        doubleTapGesture.delaysTouchesBegan = YES;
        [_recordView addGestureRecognizer:doubleTapGesture];
        //添加捏合手势
        _recordView.multipleTouchEnabled = YES;  // 允许UIView多点触控
        UIPinchGestureRecognizer *recongnizerPinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(PinchTap:)];
        [_recordView addGestureRecognizer:recongnizerPinch];
    }
    return _recordView;
}

//录制视频类型label
- (UILabel *)videoTypeLabel
{
    if (!_videoTypeLabel) {
        _videoTypeLabel = [[UILabel alloc] init];
        _videoTypeLabel.backgroundColor = [UIColor clearColor];
        _videoTypeLabel.text = @"小视频";
        _videoTypeLabel.textColor = [UIColor yellowColor];
        _videoTypeLabel.font = [UIFont systemFontOfSize:12];
        _videoTypeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _videoTypeLabel;
}

//双击放大label
- (UILabel *)recordToolLabel{
    if (!_recordToolLabel) {
        //添加录制view上的label
        _recordToolLabel = [UILabel new];
        [_recordToolLabel setText:@"双击可放大"];
        _recordToolLabel.textColor = [UIColor whiteColor];
        _recordToolLabel.font = [UIFont systemFontOfSize:16];
        _recordToolLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _recordToolLabel;
}

//翻转摄像头按钮
- (UIButton *)overTurnButton
{
    if (!_overTurnButton) {
        _overTurnButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_overTurnButton setBackgroundImage:[UIImage imageNamed:@"small-video-lz-icon-camera"] forState:UIControlStateNormal];
        [_overTurnButton addTarget:self action:@selector(touchOverTurnButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _overTurnButton;
}

#pragma mark - UI

- (void)addSubView {
    //录像View
    [self.view addSubview:self.recordView];
    
    //底部view
    [self.view addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(123);
        make.width.mas_equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    //双击放大label
    [self.view addSubview:self.recordToolLabel];
    [self.recordToolLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.bottomView.mas_top).offset(-20);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(22);
        make.width.mas_equalTo(100);
    }];
}

#pragma mark - action

/**
 *  设置写入视频属性
 */
- (void)setUpWriter
{
    NSError *error;
    self.assetWriter = [AVAssetWriter assetWriterWithURL:[self outPutFileURL] fileType:AVFileTypeMPEG4 error:&error];
    if (error) {
        NSLog(@"写入失败--error=%@",error);
    }
    
    //视频属性
    self.videoCompressionSettings = self.options.videoCompressionSettings;
    
    self.assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
    
//    _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    
    //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
    self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    
    // 音频设置
    self.audioCompressionSettings = self.options.audioCompressionSettings;
    
    self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioCompressionSettings];
    self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    
    if ([self.assetWriter canAddInput:self.assetWriterVideoInput])
    {
        [self.assetWriter addInput:self.assetWriterVideoInput];
    }
    else
    {
        NSLog(@"AssetWriter videoInput append Failed");
    }
    
    if ([self.assetWriter canAddInput:self.assetWriterAudioInput])
    {
        [self.assetWriter addInput:self.assetWriterAudioInput];
    }
    else
    {
        NSLog(@"AssetWriter audioInput Append Failed");
    }
    
    self.canWrite = NO;
}

- (void)setIsRecording:(BOOL)isRecording
{
    _isRecording = isRecording;
    if (isRecording) {
        [self.recordButton setImage:[UIImage imageNamed:@"small-video-icon-zt"] forState:UIControlStateNormal];
        //录制视频的时候隐藏翻转按钮
        self.overTurnButton.hidden = YES;
    }else{
        [self.recordButton setImage:[UIImage imageNamed:@"small-video-icon-bf"] forState:UIControlStateNormal];
        self.overTurnButton.hidden = NO;
    }
}

//视频输出路径
- (NSURL *)outPutFileURL
{
    NSString *filePath = [self.options.outPutDirPath stringByAppendingString:@"/tmp.mp4"];
    return [NSURL fileURLWithPath:filePath];
}

//取消按钮
- (void)touchCancelButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//录像按钮
- (void)touchRecordButton {
    if (self.isRecording) {
        [self stopVideoRecorder];
    }else{
//        [_movieOutput startRecordingToOutputFileURL:[self outPutFileURL] recordingDelegate:self];
        //开始录制
        [self startVideoRecorder];
    }
}

//开始录制
- (void)startVideoRecorder
{
    //先删除沙盒里的缓存文件，不然写不进去
    NSString *filePath = [self outPutFileURL].absoluteString;
    if ([filePath hasPrefix:@"file://"]) {
        filePath = [filePath substringFromIndex:7];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    [self setUpWriter];
    self.isRecording = YES;
    __weak typeof(self) weakSelf = self;
    weakSelf.recordToolLabel.text = [NSString stringWithFormat:@"00:%ld",self.residueRecordTime];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
}

- (void)timerAction
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.residueRecordTime -= 1;
        weakSelf.recordToolLabel.text = [NSString stringWithFormat:@"00:%02ld",(long)weakSelf.residueRecordTime];
        if (weakSelf.residueRecordTime <= 0) {
            [weakSelf touchRecordButton];
            weakSelf.recordToolLabel.text = [NSString stringWithFormat:@"双击可放大"];
            weakSelf.residueRecordTime = weakSelf.options.maxRecordTime;
            [weakSelf.timer invalidate];
        }
    });
}

//停止录制
- (void)stopVideoRecorder
{
    if (self.isRecording) {
        [self updateStateOriginal];
        [self.recordButton setEnabled:NO];
        [self.cancelButton setEnabled:NO];
        __weak __typeof(self)weakSelf = self;
        if(self.assetWriter && self.assetWriter.status == AVAssetWriterStatusWriting)
        {
            [self.assetWriter finishWritingWithCompletionHandler:^{
                weakSelf.canWrite = NO;
                weakSelf.assetWriter = nil;
                weakSelf.assetWriterAudioInput = nil;
                weakSelf.assetWriterVideoInput = nil;
            }];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            //如果文件存在跳转到保存小视频页面
            NSString *filePath = [weakSelf outPutFileURL].absoluteString;
            if ([filePath hasPrefix:@"file://"]) {
                filePath = [filePath substringFromIndex:7];
            }
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                CXRecordFinishViewController *finishVC = [[CXRecordFinishViewController alloc] init];
                finishVC.videoUrl = [weakSelf outPutFileURL];
                finishVC.finishBlock = self.finishBlock;
                [weakSelf.navigationController pushViewController:finishVC animated:YES];
            } else {
                [self updateStateOriginal];
                [self.recordButton setEnabled:YES];
                [self.cancelButton setEnabled:YES];
            }
            
        });
    }
    
}

//点击翻转摄像头按钮
- (void)touchOverTurnButton {
    switch (self.videoDevice.position) {
        case AVCaptureDevicePositionBack:
            self.videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
            break;
        case AVCaptureDevicePositionFront:
            self.videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
            break;
        default:
            return;
            break;
    }
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoDevice error:&error];
        
        if (newVideoInput != nil) {
            //必选先 remove 才能询问 canAdd
            [self.captureSession removeInput:self.videoInput];
            if ([self.captureSession canAddInput:newVideoInput]) {
                [self.captureSession addInput:newVideoInput];
                self.videoInput = newVideoInput;
            }else{
                [self.captureSession addInput:self.videoInput];
            }
            AVCaptureConnection *videoConn = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
            if ([videoConn isVideoOrientationSupported]) {
                [videoConn setVideoOrientation:AVCaptureVideoOrientationPortrait];
            }
        } else if (error) {
            NSLog(@"切换前/后摄像头失败, error = %@", error);
        }
    }];
}

//双击放大
-(void)doubleTap:(UITapGestureRecognizer *)tapGesture{
    AVCaptureDevice *captureDevice= [self.videoInput device];
    if (self.currentZoomFactor < captureDevice.activeFormat.videoMaxZoomFactor && self.currentZoomFactor < 5.0) {
        self.currentZoomFactor += 0.5;
    }else{
        self.currentZoomFactor = 1.0;
    }
    [self updateVideoZoomFactor];
}

//捏合手势
- (void)PinchTap:(UIPinchGestureRecognizer *)pinchTapGesture{
    
    // 捏合手势默认的系数是1.0
    // 当识别为放大手势时，系数会从1.0开始递加； 当识别为缩小手势时，系数会从1.0开始递减，直到为0.0
    CGFloat scale = pinchTapGesture.scale;
    self.currentZoomFactor = self.currentZoomFactor + (scale - 1) * 0.3;
    if (self.currentZoomFactor >= 5.0) {
        self.currentZoomFactor = 5.0;
    }else if (self.currentZoomFactor <= 1.0){
        self.currentZoomFactor = 1.0;
    }
    [self updateVideoZoomFactor];
}

//调整焦距
- (void)updateVideoZoomFactor{
    AVCaptureDevice *captureDevice= [self.videoInput device];
    NSError *error;
    if ([captureDevice lockForConfiguration:&error]) {
        [captureDevice rampToVideoZoomFactor:self.currentZoomFactor withRate:20];
    }else{
        NSLog(@"锁定设备过程error，错误信息：%@",error.localizedDescription);
    }
    [captureDevice unlockForConfiguration];
}

//更改设备属性前一定要锁上
-(void)changeDevicePropertySafety:(void (^)(AVCaptureDevice *captureDevice))propertyChange{
    //也可以直接用_videoDevice,但是下面这种更好
    AVCaptureDevice *captureDevice= [self.videoInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁,意义是---进行修改期间,先锁定,防止多处同时修改
    BOOL lockAcquired = [captureDevice lockForConfiguration:&error];
    if (!lockAcquired) {
        NSLog(@"锁定设备过程error，错误信息：%@",error.localizedDescription);
    }else{
        [self.captureSession beginConfiguration];
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        [self.captureSession commitConfiguration];
    }
}

//更改状态为初始状态
- (void)updateStateOriginal
{
    self.isRecording = NO;
    self.residueRecordTime = self.options.maxRecordTime;
    self.recordToolLabel.text = [NSString stringWithFormat:@"双击可放大"];
    [self.timer invalidate];
}

#pragma mark - delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.isRecording) {
        if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]){//视频
            [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
        }else if (connection == [self.audioOutput connectionWithMediaType:AVMediaTypeAudio]){//音频
            [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
        }
    }
}


/**
 *  开始写入数据
 */
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType
{
    if (sampleBuffer == NULL)
    {
        NSLog(@"empty sampleBuffer");
        return;
    }
    
    if (!self.canWrite && mediaType == AVMediaTypeVideo)
    {
        [self.assetWriter startWriting];
        [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        self.canWrite = YES;
    }
    
    //写入视频数据
    if (mediaType == AVMediaTypeVideo)
    {
        if (self.assetWriterVideoInput.readyForMoreMediaData)
        {
            BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
            if (!success)
            {
                NSLog(@"写入视频流失败");
            }
        }
    }
    
    //写入音频数据
    if (mediaType == AVMediaTypeAudio)
    {
        if (self.assetWriterAudioInput.readyForMoreMediaData)
        {
            BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
            if (!success)
            {
                NSLog(@"写入音频流失败");
            }
        }
    }
}

@end
