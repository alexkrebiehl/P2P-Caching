//
//  P2PFileManager.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileManager.h"
#import "P2PPeerFileAvailbilityResponse.h"
#import "P2PPeerFileAvailibilityRequest.h"

@implementation P2PFileManager

static P2PFileManager *sharedInstance = nil;
+ (P2PFileManager *)sharedManager
{
    if (sharedInstance == nil)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ sharedInstance = [[[self class] alloc] init]; });
    }
    return sharedInstance;
}

- (P2PPeerFileAvailbilityResponse *)fileAvailibilityForRequest:(P2PPeerFileAvailibilityRequest *)request
{
    // TODO
    
    P2PPeerFileAvailbilityResponse *response = [[P2PPeerFileAvailbilityResponse alloc] initWithFileName:request.fileName
                                                                                        availableChunks:@[ @(1) ]
                                                                                              chunkSize:1024];
    return response;
}

@end
