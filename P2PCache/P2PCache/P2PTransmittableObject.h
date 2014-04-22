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
     amount of time (in seconds) before the object fails if it doesn't
     receive a response
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
    P2PTransmissionErrorNoConnectionToNode
};



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
@property (nonatomic, weak) P2PNode *associatedNode;



/** The node that is handling this object should call this method if a response is received for this @c requestId
 
 @param peer The peer that received a response to this request
 @param receivedObject The response that was received
 */
- (void)peer:(P2PNode *)peer didRecieveResponse:(P2PTransmittableObject *)receivedObject;

/** The node that is handling this object could not send it to the node.  This method should be overridden by subclasses
 
 @param peer The peer that received a response to this request
 @param error The error that occurred
 */
- (void)peer:(P2PNode *)peer failedToSendObjectWithError:(P2PTransmissionError)error;

/** If @c shouldWaitForResponse is set to @c YES and the node associated with the request fails, this method should be called.  
 If this object is waiting for a response, this method should be overridden by subclasses
 
 @param peer The peer that received a response to this request
 @param error The error that occurred
 */
- (void)peer:(P2PNode *)peer failedToRecieveResponseWithError:(P2PTransmissionError)error;

/** Called with a peer started sending the object.  This method triggers timeout timers (if @c shouldWaitForResponse is set to @c YES) and
 sets the @c associatedNode for this transmission
 
 @param peer The peer that is sending this object
 */
- (void)peerDidBeginToSendObject:(P2PNode *)peer;

@end
