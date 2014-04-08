//
//  P2PIncomingData.h
//  P2PCache
//
//  Created by Alex Krebiehl on 4/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class P2PIncomingData;

typedef uint32_t file_size_type;
typedef uint32_t crc_type;

static const file_size_type P2PIncomingDataFileSizeUnknown = UINT32_MAX;

@protocol P2PIncomingDataDelegate <NSObject>

/** The object finished downloading an object and as ready to be processed
 
 @param loader The @c P2PIncomingData object that has finished loading
 */
- (void)dataDidFinishLoading:(P2PIncomingData *)loader;


/** The object failed to download an object.  Check the @c errorCode property to find out why
 
 @param loader The @c P2PIncomingData object that failed
 */
- (void)dataFailedToDownload:(P2PIncomingData *)loader;

@end

typedef NS_ENUM( NSUInteger, P2PIncomingDataStatus )
{
    /** The defualt status when the object is first created */
    P2PIncomingDataStatusNotStarted = 0,
    
    /** The object is preparing to start reading the header of the packet */
    P2PIncomingDataStatusStarting,
    
    /** The object is currently reading the header of the transmission */
    P2PIncomingDataStatusReadingHeader,
    
    /** The object is currently reading the data contents of the transmission */
    P2PIncomingDataStatusReadingData,
    
    /** The object is currently reading the footer of the transmission */
    P2PIncomingDataStatusReadingFooter,
    
    /** The object has been successfully downloaded and can be read through the @c downloadedData property */
    P2PIncomingDataStatusFinished,
    
    /** The transmission has failed.  Check the @c errorCode property to find out the reason */
    P2PIncomingDataStatusError
};

typedef NS_ENUM( NSUInteger, P2PIncomingDataErrorCode )
{
    /** There is no error */
    P2PIncomingDataErrorCodeNoError = 0,
    
    /** For some reason we just recieved a NULL character... still trying to figure out why this happens... */
    P2PIncomingDataErrorCodeNoData,
    
    /** Something about the header was off on the transmission */
    P2PIncomingDataErrorCodeInvalidHeader,
    
    /** The peer disconnected in the middle of the transmission */
    P2PIncomingDataErrorCodeStreamEnded,
    
    /** An error occoured in the stream... connection probably dropped */
    P2PIncomingDataErrorCodeStreamError,
    
    /** Recieved file was currupt */
    P2PIncomingDataErrorCodeCurruptFile
};


/** This object will handle incomming data to sort it out, make sure it is valid data, etc.
 
 After the download is complete, control of the input stream is automatically returned back to the
 calling calling object (presumably an instance of P2PNode).  This class will inform the delegate that the download
 is complete and the data is now available.
 
 Header/Data format
 
 
 New format:
 64-bit file size
 data
 32-bit checksum (crc_type)
 
 */
@interface P2PIncomingData : NSObject <NSStreamDelegate>

/** The collection of I/O streams this loader is using */
@property (weak, nonatomic, readonly) P2PNodeConnection *connection;

/** The current status of this loader object */
@property (readonly, nonatomic) P2PIncomingDataStatus status;

/** If this transmission encountered an error, this property will explain the reasoning */
@property (readonly, nonatomic) P2PIncomingDataErrorCode errorCode;

/** A delegate to recieve callbacks for status updates of this transmission */
@property (weak, nonatomic) id<P2PIncomingDataDelegate> delegate;

/** After the download is complete, this property will hold the data of the transmitted object */
@property (strong, nonatomic, readonly) NSData *downloadedData;

/** Creates a new incoming data object to download a @c P2PTranmittableObject.  This object should be created if
 a node recieves a @c NSStreamHasBytesAvailable code
 
 @param connection The @c P2PNodeConnection object that has data available for download
 @return A new @c P2PIncomingData object to handle recieving data
 */
- (id)initWithConnection:(P2PNodeConnection *)connection;

/** Instructs the @c P2PIncomingData object to take over the connection's I/O streams and start downloading data.  The @c delegate of
 this object should be set before calling this method
 */
- (void)startDownloadingData;

@end
