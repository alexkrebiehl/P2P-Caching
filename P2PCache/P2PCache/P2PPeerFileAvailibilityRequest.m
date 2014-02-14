//
//  P2PPeerFileAvailibilityRequest.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PPeerFileAvailibilityRequest.h"

static NSString *P2PAvailabilityRequestFilenameKey =    @"FileName";
static NSString *P2PAvailabilityRequestIdKey =          @"ID";

@implementation P2PPeerFileAvailibilityRequest


- (id)init
{
    return [self initWithFileName:nil];
}

static NSUInteger currentId = 1;
- (id)initWithFileName:(NSString *)fileName
{
    if ( self = [super init] )
    {
        _requestId = currentId++;
        _fileName = fileName;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.fileName forKey:P2PAvailabilityRequestFilenameKey];
    [aCoder encodeObject:@( self.requestId ) forKey:P2PAvailabilityRequestIdKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSString *fileName = [aDecoder decodeObjectForKey:P2PAvailabilityRequestFilenameKey];
    if ( self = [self initWithFileName:fileName] )
    {
        _requestId = [[aDecoder decodeObjectForKey:P2PAvailabilityRequestIdKey] unsignedIntegerValue];
    }
    return self;
}

@end
