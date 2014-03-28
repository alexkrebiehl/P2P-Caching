//
//  P2PTransmittableObject.h
//  P2PCache
//
//  Created by Alex Krebiehl on 3/26/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

enum
{
    /** If @c shouldWaitForResponse is set to @c YES, this is the maximum
     ammount of time (in seconds) before the object fails if it doesn't
     recieve a response
     */
    P2PTransmittableObjectTimeout = 10
};

typedef NS_ENUM(NSInteger, P2PTransmissionError)
{
    /** No error */
    P2PTransmissionErrorNone = 0,
    
    /** Timed out when waiting for a response */
    P2PTransmissionErrorTimeout,
    
    /** We lost connection to the peer */
    P2PTransmissionErrorPeerNoLongerReady
};


NSNumber* nextRequestId();

@class P2PNode;

@interface P2PTransmittableObject : NSObject <NSCoding>

/**
 By default, this object doesn't wait for a response.  Subclasses that require a response, such as a request
 for availability or request for a chunk, should set this to @c YES when initialzing
 */
@property (nonatomic) bool shouldWaitForResponse;

/** The ID used to keep track of responses for this request.  This ID is automatically populated if @c shouldWaitForResponse
 is set to @c YES
 */
@property (nonatomic, strong, readonly) NSNumber *requestId;

/** If this object is a response to an earlier request, that request ID will be listed here so it can be re-associated
 after transmission
 */
@property (nonatomic, strong) NSNumber *responseForRequestId;

/** The peer node that is handling this transmission */
@property (weak, nonatomic) P2PNode *associatedNode;

- (void)peer:(P2PNode *)peer didRecieveResponse:(P2PTransmittableObject *)recievedObject;

- (void)peer:(P2PNode *)peer failedToSendObjectWithError:(P2PTransmissionError)error;

- (void)peer:(P2PNode *)peer failedToRecieveResponseWithError:(P2PTransmissionError)error;

- (void)peerDidBeginToSendObject:(P2PNode *)peer;

@end
