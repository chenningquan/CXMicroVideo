//
//  CXRootViewController.m
//  CXFileUpload
//
//  Created by chennq on 2019/3/12.
//  Copyright © 2019 chennq. All rights reserved.
//

#import "CXRootViewController.h"
#import "CXMicroVideoManager.h"

@interface CXRootViewController ()

@end

@implementation CXRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 200, 200);
    btn.center = self.view.center;
    [btn setTitle:@"开始录制" forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor greenColor];
    [btn addTarget:self action:@selector(clickBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)clickBtn {
    [[CXMicroVideoManager shareManager] startVideoRecordFinish:^(BOOL isSuccess, NSString * _Nonnull msg, NSString * _Nonnull filePath) {
        
    }];
}

@end
