//
//  P2PFileRequest.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class P2PFileInfo;

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
/** A file request has completed.  The fileData property of the object will now contain the downloaded data.  Will be called on the main thread.
 
 @param fileRequest The file requested object that finished
 */
- (void)fileRequestDidComplete:(P2PFileRequest *)fileRequest;


/** The file request failed for some reason.  Check the errorCode parameter to find out why.  Will be called on the main thread.
 
 @param fileRequest The file request object that failed
 @param errorCode The reason the file request failed
 */
- (void)fileRequestDidFail:(P2PFileRequest *)fileRequest withError:(P2PFileRequestError)errorCode;


/** The request returned multiple Ids for a filename.  By the time this is called, the request will have already
 failed and a new one must be created with an explicit file Id.  Will be called on the main thread.
 
 @param fileRequest The file request object calling this delegate method
 @param fileIds An array of fileIds that match the filename requested
 @param filename The filename that returned multiple matches
 */
- (void)fileRequest:(P2PFileRequest *)fileRequest didFindMultipleIds:(NSArray *)fileIds forFileName:(NSString *)filename;

@end





@interface P2PFileRequest : NSObject

/** Delegate to recieve callbacks with the status of the request */
@property (weak, nonatomic) id<P2PFileRequestDelegate> delegate;

/** Current state the request is in */
@property (nonatomic, readonly) P2PFileRequestStatus status;

/** The reason why the request failed */
@property (nonatomic, readonly) P2PFileRequestError errorCode;

/** Information about the file (total file size, chunks on hand/available).  This property will be populated if either
 1) the file info was supplied when initializing the file request,
 2) a match for a file was found if the filename or fileId was found */
@property (strong, nonatomic, readonly) P2PFileInfo *fileInfo;



/** Gets a list of file requests currently processing
 
 @return pendingFileRequests An array of P2PFileRequest objects currently working 
 */
+ (NSArray *)pendingFileRequests;



/** Create a new request with just a file name.  If there are multiple files on the network with the same name, this request
 will exit with a P2PFileRequestErrorMultipleIdsForFile error.  It must then be recreated with the explicit fileID that you want.
 
 @param filename Thename of the file
 @return A new File Request object or nil if the file request couldn't be created
 */
- (id)initWithFilename:(NSString *)filename;



/** Creates a new request looking for a specific file ID.  If no file with that ID is found on the network, this request
 will fail with error P2PFileRequestErrorFileNotFound
 
 @param fileId The file ID of the file you want to retrieve
 @return A new request object or nil if the file request couldn't be created
 */
- (id)initWithFileId:(NSString *)fileId;



/** Creates a new file request.  Either fileID or filename must be specified.
 
 @param fileId The ID of the file the request should get
 @param filename The name of a file the request should get
 @return A new file request object or nil if the file request couldn't be created
 */
- (id)initWithFileId:(NSString *)fileId filename:(NSString *)filename;


/** Designated initializer.  Creates a new file request for the fileInfo object given
 
 @param info A P2PFileInfo object to request from peers
 @return A new file request object or nil if the file request couldn't be created
 */
- (id)initWithFileInfo:(P2PFileInfo *)info;



/** Signals this file request object to start fetching the file.  The delegate for this object should be set before calling this method 
 */
- (void)getFile;

@end
