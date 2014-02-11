//
//  P2PPeerFileAvailbilityResponse.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface P2PPeerFileAvailbilityResponse : NSObject <NSCoding>

@property (copy, readonly) NSString *fileName;
@property (strong, nonatomic, readonly) NSArray *availableChunks;   // I dont like using objects for this... I feel like this might cause a bottleneck
@property (nonatomic, readonly) NSUInteger chunkSizeInBytes;

- (id)initWithFileName:(NSString *)fileName availableChunks:(NSArray *)chunks chunkSize:(NSUInteger)chunkSizeInBytes;

@end
