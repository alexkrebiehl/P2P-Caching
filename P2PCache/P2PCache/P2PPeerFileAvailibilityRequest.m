//
//  P2PPeerFileAvailibilityRequest.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PPeerFileAvailibilityRequest.h"

static NSString *P2PAvailabilityRequestFilenameKey = @"FileName";

@implementation P2PPeerFileAvailibilityRequest

- (id)initWithFileName:(NSString *)fileName
{
    if ( self = [super init] )
    {
        _fileName = fileName;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.fileName forKey:P2PAvailabilityRequestFilenameKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSString *fileName = [aDecoder decodeObjectForKey:P2PAvailabilityRequestFilenameKey];
    return [self initWithFileName:fileName];
}

@end
