//
//  P2PNode.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/12/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>


/** Since the peer and server will share a lot of the same functionality,
 I decided to go ahead and just make them children of this superclass.
 
 All of the common networking tools will be found here */

@class P2PIncomingData;
@protocol P2PIncomingDataDelegate <NSObject>

- (void)dataDidFinishLoading:(P2PIncomingData *)loader;

@end




@interface P2PNode : NSObject <NSStreamDelegate>

/** This method will be called when the node recieves an object.  Subclasses MUST override this method
 and handle any incoming objects.  Subclasses don't need to call this method directly.
 
 @param object The recieved object
 @param sender The node which this object came from
 */
- (void)handleRecievedObject:(id)object from:(P2PNode *)sender;

@end

@interface P2PNode (MethodsNotToBeSubclassed)

/** Call this method when recieving input/output streams from a server.  
 
 @param inStream An input stream supplied by a NSNetService instance
 @param outStream An output stream supplied by a NSNetService instance
 @param service The service supplying the streams
 */
- (void)takeOverInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream forService:(NSNetService *)service;

/** Transmits an object to a peer's cache server.
 
 @param object The object to send
 */
- (void)transmitObject:(id<NSCoding>)object;


/** Transmits an object to a peer that is connected through a NSNetService object.
 This method will be used by a server instance of P2PNode to specify which peer to send the object to.
 
 @param object An object to send
 @param service The NSNetService instance object connected to a peer.
 */
- (void)transmitObject:(id<NSCoding>)object toNetService:(NSNetService *)service;

@end







/*
 
 Networking tools
 ----------------------------------------
 
 
 */







//NSData* prepareObjectForTransmission( id<NSCopying> object );
//
//NSData* prepareDataForTransmission( NSData *dataToTransmit );
















