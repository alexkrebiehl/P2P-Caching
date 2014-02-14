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
#import "P2PFileChunk.h"
#import "P2PFileChunkRequest.h"

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
    // Respond to a client with what chunks of a file we have
    
    P2PPeerFileAvailbilityResponse *response = [[P2PPeerFileAvailbilityResponse alloc] initWithFileName:request.fileName
                                                                                        availableChunks:@[ @(1) ]
                                                                                              chunkSize:P2PFileManagerFileChunkSize];
    return response;
}

- (P2PFileChunk *)fileChunkForRequest:(P2PFileChunkRequest *)request
{
    // Populate a file chunk here
    P2PFileChunk *chunk = [[P2PFileChunk alloc] initWithData:nil startPosition:0 fileName:nil];
    
    
    
    
    
    return chunk;
}

+ (NSString *)pathForDocumentsDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [paths objectAtIndex:0];
}

@end
