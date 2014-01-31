//
//  P2PCacheProtocol.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PCacheProtocol.h"
#import "CanonicalRequest.h"

@implementation P2PCacheProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    // In the future, we will have to make sure that the PeerManager's requests
    // dont come through here.  Peer caching our list of peers wont be very helpful...
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    // 'Normalization' of a URL.  This function was written by Apple (CanonicalRequest.h)
    return CanonicalRequestForRequest( request );
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client
{
    return [super initWithRequest:request cachedResponse:cachedResponse client:client];
}





- (void)startLoading
{
    // First, check local cache
    //......
    
    
    
    // Check with peers
    //......
    
    
    
    // No cached version found.  Go out to the interwebs
    //......
}



- (void)stopLoading
{
    
}

@end
