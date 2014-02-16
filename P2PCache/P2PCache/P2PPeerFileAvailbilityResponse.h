//
//  P2PPeerFileAvailbilityResponse.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class P2PPeerFileAvailibilityRequest;

@interface P2PPeerFileAvailbilityResponse : NSObject <NSCoding>

@property (copy, nonatomic, readonly) NSString *fileId;
@property (copy, readonly) NSString *fileName;
@property (strong, nonatomic) NSArray *availableChunks;   // I dont like using objects for this... I feel like this might cause a bottleneck
@property (nonatomic) NSUInteger chunkSizeInBytes;
@property (nonatomic, readonly) NSUInteger requestId;               // This response is for a request of this ID

- (id)initWithRequest:(P2PPeerFileAvailibilityRequest *)request;

@end
