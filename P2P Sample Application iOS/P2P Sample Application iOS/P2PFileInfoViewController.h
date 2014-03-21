//
//  P2PFileInfoViewController.h
//  P2P Sample Application iOS
//
//  Created by Alex Krebiehl on 3/20/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <UIKit/UIKit.h>

@class P2PFileInfo;

@interface P2PFileInfoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *chunksOnDiskLabel;
@property (weak, nonatomic) IBOutlet UILabel *chunksAvailableLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalChunksLabel;
@property (weak, nonatomic) IBOutlet UILabel *percentCompleteLabel;
@property (weak, nonatomic) P2PFileInfo *fileInfo;

- (IBAction)deleteFileButtonPressed:(id)sender;
@end
