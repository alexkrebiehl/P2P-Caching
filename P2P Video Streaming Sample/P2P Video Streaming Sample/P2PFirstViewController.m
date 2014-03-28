//
//  P2PFirstViewController.m
//  P2P Video Streaming Sample
//
//  Created by Alex Krebiehl on 3/15/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFirstViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface P2PFirstViewController ()

@end

@implementation P2PFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    AVAsset *asset = [[AVAsset alloc] init];
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:asset];
    AVPlayer *p = [[AVPlayer alloc] initWithPlayerItem:item];
    
}

@end
