//
//  WLCoreVideoRecoder.h
//  WLVideo
//
//  Created by wangliang on 13-6-27.
//  Copyright (c) 2013年 wangliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol WLCoreVideoRecoderDelegate;

@interface WLCoreVideoRecoder : NSObject {
}

@property (nonatomic,retain) AVCaptureSession *session;
@property (nonatomic,retain) AVCaptureMovieFileOutput *fileOutput;
@property (nonatomic,copy) NSURL *outputFileURL;
@property (nonatomic,readonly) BOOL recordsVideo;
@property (nonatomic,readonly) BOOL recordsAudio;
@property (nonatomic,readonly,getter=isRecording) BOOL recording;
@property (nonatomic,assign) id <WLCoreVideoRecoderDelegate> delegate;

-(id)initWithSession:(AVCaptureSession *)session outputFileURL:(NSURL *)outputFileURL;
-(void)startRecordingWithOrientation:(AVCaptureVideoOrientation)videoOrientation;
-(void)stopRecording;
@end

@protocol WLCoreVideoRecoderDelegate<NSObject>
@required
-(void)recorderRecordingDidBegin:(WLCoreVideoRecoder *)recorder;
-(void)recorder:(WLCoreVideoRecoder *)recorder recordingDidFinishToOutputFileURL:(NSURL *)outputFileURL error:(NSError *)error;
@end