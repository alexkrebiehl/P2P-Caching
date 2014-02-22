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
@synthesize serverStatusIcon = _serverStatusIcon;
@synthesize filesInCacheNumber = _filesInCacheNumber;
@synthesize activeRequestsNumber = _activeRequestsNumber;





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
    
	// Do any additional setup after loading the view.
    
    [self registerForNotifications];
    
    
}

- (void)registerForNotifications {
    
    
    //Server Notifications
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverWillStartNotification:) name:P2PServerNodeWillStartNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidStartNotification:) name:P2PServerNodeDidStartNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidStopNotification:) name:P2PServerNodeDidStopNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverFailedToStartNotification:) name:P2PServerNodeFailedToStartNotification object:nil];
//    
    //Peer Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peersUpdatedNotification:) name:P2PPeerManagerPeerListUpdatedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeFileRequestsUpdated:) name:P2PActiveFileRequestsDidChange object:nil];
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
//    [self.peerListTableView reloadData];
//    [self.peersFoundLabel setStringValue:[NSString stringWithFormat:@"%lu", (unsigned long)[activePeers count]]];
    
    _peersNumber.text = [NSString stringWithFormat:@"%lu", (unsigned long)[[[P2PPeerManager sharedManager] activePeers] count]];
}

- (void)activeFileRequestsUpdated:(NSNotification *)notification
{
    _activeRequestsNumber.text = [NSString stringWithFormat:@"%lu", [[P2PFileRequest pendingFileRequests] count]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
