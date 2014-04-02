//
//  P2PStatusViewController.m
//  P2P Sample Application iOS
//
//  Created by Tyler Darby on 2/22/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PStatusViewController.h"
#import "P2PCache/P2PCache.h"
#import "P2PPeerManager.h"
#import "P2PFileRequest.h"

@interface P2PStatusViewController ()


@end

@implementation P2PStatusViewController
@synthesize peersNumber = _peersNumber;

@synthesize filesInCacheNumber = _filesInCacheNumber;
@synthesize activeRequestsNumber = _activeRequestsNumber;
@synthesize allPeers = _allPeers;
@synthesize circleView = _circleView;





- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    _circleView.layer.cornerRadius = 10;
    
    [self registerForNotifications];
    
    
}

- (void)registerForNotifications {
    
    
    //Server Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverWillStartNotification:) name:P2PServerNodeWillStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidStartNotification:) name:P2PServerNodeDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidStopNotification:) name:P2PServerNodeDidStopNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverFailedToStartNotification:) name:P2PServerNodeFailedToStartNotification object:nil];
    
    //Peer Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peersUpdatedNotification:) name:P2PPeerManagerPeerListUpdatedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeFileRequestsUpdated:) name:P2PActiveFileRequestsDidChange object:nil];
}


#pragma mark - Server Status Updates
//Server started, sets circleView to green to indicate connection to user
- (void)serverDidStartNotification:(NSNotification *)notification{
    _circleView.backgroundColor = [UIColor colorWithRed:63/255.0 green:166/255.0 blue:73/255.0 alpha:1];
}

- (void)serverWillStartNotification:(NSNotification *)notification{
    _circleView.backgroundColor = [UIColor darkGrayColor];
}

- (void)serverDidStopNotification:(NSNotification *)notification{
    _circleView.backgroundColor = [UIColor colorWithRed:63/255.0 green:166/255.0 blue:73/255.0 alpha:1];
}

- (void)serverFailedToStartNotification:(NSNotification *)notification{
    _circleView.backgroundColor = [UIColor colorWithRed:255.0 green:0/255.0 blue:0/255.0 alpha:1];
}


- (void)peersUpdatedNotification:(NSNotification *)notification
{
//    NSArray *activePeers = [[P2PPeerManager sharedManager] activePeers];
//    if ( _allPeers == nil )
//    {
//        _allPeers = [[NSMutableOrderedSet alloc] initWithArray:activePeers copyItems:NO];
//    }
//    else
//    {
//        [_allPeers addObjectsFromArray:activePeers];
//    }
    
    _peersNumber.text = [NSString stringWithFormat:@"%lu", (unsigned long)[[[P2PPeerManager sharedManager] activePeers] count]];
}

- (void)activeFileRequestsUpdated:(NSNotification *)notification
{
    _activeRequestsNumber.text = [NSString stringWithFormat:@"%lu", (unsigned long)[[P2PFileRequest pendingFileRequests] count]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
