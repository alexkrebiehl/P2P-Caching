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




@interface P2PNode : NSObject <P2PIncomingDataDelegate>

@end






/*
 
 Networking tools
 ----------------------------------------
 
 
 */





typedef NS_ENUM(uint8_t, P2PNetworkTransmissionType)
{
    P2PNetworkTransmissionTypeUnknown = 0,
    P2PNetworkTransmissionTypeObject,
    P2PNetworkTransmissionTypeData
};

NSData* prepareObjectForTransmission( id<NSCopying> object );

NSData* prepareDataForTransmission( NSData *dataToTransmit );














typedef NS_ENUM(NSUInteger, P2PIncomingDataStatus)
{
    P2PIncomingDataStatusNotStarted = 0,
    P2PIncomingDataStatusStarting,
    P2PIncomingDataStatusReadingHeader,
    P2PIncomingDataStatusReadingData,
    P2PIncomingDataStatusFinished,
    P2PIncomingDataStatusError
};

static const NSUInteger P2PIncomingDataFileSizeUnknown = NSUIntegerMax;

/** This objected will handle incomming data to sort it out, make sure it is valid data, etc.
 
 After the download is complete, control of the input stream is automatically returned back to the
 calling calling object (presumably the delegate).  This class will inform the delegate that the download
 is complete and the data is now available.
 
 */
@interface P2PIncomingData : NSObject <NSStreamDelegate>


@property (nonatomic, readonly) NSUInteger fileSize;
@property (readonly, nonatomic) P2PIncomingDataStatus status;
@property (weak, nonatomic) id<P2PIncomingDataDelegate> delegate;
@property (weak, nonatomic) NSInputStream *stream;
@property (strong, nonatomic, readonly) id downloadedData;          // Downloaded data may either be an object (such as a request)
@property (readonly, nonatomic) P2PNetworkTransmissionType type;    // Or a binary data file
                                                                    // The correct one can be found by using the type property
                                                                    // well, now that i think about it, it will probably always be an object,
                                                                    // because a binary file will be wrapped in a P2PFileChunk object
                                                                    // so..... we'll come back to this

- (id)initWithInputStream:(NSInputStream *)stream;

- (void)takeOverStream;

@end