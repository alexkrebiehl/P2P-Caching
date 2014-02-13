//
//  P2PPeerLocator.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PLocatorDelegate.h"
#import "P2PPeerLocator.h"
#import <netinet/in.h>
#import <sys/socket.h>
#import "P2PPeerNode.h"




@implementation P2PPeerLocator
{
    NSNetServiceBrowser *_serviceBrowser;
}

- (void)beginSearching
{
    if ( _serviceBrowser == nil )
    {
        _serviceBrowser = [[NSNetServiceBrowser alloc] init];
        [_serviceBrowser setDelegate:self];
        [_serviceBrowser searchForServicesOfType:P2P_BONJOUR_SERVICE_TYPE inDomain:P2P_BONJOUR_SERVICE_DOMAIN];
    }
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    NSLog(@"---- Beginning search for peers ----");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
    NSLog(@"******** ERROR SEARCHING FOR PEERS ********");
    NSLog(@"Error code: %@", [errorDict objectForKey:NSNetServicesErrorCode]);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    if ( [aNetService.name isEqualToString:P2P_BONJOUR_SERVICE_NAME] )
    {
        P2PPeerNode *aPeer = [[P2PPeerNode alloc] initWithNetService:aNetService];
        [self.delegate peerLocator:self didFindPeer:aPeer];
    }

}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    if ( [aNetService.name isEqualToString:P2P_BONJOUR_SERVICE_NAME] )
    {
        // Find a good way to do this
    }
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    NSLog(@"---- Stopping peer search ----");
}





@end

//// Keys for dictionary returned after resolving peer's IP and port
//const NSString *P2PPeerLocatorPeerAddressKey =  @"P2PPeerLocatorPeerAddressKey";
//const NSString *P2PPeerLocatorPeerPortKey =     @"P2PPeerLocatorPeerPortKey";
//
//
//@implementation P2PPeerLocator
//{
//    NSMutableArray *services;
//    NSNetServiceBrowser *serviceBrowser;
//    NSNetService *service;
//    
//    BOOL searching;
//    
//    NSInputStream		*_inStream;
//	NSOutputStream		*_outStream;
//	BOOL				inReady;
//	BOOL				outReady;
//    
//    NSMutableData * dataBuffer;
//}
//
//-(void)openStreams
//{
//	_inStream.delegate = self;
//	[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//	[_inStream open];
//	_outStream.delegate = self;
//	[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//	[_outStream open];
//}
//
//-(id)init
//{
//	if ( self = [super init] )
//	{
//
//	}
//    return self;
//}
//
//- (void)beginSearching
//{
//	service = [[NSNetService alloc] initWithDomain:P2P_BONJOUR_SERVICE_DOMAIN
//											  type:P2P_BONJOUR_SERVICE_TYPE
//											  name:P2P_BONJOUR_SERVICE_NAME];
//	[service setDelegate:self];
//	[service resolveWithTimeout:0.0];
//}
//
//- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)streamEvent
//{
//    NSLog(@"handleEvent: %lu",streamEvent);
//    NSInputStream * istream;
//    switch(streamEvent)
//    {
//        case NSStreamEventHasBytesAvailable:
//            NSLog(@"NSStreamEventHasBytesAvailable");
//            uint8_t oneByte;
//            NSInteger actuallyRead = 0;
//            istream = (NSInputStream *)stream;
//            if (!dataBuffer) {
//                dataBuffer = [[NSMutableData alloc] initWithCapacity:2048];
//            }
//            actuallyRead = [istream read:&oneByte maxLength:1];
//            if (actuallyRead == 1) {
//                [dataBuffer appendBytes:&oneByte length:1];
//            }
//            if (oneByte == '\n') {
//                // We've got the carriage return at the end of the echo. Let's set the string.
//                NSString * string = [[NSString alloc] initWithData:dataBuffer encoding:NSUTF8StringEncoding];
//                NSLog(@"%@",string);
//                dataBuffer = nil;
//            }
//            break;
//        case NSStreamEventEndEncountered:
//            NSLog(@"NSStreamEventEndEncountered");
//            //[self closeStreams];
//            break;
//        case NSStreamEventHasSpaceAvailable:
//            NSLog(@"NSStreamEventHasSpaceAvailable");
//            break;
//        case NSStreamEventErrorOccurred:
//            NSLog(@"NSStreamEventErrorOccurred");
//            break;
//        case NSStreamEventOpenCompleted:
//            NSLog(@"NSStreamEventOpenCompleted");
//            break;
//        case NSStreamEventNone:
//            NSLog(@"NSStreamEventNone");
//        default:
//            break;
//    }
//}
//
//#pragma mark - NSNetServiceDelegate Methods
//
//- (void)netServiceWillResolve:(NSNetService *)sender
//{
//    LogSelector();
//    
//    serviceBrowser = [[NSNetServiceBrowser alloc] init];
//	if(!serviceBrowser) {
//        NSLog(@"The NSNetServiceBrowser couldn't be allocated and initialized.");
//	}
//	serviceBrowser.delegate = self;
//	[serviceBrowser searchForServicesOfType:P2P_BONJOUR_SERVICE_TYPE inDomain:P2P_BONJOUR_SERVICE_DOMAIN];
//}
//
//- (void)netServiceWillPublish:(NSNetService *)netService
//{
//    LogSelector();
//    [services addObject:netService];
//}
//
//- (void)netServiceDidPublish:(NSNetService *)sender
//{
//    LogSelector();
//}
//
//- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
//{
//    LogSelector();
//}
//
//- (void)netServiceDidResolveAddress:(NSNetService *)netService
//{
//    LogSelector();
//
//    // There can be multiple IP addresses pointing to the same peer.
//    // For now, we will just use the first one in the list.
//    //
//    // Perhaps in the future, we'll track all of them.  I'm not sure if there is really a benifit to having
//    // multiple addresses for each device, however....
//    //
//    // I noticed that the machine this is running on gets returned here, so one of these multiple addresses should be 127.0.0.1
//    // If thats the case, we wont have to explicitly check the local device's cache.  If we treat the local device like any other peer,
//    // it should always be the first choice of 'peers' to check since it would have an instantanous response time.
//    
//    NSDictionary *addr = [self getAddressAndPortFromData:[netService.addresses objectAtIndex:0]];
//    
//    NSLog(@"%@", [NSString stringWithFormat:@"Resolved (%@) :%@ -> %@:%@\n",
//                  netService.name, [netService hostName], [addr objectForKey:P2PPeerLocatorPeerAddressKey], [addr objectForKey:P2PPeerLocatorPeerPortKey]]);
//    
//    
//    
//    P2PPeer *peer = [[P2PPeer alloc] initWithIpAddress:[addr objectForKey:P2PPeerLocatorPeerAddressKey]
//                                                  port:[[addr objectForKey:P2PPeerLocatorPeerPortKey] unsignedIntegerValue]
//                                                domain:[netService hostName]];
//    
//    [self.delegate peerLocator:self didFindPeer:peer];
//    
//    [self openStreams];
//}
//
//
//// Some insight from StackOverflow...
//// http://stackoverflow.com/questions/938521/iphone-bonjour-nsnetservice-ip-address-and-port/4976808#4976808
//// Convert binary NSNetService data to an IP Address string
//- (NSDictionary *)getAddressAndPortFromData:(NSData *)data
//{
//    char addressBuffer[INET6_ADDRSTRLEN];
//
//    memset(addressBuffer, 0, INET6_ADDRSTRLEN);
//    
//    typedef union
//    {
//        struct sockaddr sa;
//        struct sockaddr_in ipv4;
//        struct sockaddr_in6 ipv6;
//    } ip_socket_address;
//    
//    ip_socket_address *socketAddress = (ip_socket_address *)[data bytes];
//    
//    if ( socketAddress && (socketAddress->sa.sa_family == AF_INET || socketAddress->sa.sa_family == AF_INET6) )
//    {
//        const char *addressStr = inet_ntop( socketAddress->sa.sa_family,
//                                           (socketAddress->sa.sa_family == AF_INET ? (void *)&(socketAddress->ipv4.sin_addr) : (void *)&(socketAddress->ipv6.sin6_addr)),
//                                           addressBuffer,
//                                           sizeof(addressBuffer));
//        
//        int port = ntohs(socketAddress->sa.sa_family == AF_INET ? socketAddress->ipv4.sin_port : socketAddress->ipv6.sin6_port);
//        
//        if ( addressStr && port )
//        {
//            NSLog(@"Found service at %s:%d", addressStr, port);
//            return @{ P2PPeerLocatorPeerAddressKey : [NSString stringWithCString:addressStr encoding:NSUTF8StringEncoding],
//                         P2PPeerLocatorPeerPortKey : @( port ) };
//            
//        }
//    }
//    return nil;
//}
//
//- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
//{
//    LogSelector();
//}
//
//- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data
//{
//    LogSelector();
//}
//
//- (void)netServiceDidStop:(NSNetService *)netService
//{
//    LogSelector();
//    [services removeObject:netService];
//}
//
//
//
//
//
//
//
//
//#pragma mark - NSNetServiceBrowserDelegate Methods
//
//- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing
//{
//    LogSelector();
//}
//
//- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing
//{
//    LogSelector();
//}
//
//- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
//{
//    LogSelector();
//    
////    if ( [netService.name isEqualToString:P2P_BONJOUR_SERVICE_NAME] )
////    {
////        NSLog( @"Found P2P Service: %@", netService.addresses );
////        
////        P2PPeer *peer = [[P2PPeer alloc] initWithIpAddress:@"127.0.0.1"];    // IP Address just to get something going...
////        [self.delegate peerLocator:self didFindPeer:peer];
//        
//        /*
//        NSInputStream		*inStream;
//        NSOutputStream		*outStream;
//        if ( ![netService getInputStream:&inStream outputStream:&outStream] )
//        {
//            P2PLog( P2PLogLevelError, @"Failed connecting to server" );
//            return;
//        }
//        _inStream=inStream;
//        _outStream=outStream;
//         */
////    }
////    else
////    {
////        P2PLog( P2PLogLevelDebug, @"found other service: %@", netService.name );
////    }
//}
//
//- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
////    NSLog(@"didRemoveService: %@", netService.name);
//    LogSelector();
//}
//
//- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo {
////    NSLog(@"didNotSearch: %@", errorInfo);
//    LogSelector();
//}
//
//- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser {
////    NSLog(@"netServiceBrowserWillSearch");
//    LogSelector();
//}
//
//- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser {
////    NSLog(@"netServiceBrowserDidStopSearch");
//    LogSelector();
//    NSAssert(NO, @"Why did we stop?");
//}


//@end
