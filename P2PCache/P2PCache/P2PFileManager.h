//
//  P2PFileManager.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

static const NSUInteger P2PFileManagerFileChunkSize = 1024 * 64;  // 64k File chunk size

@class P2PPeerFileAvailibilityRequest, P2PPeerFileAvailbilityResponse, P2PFileChunk, P2PFileChunkRequest;

@interface P2PFileManager : NSObject

+ (P2PFileManager *)sharedManager;

- (P2PPeerFileAvailbilityResponse *)fileAvailibilityForRequest:(P2PPeerFileAvailibilityRequest *)request;

- (P2PFileChunk *)fileChunkForRequest:(P2PFileChunkRequest *)request;

@end