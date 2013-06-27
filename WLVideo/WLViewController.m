//
//  WLViewController.m
//  WLVideo
//
//  Created by wangliang on 13-6-27.
//  Copyright (c) 2013年 wangliang. All rights reserved.
//

#import "WLViewController.h"
#import "WLCoreVideoManger.h"
@interface WLViewController ()<WLCoreVideoManagerDelegate>
@property(nonatomic,strong)UIButton *playButton;
@property(nonatomic,strong)UILabel *timeLabel;
@property(nonatomic,strong)UIView *videoView;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property(nonatomic,strong)WLCoreVideoManger *videoManger;
@end
static BOOL bRecording = NO;

@implementation WLViewController

- (id)init
{
    self = [super init];
    if (self) {
        bRecording = NO;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    self.view.backgroundColor = [UIColor colorWithRed:0x29/255.f green:0x98/255.f blue:0xd7/255.f alpha:1.0];
    
    //Init subviews
    self.playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.playButton setFrame:CGRectMake(10, self.view.frame.size.height-50, 50, 30)];
    [self.playButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.playButton setTitle:@"start" forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playButtonChick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playButton];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width-60, self.playButton.frame.origin.y, 50, 30)];
    self.timeLabel.text = @"0.0s";
    [self.view addSubview:self.timeLabel];
    
    self.videoView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, self.view.frame.size.width-10.f, self.view.frame.size.height-70)];
    self.videoView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.videoView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self initVideoManger];
}

- (void)initVideoManger
{
    if (!self.videoManger) {
		self.videoManger = [[WLCoreVideoManger alloc] init];
		
		[self.videoManger setDelegate:self];
        
		if ([self.videoManger setupSession]) {
            // Create video preview layer and add it to the UI
			self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[self.videoManger session]];
			UIView *view = self.videoView;
			CALayer *viewLayer = [view layer];
			[viewLayer setMasksToBounds:YES];
			
			CGRect bounds = [view bounds];
			[self.videoPreviewLayer setFrame:bounds];
			
//			if ([self.videoPreviewLayer isOrientationSupported]) {
//				[self.videoPreviewLayer setOrientation:AVCaptureVideoOrientationPortrait];
//			}
			
			[self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
			
			[viewLayer insertSublayer:self.videoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
						
            // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[[self.videoManger session] startRunning];
			});
			
		}
	}
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)playButtonChick:(UIButton*)button
{
    if (!bRecording) {
        [self.videoManger startRecording];
    }else{
        [self.videoManger stopRecording];
    }
}

- (void) captureManager:(WLCoreVideoManger *)captureManager didFailWithError:(NSError *)error
{
    bRecording = NO;
    [self.playButton setTitle:@"start" forState:UIControlStateNormal];
}
- (void) captureManagerRecordingBegan:(WLCoreVideoManger *)captureManager
{
    bRecording = YES;
    [self.playButton setTitle:@"stop" forState:UIControlStateNormal];
}
- (void) captureManagerRecordingFinished:(WLCoreVideoManger *)captureManager
{
    bRecording = NO;
    [self.playButton setTitle:@"start" forState:UIControlStateNormal];
}
@end
