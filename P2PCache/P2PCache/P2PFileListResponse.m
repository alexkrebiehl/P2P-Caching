//
//  P2PFileListResponse.m
//  P2PCache
//
//  Created by Alex Krebiehl on 4/25/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileListResponse.h"

static NSString *P2PFileListResponseFilenamesKey = @"Filenames";

@implementation P2PFileListResponse

- (id)initWithFilenames:(NSArray *)filenames
{
    if ( self = [super init] )
    {
        _filenames = filenames;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ( self = [super initWithCoder:aDecoder] )
    {
        _filenames = [aDecoder decodeObjectForKey:P2PFileListResponseFilenamesKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.filenames forKey:P2PFileListResponseFilenamesKey];
}

@end
