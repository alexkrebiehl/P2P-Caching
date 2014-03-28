//
//  P2PPeerFileAvailbilityResponse.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class P2PPeerFileAvailibilityRequest, P2PPeerNode;

@interface P2PPeerFileAvailbilityResponse : P2PTransmittableObject

/** Possible file ID matches for the request */
@property (copy, nonatomic) NSArray *matchingFileIds;

/** Human readable name of the file */
@property (copy, readonly) NSString *fileName;

/** Chunks that are available from the responding peer */
@property (strong, nonatomic) NSMutableSet *availableChunks;

/** The length of each chunk */
@property (nonatomic) NSUInteger chunkSizeInBytes;

/** The total number of chunks for the complete file */
@property (nonatomic) NSUInteger totalChunks;

/** The identifier for this request */
//@property (nonatomic, readonly) NSUInteger requestId;

/** The peer handling this response */
//@property (weak, nonatomic) P2PPeerNode *owningPeer;

/** Creates a new response object from a given request
 @param request The request this object is responding to
 @return A new file availability response object
 */
- (id)initWithRequest:(P2PPeerFileAvailibilityRequest *)request;

@end
