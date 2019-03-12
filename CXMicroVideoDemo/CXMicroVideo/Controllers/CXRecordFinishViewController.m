//
//  CXRecordFinishViewController.m
//  NIM
//
//  Created by chennq on 2018/4/16.
//  Copyright © 2018年 chennq. All rights reserved.
//

#import "CXRecordFinishViewController.h"
#import <AVKit/AVKit.h>
#import <Masonry.h>

@interface CXRecordFinishViewController ()

@property (nonatomic, strong) AVPlayer *player; //播放视图
@property (nonatomic, strong) UILabel *recordFinishLabel; //录制完成显示label（默认显示确认发送小视频?）
@property (nonatomic, strong) UIButton *confirmSendVideoButton; //确认发送小视频按钮
@property (nonatomic, strong) UIButton *cancelSendVideoButton; //取消发送小视频按钮

@end

@implementation CXRecordFinishViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    //开始播放小视频
    [self.player play];
    //配置子视图
    [self addSubviews];
    //播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player pause];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addSubviews
{
    [self.view addSubview:self.cancelSendVideoButton];
    [self.cancelSendVideoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(20);
        make.bottom.equalTo(self.view.mas_bottom).offset(-30);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(25);
    }];
    
    [self.view addSubview:self.confirmSendVideoButton];
    [self.confirmSendVideoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view.mas_right).offset(-20);
        make.bottom.equalTo(self.view.mas_bottom).offset(-30);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(25);
    }];
    
    [self.view addSubview:self.recordFinishLabel];
    [self.recordFinishLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-60);
        make.width.mas_equalTo(128);
        make.height.mas_equalTo(25);
    }];
}

#pragma mark lazyLoading

- (AVPlayer *)player
{
    if (!_player) {
        AVPlayerItem *playItem = [AVPlayerItem playerItemWithURL:self.videoUrl];
        _player = [AVPlayer playerWithPlayerItem:playItem];
        AVPlayerLayer *playerLayer =[AVPlayerLayer playerLayerWithPlayer:_player];
        playerLayer.frame = self.view.frame;
        playerLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//视频填充模式
        [self.view.layer addSublayer:playerLayer];
    }
    return _player;
}

//确认发送小视频按钮
- (UIButton *)confirmSendVideoButton
{
    if (!_confirmSendVideoButton) {
        _confirmSendVideoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_confirmSendVideoButton setBackgroundImage:[UIImage imageNamed:@"small-video-fs-icon-qr"] forState:UIControlStateNormal];
        [_confirmSendVideoButton addTarget:self action:@selector(confirmSendSmallVideo) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmSendVideoButton;
}

//取消发送小视频按钮
- (UIButton *)cancelSendVideoButton
{
    if (!_cancelSendVideoButton) {
        _cancelSendVideoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelSendVideoButton setBackgroundImage:[UIImage imageNamed:@"small-video-spfs-icon-fh"] forState:UIControlStateNormal];
        [_cancelSendVideoButton addTarget:self action:@selector(cancelSendSmallVideo) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelSendVideoButton;
}

- (UILabel *)recordFinishLabel
{
    if (!_recordFinishLabel) {
        _recordFinishLabel = [UILabel new];
        _recordFinishLabel.text = @"确认发送小视频?";
        _recordFinishLabel.textColor = [UIColor yellowColor];
        _recordFinishLabel.font = [UIFont systemFontOfSize:16];
        _recordFinishLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _recordFinishLabel;
}

#pragma mark action
//发送小视频
- (void)confirmSendSmallVideo {
    if (self.finishBlock) {
        self.finishBlock(YES,@"",self.videoUrl.absoluteString);
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

//取消发送小视频
- (void)cancelSendSmallVideo {
    [self.navigationController popViewControllerAnimated:YES];
}

//播放完成后回到开始继续播放
-(void)playbackFinished:(NSNotification *)notification
{
    [_player seekToTime:CMTimeMake(0, 1)];
    [_player play];
}

@end
