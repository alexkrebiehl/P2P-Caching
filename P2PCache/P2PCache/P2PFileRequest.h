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

@class P2PPeerNode, P2PFileRequest, P2PPeerFileAvailbilityResponse;

@protocol P2PFileRequestDelegate <NSObject>

- (void)fileRequestDidComplete:(P2PFileRequest *)fileRequest;

@end

@interface P2PFileRequest : NSObject

@property (copy, nonatomic, readonly) NSString *fileId;     // Hash of the file
@property (copy, nonatomic) NSString *fileName;   // Name of the file requested
@property (strong, nonatomic, readonly) NSData *fileData;   // Populated after the file is completely loaded
@property (weak, nonatomic) id<P2PFileRequestDelegate> delegate;
@property (nonatomic, readonly) P2PFileRequestStatus status;

- (id)initWithFileId:(NSString *)fileId;

- (void)getFile;


// Callbacks for peer objects
- (void)peer:(P2PPeerNode *)peer didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)response;

@end
