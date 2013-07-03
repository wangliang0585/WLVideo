//
//  RRCoreCamEngine.m
//  WLVideo
//
//  Created by wangliang on 13-6-27.
//  Copyright (c) 2013年 wangliang. All rights reserved.
//

#import "RRCoreCamEngine.h"
#import "RRCoreVideoEncoder.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface RRCoreCamEngine  () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{
    AVCaptureSession* _session;
    AVCaptureVideoPreviewLayer* _preview;
    dispatch_queue_t _captureQueue;
    AVCaptureConnection* _audioConnection;
    AVCaptureConnection* _videoConnection;
    
    RRCoreVideoEncoder* _encoder;
    BOOL _isCapturing;
    BOOL _isPaused;
    BOOL _discont;
    int _currentFile;
    CMTime _timeOffset;
    CMTime _lastVideo;
    CMTime _lastAudio;
    
    int _cx;
    int _cy;
    int _channels;
    Float64 _samplerate;
}
@end


static RRCoreCamEngine *coreEngine = nil;

@implementation RRCoreCamEngine

+ (RRCoreCamEngine*) engine
{
    @synchronized(self){
        if (!coreEngine) {
            coreEngine = [[RRCoreCamEngine alloc] init];
        }
    }

    return coreEngine;
}

- (void) startUp
{
    if (_session == nil)
    {        
        _isCapturing = NO;
        _isPaused = NO;
        _currentFile = 0;
        _discont = NO;
        
        _session = [[AVCaptureSession alloc] init];
        if ([_session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
            [_session setSessionPreset:AVCaptureSessionPreset640x480];
        }
        
        AVCaptureDevice* backCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:nil];
        [_session addInput:input];
        
        AVCaptureDevice* mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput* micinput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:nil];
        [_session addInput:micinput];
        
        _captureQueue = dispatch_queue_create("wangliang.coreCam.capture", DISPATCH_QUEUE_SERIAL);
        AVCaptureVideoDataOutput* videoout = [[AVCaptureVideoDataOutput alloc] init];
        [videoout setSampleBufferDelegate:self queue:_captureQueue];
        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
//                                        [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        videoout.videoSettings = setcapSettings;
        [_session addOutput:videoout];
        _videoConnection = [videoout connectionWithMediaType:AVMediaTypeVideo];
        
        if ([_videoConnection isVideoOrientationSupported])
            [_videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        
        NSDictionary* actual = videoout.videoSettings;
        _cy = [[actual objectForKey:@"Height"] integerValue];
        _cx = [[actual objectForKey:@"Width"] integerValue];
        
        AVCaptureAudioDataOutput* audioout = [[AVCaptureAudioDataOutput alloc] init];
        [audioout setSampleBufferDelegate:self queue:_captureQueue];
        [_session addOutput:audioout];
        _audioConnection = [audioout connectionWithMediaType:AVMediaTypeAudio];

        [_session startRunning];
        
        _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
}

- (void) close
{
    if (_session)
    {
        [_session stopRunning];
        _session = nil;
    }
    [_encoder finishWithCompletionHandler:^{
        NSLog(@"Capture completed");
    }];
}

- (AVCaptureVideoPreviewLayer*) getPreviewLayer
{
    return _preview;
}

- (void) startCapture:(AVCaptureVideoOrientation)orientation
{
    if (!self.isCapturing)
    {
        NSLog(@"starting capture");
        _encoder = nil;
        _isPaused = NO;
        _discont = NO;
        _timeOffset = CMTimeMake(0, 0);
        _isCapturing = YES;
        if (orientation) {
            [self changeVideoOrientation:orientation];
        }
    }
}

- (void) stopCapture
{
    if (self.isCapturing)
    {
        NSString* filename = [NSString stringWithFormat:@"capture%d.mov", _currentFile];
        NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
        NSURL* url = [NSURL fileURLWithPath:path];
        _currentFile++;
            
        _isCapturing = NO;
        dispatch_async(_captureQueue, ^{
            [_encoder finishWithCompletionHandler:^{
                _isCapturing = NO;
                _encoder = nil;
                NSLog(@"stoped capture");
                [self convertVideo:url name:filename];
            }];
        });
    }
}

- (void)convertVideo:(NSURL*)movURL name:(NSString*)videoName
{
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:movURL options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    NSString *mp4Quality = AVAssetExportPresetMediumQuality;
    if ([compatiblePresets containsObject:mp4Quality])
    {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset
                                                                              presetName:mp4Quality];

        NSString *mp4Name = [[videoName componentsSeparatedByString:@"."] objectAtIndex:0];
        NSString *mp4Path = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-%@.mp4", mp4Name];
        
        exportSession.outputURL = [NSURL fileURLWithPath: mp4Path];
        exportSession.outputFileType = AVFileTypeMPEG4;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Failed\n %@",[exportSession error]);
                    if (self.delegate && [self.delegate respondsToSelector:@selector(coreCamEngineThrowException:withError:)]) {
                        [self.delegate coreCamEngineThrowException:self withError:[exportSession error]];
                    }
                    break;
                    
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export canceled");
                    break;

                case AVAssetExportSessionStatusCompleted:
                {
                    NSLog(@"Successful!");
                    [self convertfinish:exportSession.outputURL];
                }
                    break;
                default:
                    break;
            }
            
        }];
    }

}
- (void)convertfinish:(NSURL*)fileURL
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:^(NSURL *assetURL, NSError *error){
        NSLog(@"save completed");
    }];

    
    if (self.delegate && [self.delegate respondsToSelector:@selector(coreCamEngineDidFinish:withURL:)]) {
        [self.delegate coreCamEngineDidFinish:self withURL:fileURL];
    }
}

- (void) pauseCapture
{
    if (self.isCapturing)
    {
        NSLog(@"Pausing capture");
        _isPaused = YES;
        _discont = YES;
    }
}

- (void) resumeCapture
{
    if (_isPaused)
    {
        NSLog(@"Resuming capture");
        _isPaused = NO;
    }
}

- (void) changeVideoOrientation:(AVCaptureVideoOrientation)orientation
{
    if ([_videoConnection isVideoOrientationSupported])
        [_videoConnection setVideoOrientation:orientation];
}

- (CMSampleBufferRef) adjustTime:(CMSampleBufferRef) sample by:(CMTime) offset
{
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++)
    {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

- (void) setAudioFormat:(CMFormatDescriptionRef) fmt
{
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
    _samplerate = asbd->mSampleRate;
    _channels = asbd->mChannelsPerFrame;
    
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    BOOL bVideo = YES;
    
    @synchronized(self)
    {
        if (!_isCapturing  || _isPaused)
        {
            return;
        }
        if (connection != _videoConnection)
        {
            bVideo = NO;
        }
        if ((_encoder == nil) && !bVideo)
        {
            CMFormatDescriptionRef fmt = CMSampleBufferGetFormatDescription(sampleBuffer);
            [self setAudioFormat:fmt];
            NSString* filename = [NSString stringWithFormat:@"capture%d.mov", _currentFile];
            NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
            _encoder = [RRCoreVideoEncoder encoderForPath:path Height:_cy width:_cx channels:_channels samples:_samplerate];
        }
        if (_discont)
        {
            if (bVideo)
            {
                return;
            }
            _discont = NO;

            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            CMTime last = bVideo ? _lastVideo : _lastAudio;
            if (last.flags & kCMTimeFlags_Valid)
            {
                if (_timeOffset.flags & kCMTimeFlags_Valid)
                {
                    pts = CMTimeSubtract(pts, _timeOffset);
                }
                CMTime offset = CMTimeSubtract(pts, last);
                NSLog(@"Setting offset from %s", bVideo?"video": "audio");
                NSLog(@"Adding %f to %f (pts %f)", ((double)offset.value)/offset.timescale, ((double)_timeOffset.value)/_timeOffset.timescale, ((double)pts.value/pts.timescale));
                
                if (_timeOffset.value == 0)
                {
                    _timeOffset = offset;
                }
                else
                {
                    _timeOffset = CMTimeAdd(_timeOffset, offset);
                }
            }
            _lastVideo.flags = 0;
            _lastAudio.flags = 0;
        }
        
        CFRetain(sampleBuffer);
        
        if (_timeOffset.value > 0)
        {
            CFRelease(sampleBuffer);
            sampleBuffer = [self adjustTime:sampleBuffer by:_timeOffset];
        }
        
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
        if (dur.value > 0)
        {
            pts = CMTimeAdd(pts, dur);
        }
        if (bVideo)
        {
            _lastVideo = pts;
        }
        else
        {
            _lastAudio = pts;
        }
    }
    [_encoder encodeFrame:sampleBuffer isVideo:bVideo];
    CFRelease(sampleBuffer);
}


@end
