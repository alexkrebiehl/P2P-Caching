//
//  P2PFileListRequest.h
//  P2PCache
//
//  Created by Alex Krebiehl on 4/25/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

@class P2PFileListRequest, P2PFileListResponse;

@protocol P2PFileListRequestDelegate <NSObject>

/** Delegate method called by a request object indicating that it did receive a response
 
 @param request The request object that received a response
 @param response The response that was received
 */
- (void)fileListRequest:(P2PFileListRequest *)request didRecieveResponse:(P2PFileListResponse *)response;


/** Delegate method called by a request object that has failed.
 
 @param request The request object that failed
 @param error The error that occurred
 */
- (void)fileListRequest:(P2PFileListRequest *)request failedWithError:(P2PTransmissionError)error;

@end


/** Requests a list of filenames on hand from a node */
@interface P2PFileListRequest : P2PTransmittableObject

/** The delegate to recieve updates on this request */
@property (weak, nonatomic) id<P2PFileListRequestDelegate> delegate;

@end
