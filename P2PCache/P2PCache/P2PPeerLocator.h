//
//  P2PPeerLocator.h
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "P2PPeerLocatorProtocol.h"

@interface P2PPeerLocator : NSObject <NSNetServiceDelegate,NSNetServiceBrowserDelegate,NSStreamDelegate>

@property (weak, nonatomic) id<P2PPeerLocatorProtocol> delegate;

/** Find peers on the network.  Results will be reported to the P2PPeerLocatorProtocol delegate */
- (void)beginSearching;

@end
