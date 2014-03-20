//
//  P2PFileRequest.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, P2PFileRequestStatus)
{
    P2PFileRequestStatusUnknown = 0,
    P2PFileRequestStatusNotStarted,
    P2PFileRequestStatusCheckingAvailability,
    P2PFileRequestStatusRetreivingFile,
    P2PFileRequestStatusComplete,
    P2PFileRequestStatusFailed
};

typedef NS_ENUM(NSUInteger, P2PFileRequestError)
{
    /** No error */
    P2PFileRequestErrorNone = 0,
    
    /** Could not find a file with the specified ID, or no files matching the specified filename were found */
    P2PFileRequestErrorFileNotFound,
    
    /** The request was able to partially complete the request, but is missing chunks */
    P2PFileRequestErrorMissingChunks,
    
    /** The request doesn't know which file to retrieve because the specified filename matched multiple file IDs */
    P2PFileRequestErrorMultipleIdsForFile
};

@class P2PPeerNode, P2PFileRequest, P2PPeerFileAvailbilityResponse, P2PFileChunk;

@protocol P2PFileRequestDelegate <NSObject>

@required
/** A file request has completed.  The fileData property of the object will now contain the downloaded data
 
 @param fileRequest The file requested object that finished
 */
- (void)fileRequestDidComplete:(P2PFileRequest *)fileRequest;

/** The file request failed for some reason.  Check the errorCode parameter to find out why
 
 @param fileRequest The file request object that failed
 @param errorCode The reason the file request failed
 */
- (void)fileRequestDidFail:(P2PFileRequest *)fileRequest withError:(P2PFileRequestError)errorCode;

/** The request returned multiple Ids for a filename.  By the time this is called, the request will have already
 failed and a new one must be created with an explicit file Id
 
 @param fileRequest The file request object calling this delegate method
 @param fileIds An array of fileIds that match the filename requested
 @param filename The filename that returned multiple matches
 */
- (void)fileRequest:(P2PFileRequest *)fileRequest didFindMultipleIds:(NSArray *)fileIds forFileName:(NSString *)filename;



/** If the delegate wants to recieve updates as chunks arrive, this optional method can be implemented.

 @param fileRequest The file request object calling this delegate method
 @param chunk A chunk of the file that was recieved
 */
@optional
- (void)fileRequest:(P2PFileRequest *)fileRequest didRecieveChunk:(P2PFileChunk *)chunk;

@end

@interface P2PFileRequest : NSObject

/** Unique ID of the file */
@property (copy, nonatomic, readonly) NSString *fileId;
/** Human readable name of the file */
@property (copy, nonatomic) NSString *fileName;
/** Delegate to recieve callbacks with the status of the request */
@property (weak, nonatomic) id<P2PFileRequestDelegate> delegate;
/** Current state the request is in */
@property (nonatomic, readonly) P2PFileRequestStatus status;
/** The reason why the request failed */
@property (nonatomic, readonly) P2PFileRequestError errorCode;
/** Total number of chunks for complete file */
@property (nonatomic, readonly) NSUInteger totalChunks;
/** Number of chunks available from peers */
@property (nonatomic, readonly) NSUInteger chunksAvailable;
/** Number of chunks downloaded to the local machine */
@property (nonatomic, readonly) NSUInteger chunksReady;
/** Total completion of the request (0.0-100.0) */
@property (nonatomic, readonly) double progress;



/** Gets a list of file requests currently processing
 @return pendingFileRequests An array of P2PFileRequest objects currently working */
+ (NSArray *)pendingFileRequests;



/** Create a new request with just a file name.  If there are multiple files on the network with the same name, this request
 will exit with a P2PFileRequestErrorMultipleIdsForFile error.  It must then be recreated with the explicit fileID that you want.
 
 @param filename Thename of the file
 @return A new File Request object
 */
- (id)initWithFilename:(NSString *)filename;



/** Creates a new request looking for a specific file ID.  If no file with that ID is found on the network, this request
 will fail with error P2PFileRequestErrorFileNotFound
 
 @param fileId The file ID of the file you want to retrieve
 @return A new request object
 */
- (id)initWithFileId:(NSString *)fileId;



/** Creates a new file request.  Either fileID or filename must be specified.  One of them may be nil.
 
 @param fileId The ID of the file the request should get
 @param filename The name of a file the request should get
 @return A new file request object
 */
- (id)initWithFileId:(NSString *)fileId filename:(NSString *)filename;



/** Signals this file request object to start fetching the file.  The delegate for this object should be set before calling this method 
 */
- (void)getFile;

@end
