//
//  P2PActiveTransfersWindowController.h
//  P2P Sample Application OS X
//
//  Created by Alex Krebiehl on 2/20/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface P2PActiveTransfersWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSComboBoxDelegate>


@property (weak) IBOutlet NSComboBox *fileNameComboBox;
@property (weak) IBOutlet NSTableView *tableView;

- (IBAction)requestFileButtonPressed:(id)sender;

@end
