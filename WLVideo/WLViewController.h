//
//  WLViewController.h
//  WLVideo
//
//  Created by wangliang on 13-6-27.
//  Copyright (c) 2013年 wangliang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *captureView;
@property(nonatomic,strong)IBOutlet UIButton *playBtn;
@property(nonatomic,strong)IBOutlet UIButton *pauseBtn;
- (IBAction)playAction:(id)sender;
- (IBAction)pauseAction:(id)sender;
@end
