//
//  P2PPeer.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/31/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//



#import "P2PPeerNode.h"
#import "SimplePing.h"
#import "P2PFileRequest.h"
#import "P2PFileChunkRequest.h"
#import "P2PFileChunk.h"
#import "P2PPeerFileAvailbilityResponse.h"
#import "P2PPeerFileAvailibilityRequest.h"

@interface P2PPeerNode() <NSNetServiceDelegate, NSStreamDelegate>

@end


@implementation P2PPeerNode
{
    NSMutableArray *_pendingFileAvailibilityRequests;
    NSMutableArray *_pendingFileChunkRequests;
}

- (id)init
{
    return [self initWithNetService:nil];
}

- (id)initWithNetService:(NSNetService *)netService
{
    if ( self = [super init] )
    {
        NSAssert( netService != nil, @"Cannot init with a nil netService!" );
        
        _isReady = NO;
        
        _netService = netService;
        _netService.delegate = self;
    }
    return self;
}

- (void)preparePeer
{
    // Resolve addresses
//    [_netService resolveWithTimeout:0];
    
    // open streams
    NSInputStream		*inStream;
    NSOutputStream		*outStream;
    if ( [_netService getInputStream:&inStream outputStream:&outStream] )
    {
        P2PLog( P2PLogLevelNormal, @"%@ - Successfully connected to peer's stream", self);
        [self takeOverInputStream:inStream outputStream:outStream]; // forService:_netService];
        [self peerDidBecomeReady];
    }
    else
    {
        P2PLog( P2PLogLevelError, @"***** Failed connecting to server *******" );
        [self peerIsNoLongerReady];
    }
    
}

// Some insight from StackOverflow...
// http://stackoverflow.com/questions/938521/iphone-bonjour-nsnetservice-ip-address-and-port/4976808#4976808
// Convert binary NSNetService data to an IP Address string
//- (void)getAddressAndPort
//{
//    if ( [[_netService addresses] count] > 0 )
//    {
//        NSData *data = [[_netService addresses] objectAtIndex:0];
//        
//        char addressBuffer[INET6_ADDRSTRLEN];
//        
//        memset(addressBuffer, 0, INET6_ADDRSTRLEN);
//        
//        typedef union
//        {
//            struct sockaddr sa;
//            struct sockaddr_in ipv4;
//            struct sockaddr_in6 ipv6;
//        } ip_socket_address;
//        
//        ip_socket_address *socketAddress = (ip_socket_address *)[data bytes];
//        
//        if ( socketAddress && (socketAddress->sa.sa_family == AF_INET || socketAddress->sa.sa_family == AF_INET6) )
//        {
//            const char *addressStr = inet_ntop( socketAddress->sa.sa_family,
//                                               (socketAddress->sa.sa_family == AF_INET ? (void *)&(socketAddress->ipv4.sin_addr) : (void *)&(socketAddress->ipv6.sin6_addr)),
//                                               addressBuffer,
//                                               sizeof(addressBuffer));
//            
//            int port = ntohs(socketAddress->sa.sa_family == AF_INET ? socketAddress->ipv4.sin_port : socketAddress->ipv6.sin6_port);
//            
//            if ( addressStr && port )
//            {
//                P2PLog( P2PLogLevelDebug, @"%@ - Found service at %s:%d", self, addressStr, port);
//                _ipAddress = [NSString stringWithCString:addressStr encoding:NSUTF8StringEncoding];
//                _port = port;
//                [self peerDidBecomeReady];
//            }
//        }
//    }
//    else
//    {
//        _ipAddress = nil;
//        _port = 0;
//        [self peerIsNoLongerReady];
//    }
//}

- (void)handleRecievedObject:(id)object from:(P2PNodeConnection *)sender
{
    if ( [object isMemberOfClass:[P2PPeerFileAvailbilityResponse class]] )
    {
        [self didRecieveFileAvailabilityResponse:object];
    }
    else if ( [object isMemberOfClass:[P2PFileChunk class]] )
    {
        [self didRecieveFileChunk:object];
    }
    else
    {
        NSAssert( NO, @"Unable to handle recieved file: %@", object );
    }
}

- (void)peerDidBecomeReady
{
    _isReady = YES;
    [self.delegate peerDidBecomeReady:self];
}

- (void)peerIsNoLongerReady
{
    _isReady = NO;
    [self.delegate peerIsNoLongerReady:self];
}




#pragma mark - NetService Delegate Methods
//- (void)netServiceDidResolveAddress:(NSNetService *)sender
//{
//    [self getAddressAndPort];
//}


- (void)netServiceDidStop:(NSNetService *)sender
{
    [self peerIsNoLongerReady];
}



#pragma mark - File Handling
- (void)getFileAvailabilityForRequest:(P2PFileRequest *)request
{
    if ( _pendingFileAvailibilityRequests == nil )
    {
        _pendingFileAvailibilityRequests = [[NSMutableArray alloc] init];
    }
    
    [_pendingFileAvailibilityRequests addObject:request];
    

    P2PPeerFileAvailibilityRequest *availabilityRequest = [[P2PPeerFileAvailibilityRequest alloc] initWithFileId:request.fileId];
    [self transmitObject:availabilityRequest];
    P2PLogDebug(@"%@ - File availability request sent", self);
}

- (void)didRecieveFileAvailabilityResponse:(P2PPeerFileAvailbilityResponse *)response
{
    // Find out what request this response is for...
    for ( P2PFileRequest *aRequest in _pendingFileAvailibilityRequests )
    {
        //good enough for now..
        if ( [aRequest.fileId isEqualToString:response.fileId] )
        {
            // found the request.....
            [aRequest peer:self didRecieveAvailibilityResponse:response];
            [_pendingFileAvailibilityRequests removeObject:aRequest];
            return;
        }
    }
}

- (void)requestFileChunk:(P2PFileChunkRequest *)request
{
    if ( _pendingFileChunkRequests == nil )
    {
        _pendingFileChunkRequests = [[NSMutableArray alloc] init];
    }
    
    [_pendingFileChunkRequests addObject:request];
    [self transmitObject:request];
}

- (void)didRecieveFileChunk:(P2PFileChunk *)fileChunk
{
    for ( P2PFileChunkRequest *aRequest in _pendingFileChunkRequests )
    {
        //good enough for now..
        if ( [aRequest.fileId isEqualToString:fileChunk.fileId] && aRequest.chunksId == fileChunk.chunkId )
        {
            // found the request.....
            [aRequest peer:self didRecieveChunk:fileChunk];
            [_pendingFileAvailibilityRequests removeObject:aRequest];
            return;
        }
    }
}






#pragma mark - Logging
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %@>", NSStringFromClass([self class]), self.netService.name];
}
@end
