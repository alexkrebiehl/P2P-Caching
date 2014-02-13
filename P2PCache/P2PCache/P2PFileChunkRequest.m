//
//  P2PFileChunkRequest.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/13/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileChunkRequest.h"

@implementation P2PFileChunkRequest

- (id)init
{
    return [self initWithFilename:nil chunks:nil chunkSize:0];
}

- (id)initWithFilename:(NSString *)fileName chunks:(NSArray *)chunksNeeded chunkSize:(NSUInteger)chunkSize
{
    assert( fileName != nil );
    assert( chunksNeeded != nil );
    assert( chunkSize != 0 );
    
    if ( self = [super init] )
    {
        
    }
    return self;
}

@end
