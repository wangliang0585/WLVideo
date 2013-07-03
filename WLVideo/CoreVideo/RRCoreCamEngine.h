//
//  RRCoreCamEngine.h
//  WLVideo
//
//  Created by wangliang on 13-6-27.
//  Copyright (c) 2013年 wangliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol RRCoreCamEngineDelegate;
@interface RRCoreCamEngine : NSObject
/*!
 是否在录像
 */
@property (nonatomic, readonly) BOOL isCapturing;
/**
 是否暂停
 */
@property (nonatomic, readonly) BOOL isPaused;
@property (nonatomic, assign) id<RRCoreCamEngineDelegate> delegate;

/*!
 * @brief 获取RRCoreCamEngine的单例方法
 * @param N/A
 * @return RRCoreCamEngine的全局唯一实例
 */
+ (RRCoreCamEngine*)engine;

/*!
 * @brief 启动视频引擎
 * @param N/A
 * @return N/A
 */
- (void)startUp;

/*!
 * @brief 关闭视频引擎
 * @param N/A
 * @return N/A
 */
- (void)close;

/*!
 * @brief 获取视频图层
 * @param N/A
 * @return 当前视频图层
 */
- (AVCaptureVideoPreviewLayer*) getPreviewLayer;

/*!
 * @brief 开始录像
 * @param option 视频方向  
                if orientation = nil,default vaule is AVCaptureVideoOrientationPortrait
 * @return N/A
 */
- (void) startCapture:(AVCaptureVideoOrientation)orientation;

/*!
 * @brief 暂停录像
 * @param N/A
 * @return N/A
 */
- (void) pauseCapture;

/*!
 * @brief 恢复录像
 * @param N/A
 * @return N/A
 */
- (void) resumeCapture;

/*!
 * @brief 停止录像
 * @param N/A
 * @return N/A
 */
- (void) stopCapture;

/*!
 * @brief 更新视频方向
 * @param 视频方向
 * @return N/A
 */
- (void) changeVideoOrientation:(AVCaptureVideoOrientation)orientation;

@end


#pragma mark - RRCoreCamEngineDelegate
@protocol RRCoreCamEngineDelegate <NSObject>
- (void)coreCamEngineDidFinish:(RRCoreCamEngine*)engine withURL:(NSURL*)fileURL;
- (void)coreCamEngineThrowException:(RRCoreCamEngine *)engine withError:(NSError *)error;
@end