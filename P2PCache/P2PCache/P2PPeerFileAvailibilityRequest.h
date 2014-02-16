//
//  P2PPeerFileAvailibilityRequest.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class P2PPeerFileAvailbilityResponse;


@interface P2PPeerFileAvailibilityRequest : NSObject <NSCoding>

@property (readonly, nonatomic, copy) NSString *fileId;       // File's hash
@property (readonly, nonatomic) NSUInteger requestId;
@property (copy, nonatomic) NSString *fileName;

- (id)initWithFileId:(NSString *)fileId;

@end
