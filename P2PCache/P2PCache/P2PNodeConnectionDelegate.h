//
//  P2PNodeConnectionDelegate.h
//  P2PCache
//
//  Created by Alex Krebiehl on 4/17/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class P2PNodeConnection, P2PTransmittableObject;

typedef NS_ENUM( NSUInteger, P2PIncomingDataStatus )
{
    /** The connection is not currently downloading any data */
    P2PIncomingDataStatusNotStarted = 0,
 
    /** The object is currently reading the header of the transmission */
    P2PIncomingDataStatusReadingHeader,
    
    /** The object is currently reading the data contents of the transmission */
    P2PIncomingDataStatusReadingData,
    
    /** The object is currently reading the footer of the transmission */
    P2PIncomingDataStatusReadingFooter,
};


/** If this transmission encountered an error, this property will explain the reasoning */
typedef NS_ENUM( NSUInteger, P2PIncomingDataErrorCode )
{
    /** There is no error */
    P2PIncomingDataErrorCodeNoError = 0,
    
    /** For some reason we just recieved a NULL character... still trying to figure out why this happens... */
    P2PIncomingDataErrorCodeNoData,
    
    /** Something about the header was off on the transmission */
    P2PIncomingDataErrorCodeInvalidHeader,
    
    /** An error occoured in the stream... connection probably dropped */
    P2PIncomingDataErrorCodeStreamError,
    
    /** Recieved file was currupt */
    P2PIncomingDataErrorCodeCurruptFile
};


@protocol P2PNodeConnectionDelegate <NSObject>

/** The object finished downloading an object and as ready to be processed
 
 @param connection The @c P2PNodeConnection object that completed a download
 @param object The object that the connection downloaded
 */
- (void)nodeConnection:(P2PNodeConnection *)connection didRecieveObject:(P2PTransmittableObject *)object;


/** The connection failed to download an object.
 
 @param connection The @c P2PNodeConnection object that failed
 @param errorCode The reason for failure
 */
- (void)nodeConnection:(P2PNodeConnection *)connection failedToDownloadWithError:(P2PIncomingDataErrorCode)errorCode;


/** Called when a node's stream is closing.  Subclasses should override this method and perform any cleanup necessicary.  After
 this method is called, attempting to continue using the node is an error
 
 @param node The connection for the node that ended
 */
- (void)nodeConnectionDidEnd:(P2PNodeConnection *)node;

@end
