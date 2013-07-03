//
//  WLViewController.m
//  WLVideo
//
//  Created by wangliang on 13-6-27.
//  Copyright (c) 2013年 wangliang. All rights reserved.
//

#import "WLViewController.h"
#include "RRCoreCamEngine.h"
@interface WLViewController ()<RRCoreCamEngineDelegate>
{
    RRCoreCamEngine *_engine;
}
@end

static BOOL bRecording = NO;
static BOOL bPause = NO;
@implementation WLViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        bRecording = NO;
        bPause = NO;
    }
    return self;
}

- (void)dealloc
{
    _engine.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
        
    [self.playBtn setTitle:@"start" forState:UIControlStateNormal];
    self.pauseBtn.hidden = YES;
    [self.pauseBtn setTitle:@"pause" forState:UIControlStateNormal];
    
    CGRect rt = self.playBtn.frame;
    rt.origin.y = self.view.bounds.size.height - self.playBtn.frame.size.height - self.navigationController.navigationBar.frame.size.height - 10.f;
    self.playBtn.frame = rt;
    
    rt = self.pauseBtn.frame;
    rt.origin.y = self.view.bounds.size.height - self.pauseBtn.frame.size.height - self.navigationController.navigationBar.frame.size.height - 10.f;
    self.pauseBtn.frame = rt;
    
    [self initEngine];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
        return YES;
    }
    return NO;
}

- (void)initEngine
{
    _engine = [RRCoreCamEngine engine];
    _engine.delegate = self;
    
    [_engine startUp];
    
    AVCaptureVideoPreviewLayer *videoLayer = [_engine getPreviewLayer];
    videoLayer.frame = self.captureView.bounds;
    [videoLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [self.captureView.layer addSublayer:videoLayer];
}

- (IBAction)playAction:(id)sender {
    if (!bRecording) {
        [_engine startCapture:AVCaptureVideoOrientationPortrait];
        [self.playBtn setTitle:@"stop" forState:UIControlStateNormal];
        bRecording = YES;
    }else{
        [_engine stopCapture];
        [self.playBtn setTitle:@"start" forState:UIControlStateNormal];
        bRecording = NO;
    }
    
    self.pauseBtn.hidden = !bRecording;
}

- (IBAction)pauseAction:(id)sender {
    if (!bPause) {
        [_engine pauseCapture];
        [self.pauseBtn setTitle:@"resume" forState:UIControlStateNormal];
        bPause = YES;
    }else{
        [_engine resumeCapture];
        [self.pauseBtn setTitle:@"pause" forState:UIControlStateNormal];
        bPause = NO;
    }
}


- (void)coreCamEngineDidFinish:(RRCoreCamEngine*)engine withURL:(NSURL*)fileURL
{
 
}

- (void)coreCamEngineThrowException:(RRCoreCamEngine *)engine withError:(NSError *)error
{
}
@end
