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

/** Possible file ID matches for the request */
@property (copy, nonatomic) NSArray *matchingFileIds;

/** Human readable name of the file */
@property (copy, readonly) NSString *fileName;

/** What chunks are available */
@property (strong, nonatomic) NSArray *availableChunks;

/** The length of each chunk */
@property (nonatomic) NSUInteger chunkSizeInBytes;

/** The total size of the completed file */
@property (nonatomic) NSUInteger totalFileLength;

/** The identifier for this request */
@property (nonatomic, readonly) NSUInteger requestId;

/** Creates a new response object from a given request
 @param request The request this object is responding to
 @return A new file availability response object
 */
- (id)initWithRequest:(P2PPeerFileAvailibilityRequest *)request;

@end
