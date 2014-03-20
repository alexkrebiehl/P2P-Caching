//
//  P2PAddFileViewController.h
//  P2P Sample Application iOS
//
//  Created by Alex Krebiehl on 3/17/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <UIKit/UIKit.h>

@class P2PAddFileViewController;
@protocol P2PAddFileViewControllerDelegate <NSObject>

- (void)addFileController:(P2PAddFileViewController *)controller didSelectFileToAdd:(NSString *)filename;

@end

@interface P2PAddFileViewController : UIViewController

@property (weak, nonatomic) id<P2PAddFileViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *filenameLabel;
- (IBAction)getFileButtonPressed:(id)sender;

@end
