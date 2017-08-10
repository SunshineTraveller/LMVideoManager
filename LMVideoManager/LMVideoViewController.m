//
//  LMVideoViewController.m
//  TopicEdit
//
//  Created by 张利民 on 2017/8/9.
//  Copyright © 2017年 ghostlord. All rights reserved.
//

#define LMWID [UIScreen mainScreen].bounds.size.width
#define LMHEI [UIScreen mainScreen].bounds.size.height

//#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "LMNoticeLabel.h"
#import "LMVideoManager.h"

#import "LMVideoViewController.h"

@interface LMVideoViewController ()<LMVideoManagerProtocol> {
    NSString *_filePath;
}

/** 视频播放视图 */
@property (nonatomic,strong) UIView *videoView;

@property (nonatomic,strong) AVPlayerViewController *player;

/** manager */
@property (nonatomic,strong) LMVideoManager *manager;



@end

@implementation LMVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

-(void)setupUI {
    
    self.title = @"视频";
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 64, LMWID/2, 44);
    btn.backgroundColor = [UIColor yellowColor];
    [btn setTitle:@"录制视频" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(recordBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *stop = [UIButton buttonWithType:UIButtonTypeCustom];
    stop.backgroundColor = [UIColor redColor];
    [stop setTitle:@"停止录制" forState:UIControlStateNormal];
    [stop setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    stop.frame = CGRectMake(LMWID/2, 64, LMWID/2, 44);
    [stop addTarget:self action:@selector(endRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stop];
    
    self.videoView = [[UIView alloc] initWithFrame:CGRectMake(10, LMHEI/2, LMWID-20, LMHEI/2)];
    self.videoView.userInteractionEnabled = YES;
    
    UIButton *play = [UIButton buttonWithType:UIButtonTypeCustom];
    play.frame = CGRectMake(0, LMHEI-60, LMWID, 50);
    [play setTitle:@"播放" forState:UIControlStateNormal];
    [play setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [play addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:play];
    
    _manager = [[LMVideoManager alloc] init];
    _manager.delegate = self;
    [_manager showWithFrame:CGRectMake(20, 120, LMWID-40, LMHEI/2-1) superView:self.view];
    _manager.maxTime = 30.0;
    
}

-(void)recordBtnAction:(UIButton *)btn {
    
    [_manager startRecording];
    
}

-(void)endRecording {
    
    [_manager endRecording];
}

-(void)playVideo {
    
    _player = [[AVPlayerViewController alloc] init];
    _player.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:_filePath]];
    _player.videoGravity = AVLayerVideoGravityResize;
    [self presentViewController:_player animated:NO completion:nil];
    
}

-(void)didStartRecordVideo {
    
    [self.view addSubview:[LMNoticeLabel message:@"开始录制..." delaySecond:2]];
}

-(void)didCompressingVideo {
    
    [self.view addSubview:[LMNoticeLabel message:@"视频压缩中..." delaySecond:2]];
    
}

-(void)didEndRecordVideoWithTime:(CGFloat)totalTime outputFile:(NSString *)filePath {
    
    [self.view addSubview:[LMNoticeLabel message:@" 录制完毕，时长:%lu  路径：%@" delaySecond:4]];
    _filePath = filePath;
    
}

- (void)dealloc
{
    NSLog(@"控制器销毁了");
}

@end



























