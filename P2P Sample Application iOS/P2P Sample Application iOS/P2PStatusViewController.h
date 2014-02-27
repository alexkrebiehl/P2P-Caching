//
//  P2PStatusViewController.h
//  P2P Sample Application iOS
//
//  Created by Tyler Darby on 2/22/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface P2PStatusViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *peersNumber;
@property (weak, nonatomic) IBOutlet UILabel *filesInCacheNumber;
@property (weak, nonatomic) IBOutlet UILabel *activeRequestsNumber;


@property (weak, nonatomic) IBOutlet UIView *circleView;

@property (strong, nonatomic) NSMutableOrderedSet *allPeers;

@end
