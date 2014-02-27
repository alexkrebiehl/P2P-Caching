//
//  P2PCachesFilesViewController.h
//  P2P Sample Application iOS
//
//  Created by Tyler Darby on 2/27/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface P2PCachesFilesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
