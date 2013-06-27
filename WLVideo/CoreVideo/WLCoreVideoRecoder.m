//
//  WLCoreVideoRecoder.m
//  WLVideo
//
//  Created by wangliang on 13-6-27.
//  Copyright (c) 2013年 wangliang. All rights reserved.
//

#import "WLCoreVideoRecoder.h"
#import <AVFoundation/AVFoundation.h>

@interface WLCoreVideoRecoder (FileOutputDelegate) <AVCaptureFileOutputRecordingDelegate>
@end

@implementation WLCoreVideoRecoder

@synthesize session;
@synthesize fileOutput;
@synthesize outputFileURL;
@synthesize delegate;

- (id) initWithSession:(AVCaptureSession *)aSession outputFileURL:(NSURL *)anOutputFileURL
{
    self = [super init];
    if (self != nil) {
        self.fileOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ([aSession canAddOutput:self.fileOutput])
            [aSession addOutput:self.fileOutput];

		self.session = aSession;
        self.outputFileURL = anOutputFileURL;
        
    }
    
	return self;
}

- (void) dealloc
{
    [[self session] removeOutput:[self fileOutput]];
}

-(BOOL)recordsVideo
{
	AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self fileOutput] connections]];
	return [videoConnection isActive];
}

-(BOOL)recordsAudio
{
	AVCaptureConnection *audioConnection = [self connectionWithMediaType:AVMediaTypeAudio fromConnections:[[self fileOutput] connections]];
	return [audioConnection isActive];
}

-(BOOL)isRecording
{
    return [[self fileOutput] isRecording];
}

-(void)startRecordingWithOrientation:(AVCaptureVideoOrientation)videoOrientation;
{
    AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self fileOutput] connections]];
    if ([videoConnection isVideoOrientationSupported])
        [videoConnection setVideoOrientation:videoOrientation];
    
    [[self fileOutput] startRecordingToOutputFileURL:[self outputFileURL] recordingDelegate:self];
}

-(void)stopRecording
{
    [[self fileOutput] stopRecording];
}

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
    for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return connection;
			}
		}
	}
	return nil;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
      fromConnections:(NSArray *)connections
{
    if ([self.delegate respondsToSelector:@selector(recorderRecordingDidBegin:)]) {
        [[self delegate] recorderRecordingDidBegin:self];
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)anOutputFileURL
                    fromConnections:(NSArray *)connections
                              error:(NSError *)error
{
    if ([[self delegate] respondsToSelector:@selector(recorder:recordingDidFinishToOutputFileURL:error:)]) {
        [[self delegate] recorder:self recordingDidFinishToOutputFileURL:anOutputFileURL error:error];
    }
}

@end