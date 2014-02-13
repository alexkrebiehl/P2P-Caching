//
//  P2PFileChunkRequest.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/13/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface P2PFileChunkRequest : NSObject

- (id)initWithFilename:(NSString *)fileName chunks:(NSArray *)chunksNeeded chunkSize:(NSUInteger)chunkSize;

@end
