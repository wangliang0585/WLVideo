//
//  WLCoreVideoManger.h
//  WLVideo
//
//  Created by wangliang on 13-6-27.
//  Copyright (c) 2013年 wangliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol WLCoreVideoManagerDelegate;

@interface WLCoreVideoManger : NSObject
@property (nonatomic,retain) AVCaptureSession *session;
@property (nonatomic,assign) AVCaptureVideoOrientation orientation;
@property (nonatomic,retain) AVCaptureDeviceInput *videoInput;
@property (nonatomic,retain) AVCaptureDeviceInput *audioInput;

@property (nonatomic,assign)id<WLCoreVideoManagerDelegate> delegate;

- (BOOL) setupSession;
- (void) startRecording;
- (void) stopRecording;
@end



@protocol WLCoreVideoManagerDelegate <NSObject>
@optional
- (void) captureManager:(WLCoreVideoManger *)captureManager didFailWithError:(NSError *)error;
- (void) captureManagerRecordingBegan:(WLCoreVideoManger *)captureManager;
- (void) captureManagerRecordingFinished:(WLCoreVideoManger *)captureManager;
@end