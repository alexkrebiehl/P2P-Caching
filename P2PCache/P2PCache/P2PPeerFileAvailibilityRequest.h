//
//  P2PPeerFileAvailibilityRequest.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class P2PPeerFileAvailbilityResponse, P2PPeerFileAvailibilityRequest;

@protocol P2PPeerFileAvailabilityDelegate <NSObject>

/** Delegate method called by a request object indicating that it did receive a response
 
 @param request The request object that received a response
 @param response The response that was received
 */
- (void)fileAvailabilityRequest:(P2PPeerFileAvailibilityRequest *)request didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)response;

/** Delegate method called by a request object that has failed.
 
 @param request The request object that failed
 @param error The error that occurred
 */
- (void)fileAvailabilityRequest:(P2PPeerFileAvailibilityRequest *)request failedWithError:(P2PTransmissionError)error;

@end



@interface P2PPeerFileAvailibilityRequest : P2PTransmittableObject

/** The file identifier that we are looking for information on */
@property (readonly, nonatomic, copy) NSString *fileId;

/** The name of the file we're trying to find information on */
@property (copy, nonatomic) NSString *fileName;

/** The delegate to recieve updates on this request */
@property (weak, nonatomic) id<P2PPeerFileAvailabilityDelegate> delegate;


/** Creates a new request with a file identifier or a file name.  If only a file name is supplied, 
 responses to this object will attempt to locate a matching @c fileId.  At most one of the parameters
 may be @c nil
 
 @param fileId The file identifier that we are looking for information on
 @param filename The name of the file we're trying to find information on
 @return A new request object
 */
- (id)initWithFileId:(NSString *)fileId filename:(NSString *)filename;

@end
