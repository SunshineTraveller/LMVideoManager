//
//  LMVideoManager.m
//  TopicEdit
//
//  Created by 张利民 on 2017/8/9.
//  Copyright © 2017年 ghostlord. All rights reserved.
//
#define COMPRESSEDVIDEOPATH [NSHomeDirectory() stringByAppendingFormat:@"/Documents/CompressionVideoField"]


#import "LMVideoManager.h"

@interface LMVideoManager ()<GPUImageVideoCameraDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

/** 摄像头 */
@property (nonatomic,strong) GPUImageVideoCamera *videoCamera;

/** 美颜滤镜 */
@property (nonatomic,strong) GPUImageBeautifyFilter *beautifyFilter;

/** 视频输出视图 */
@property (nonatomic,strong) GPUImageView *displayView;

/** 视频写入 */
@property (nonatomic,strong) GPUImageMovieWriter *movieWriter;

/** 视频写入的地址URL */
@property (nonatomic,strong) NSURL *movieURL;

/** 视频写入路径 */
@property (nonatomic,copy) NSString *moviePath;

/** 压缩成功后的视频路径 */
@property (nonatomic,copy) NSString *resultPath;

/** 视频时长 */
@property (nonatomic,assign) int seconds;

/** 系统计时器 */
@property (nonatomic,strong) NSTimer *timer;

/** 计时器常量 */
@property (nonatomic,assign) int recordSecond;


@end

@implementation LMVideoManager

static LMVideoManager *_manager;

// 单例
+(instancetype)manager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[LMVideoManager alloc] init];
    });
    return _manager;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_manager == nil) {
            _manager = [super allocWithZone:zone];
        }
    });
    return _manager;
}

// 开始录制
-(void)startRecording {
    
    NSString *defultPath = [self getVideoPathCache];
    self.moviePath = [defultPath stringByAppendingPathComponent:[self getVideoNameWithType:@"mp4"]];
    // 录制路径
    self.movieURL = [NSURL fileURLWithPath:self.moviePath];
    // ？
    unlink([self.moviePath UTF8String]);
    
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.movieURL size:CGSizeMake(480.0, 640.0)];
    self.movieWriter.encodingLiveVideo = YES;
    self.movieWriter.shouldPassthroughAudio = YES;
    [self.beautifyFilter addTarget:self.movieWriter];
    self.videoCamera.audioEncodingTarget = self.movieWriter;
    // 开始录制
    [self.movieWriter startRecording];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStartRecordVideo)]) {
        [self.delegate didStartRecordVideo];
    }
    [self.timer setFireDate:[NSDate distantPast]];
    [self.timer fire];
    
}

// 结束录制
-(void)endRecording {
    
    if ([self.videoCamera isRunning]) {
        
        [self.timer invalidate];
        self.timer = nil;
        __weak typeof(self) weakSelf = self;
        [self.movieWriter finishRecording];
        [self.beautifyFilter removeTarget:self.movieWriter];
        self.videoCamera.audioEncodingTarget = nil;
        if (self.recordSecond > self.maxTime) {
            
            // 清除录制的视频
            
        }else {
            
            // 压缩中...
            if ([self.delegate respondsToSelector:@selector(didCompressingVideo)]) {
                [self.delegate didCompressingVideo];
            }
            
            // 压缩
            [self compressVideoWithUrl:self.movieURL compressionType:AVAssetExportPresetMediumQuality filePath:^(NSString *resultPath, float memorySize, NSString *videoImagePath, int seconds) {
                
                
                NSData *data = [NSData dataWithContentsOfFile:resultPath];
                CGFloat totalTime = (CGFloat)data.length / 1024 / 1024;
                
                // 压缩完回调
                if ([weakSelf.delegate respondsToSelector:@selector(didEndRecordVideoWithTime:outputFile:)]) {
                    [weakSelf.delegate didEndRecordVideoWithTime:totalTime outputFile:resultPath];
                }
                
            }];
        }
    }
}

// 暂停
-(void)pauseRecording {
    
    if ([_videoCamera isRunning]) {
        [self.timer invalidate];
        self.timer = nil;
        [_videoCamera pauseCameraCapture];
    }
    
}

// 恢复
-(void)resumeRecording {
 
    [_videoCamera resumeCameraCapture];
    [self.timer setFireDate:[NSDate distantPast]];
    [self.timer fire];
}


#pragma mark -- 自定义方法

-(void)showWithFrame:(CGRect)frame superView:(UIView *)superView {
    
    _frame = frame;
    [self.beautifyFilter addTarget:self.displayView];
    [self.videoCamera addTarget:self.beautifyFilter];
    [superView addSubview:self.displayView];
    [self.videoCamera startCameraCapture];
    
}

// 切换前后摄像头
-(void)changeCameraPosition:(LMVideoManagerCameraType)type {
    
    switch (type) {
        case LMVideoManagerCameraTypeFront:{
            [_videoCamera rotateCamera];
        }
            break;
        case LMVideoManagerCameraTypeBack:{
            [_videoCamera rotateCamera];
        }
            break;
            
        default:
            break;
    }
    
}

#pragma mark ----摄像头输出代理方法----
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
}

// 手电筒开关
-(void)turnTorchOn:(BOOL)on {
    
    if ([_videoCamera.inputCamera hasTorch] && [_videoCamera.inputCamera hasFlash]) {
        
        [_videoCamera.inputCamera lockForConfiguration:nil];
        if (on) {
            [_videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
            [_videoCamera.inputCamera setFlashMode:AVCaptureFlashModeOn];
        }else{
            [_videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
            [_videoCamera.inputCamera setFlashMode:AVCaptureFlashModeOff];
        }
        [_videoCamera.inputCamera unlockForConfiguration];
        
    }
    
}

// 获取视频地址
-(NSString *)getVideoPathCache {
    
    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingString:@"videos"];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:videoCache isDirectory:&isDir];
    if (!existed) {
        [fileManager createDirectoryAtPath:videoCache withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return videoCache;
}

// 获取视频名称
-(NSString *)getVideoNameWithType:(NSString *)fileType {
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HHmmss"];
    NSDate *nowDate = [NSDate dateWithTimeIntervalSince1970:now];
    NSString *timeStr = [formatter stringFromDate:nowDate];
    NSString *fileName = [NSString stringWithFormat:@"video_%@.%@",timeStr,fileType];
    return fileName;
    
}

#pragma mark -- 懒加载

// 摄像头
-(GPUImageVideoCamera *)videoCamera {
    
    if (_videoCamera == nil) {
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        _videoCamera.delegate = self;
        // 可防止允许声音通过的情况下,避免第一帧黑屏
        [_videoCamera addAudioInputsAndOutputs];
    }
    return _videoCamera;
}

// 滤镜
-(GPUImageBeautifyFilter *)beautifyFilter {
    
    if (_beautifyFilter == nil) {
        _beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    }
    return _beautifyFilter;
}

// 展示视图
-(GPUImageView *)displayView {
    
    if (_displayView == nil) {
        _displayView = [[GPUImageView alloc] initWithFrame:self.frame];
        _displayView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    }
    return _displayView;
}

// 计时器
-(NSTimer *)timer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateWithTime) userInfo:nil repeats:YES];
    }
    return _timer;
}

// 超过最大录制时长结束录制
-(void)updateWithTime {
    
    self.recordSecond++;
    if (self.recordSecond >= self.maxTime) {
        [self endRecording];
    }
    
}

// 压缩视频
-(void)compressVideoWithUrl:(NSURL *)url compressionType:(NSString *)type filePath:(void(^)(NSString *resultPath,float memorySize,NSString * videoImagePath,int seconds))resultBlock {
    
    NSString *resultPath;
    
    
     // 视频压缩前大小
    NSData *data = [NSData dataWithContentsOfURL:url];
    CGFloat totalSize = (float)data.length / 1024 / 1024;
    NSLog(@"压缩前大小：%.2fM",totalSize);
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    CMTime time = [avAsset duration];
    
    // 视频时长
    int seconds = ceil(time.value / time.timescale);
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:type]) {
        
        // 中等质量
        AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        
        // 用时间给文件命名 防止存储被覆盖
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
        
        // 若压缩路径不存在重新创建
        NSFileManager *manager = [NSFileManager defaultManager];
        BOOL isExist = [manager fileExistsAtPath:COMPRESSEDVIDEOPATH];
        if (!isExist) {
            [manager createDirectoryAtPath:COMPRESSEDVIDEOPATH withIntermediateDirectories:YES attributes:nil error:nil];
        }
        resultPath = [COMPRESSEDVIDEOPATH stringByAppendingPathComponent:[NSString stringWithFormat:@"user%outputVideo-%@.mp4",arc4random_uniform(10000),[formatter stringFromDate:[NSDate date]]]];
        
        session.outputURL = [NSURL fileURLWithPath:resultPath];
        session.outputFileType = AVFileTypeMPEG4;
        session.shouldOptimizeForNetworkUse = YES;
        [session exportAsynchronouslyWithCompletionHandler:^{
            
            switch (session.status) {
                case AVAssetExportSessionStatusUnknown:
                    break;
                case AVAssetExportSessionStatusWaiting:
                    break;
                case AVAssetExportSessionStatusExporting:
                    break;
                case AVAssetExportSessionStatusCancelled:
                    break;
                case AVAssetExportSessionStatusFailed:
                    break;
                case AVAssetExportSessionStatusCompleted:{
                    
                    NSData *data = [NSData dataWithContentsOfFile:resultPath];
                    // 压缩过后的大小
                    float compressedSize = (float)data.length / 1024 / 1024;
                    resultBlock(resultPath,compressedSize,@"",seconds);
                    NSLog(@"压缩后大小：%.2f",compressedSize);
                }
                default:
                    break;
            }
        }];
    }
}

- (void)dealloc {
    
    [self.timer invalidate];
    NSLog(@"销毁了啊");
    
}









@end











