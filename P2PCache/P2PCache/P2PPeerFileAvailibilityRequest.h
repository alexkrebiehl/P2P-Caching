//
//  P2PPeerFileAvailibilityRequest.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

#warning Implement Timeout

@class P2PPeerFileAvailbilityResponse, P2PPeerFileAvailibilityRequest, P2PPeerNode;

@protocol P2PPeerFileAvailabilityDelegate <NSObject>

- (void)fileAvailabilityRequest:(P2PPeerFileAvailibilityRequest *)request didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)response;

- (void)fileAvailabilityRequest:(P2PPeerFileAvailibilityRequest *)request failedWithEvent:(NSStreamEvent)event;

@end



@interface P2PPeerFileAvailibilityRequest : P2PTransmittableObject

@property (readonly, nonatomic, copy) NSString *fileId;       // File's hash
//@property (readonly, nonatomic) NSUInteger requestId;
@property (copy, nonatomic) NSString *fileName;
@property (weak, nonatomic) id<P2PPeerFileAvailabilityDelegate> delegate;

- (id)initWithFileId:(NSString *)fileId;
- (id)initWithFilename:(NSString *)filename;
- (id)initWithFileId:(NSString *)fileId filename:(NSString *)filename;

- (void)didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)response;
- (void)failedWithStreamEvent:(NSStreamEvent)event;

@end
