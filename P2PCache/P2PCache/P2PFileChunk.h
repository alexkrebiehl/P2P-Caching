//
//  P2PFileChunk.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

enum
{
    P2PFileChunkDefaultSize = 64 * 1024     // 64k chunks
};

@interface P2PFileChunk : NSObject <NSCoding>

@property (nonatomic, readonly, copy) NSString *fileId;
@property (nonatomic, readonly) NSUInteger  chunkId;
@property (nonatomic, readonly) NSData      *dataBlock;

- (id)initWithData:(NSData *)data chunkId:(NSUInteger)chunkId fileId:(NSString *)fileId;



@end
