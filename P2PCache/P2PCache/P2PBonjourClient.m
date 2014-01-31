//
//  P2PBonjourClient.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PBonjourClient.h"
#import <netinet/in.h>
#import <sys/socket.h>


@implementation P2PBonjourClient
{
    NSMutableArray *services;
    NSNetServiceBrowser *serviceBrowser;
    NSNetService *service;
    
    BOOL searching;
    
    NSInputStream		*_inStream;
	NSOutputStream		*_outStream;
	BOOL				inReady;
	BOOL				outReady;
    
    NSMutableData * dataBuffer;
}

-(void)openStreams
{
	_inStream.delegate = self;
	[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream open];
	_outStream.delegate = self;
	[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream open];
}

-(id)init
{
    service = [[NSNetService alloc] initWithDomain:P2P_BONJOUR_SERVICE_DOMAIN
                                              type:P2P_BONJOUR_SERVICE_TYPE
                                              name:P2P_BONJOUR_SERVICE_NAME];
    [service setDelegate:self];
    [service resolveWithTimeout:0.0];
    return self;
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)streamEvent
{
    NSLog(@"handleEvent: %lu",streamEvent);
    NSInputStream * istream;
    switch(streamEvent)
    {
        case NSStreamEventHasBytesAvailable:
            NSLog(@"NSStreamEventHasBytesAvailable");
            uint8_t oneByte;
            NSInteger actuallyRead = 0;
            istream = (NSInputStream *)stream;
            if (!dataBuffer) {
                dataBuffer = [[NSMutableData alloc] initWithCapacity:2048];
            }
            actuallyRead = [istream read:&oneByte maxLength:1];
            if (actuallyRead == 1) {
                [dataBuffer appendBytes:&oneByte length:1];
            }
            if (oneByte == '\n') {
                // We've got the carriage return at the end of the echo. Let's set the string.
                NSString * string = [[NSString alloc] initWithData:dataBuffer encoding:NSUTF8StringEncoding];
                NSLog(@"%@",string);
                dataBuffer = nil;
            }
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered");
            //[self closeStreams];
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"NSStreamEventHasSpaceAvailable");
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"NSStreamEventErrorOccurred");
            break;
        case NSStreamEventOpenCompleted:
            NSLog(@"NSStreamEventOpenCompleted");
            break;
        case NSStreamEventNone:
            NSLog(@"NSStreamEventNone");
        default:
            break;
    }
}

#pragma mark - NSNetServiceDelegate Methods

- (void)netServiceWillResolve:(NSNetService *)sender {
    NSLog(@"netServiceWillResolve");
    
    serviceBrowser = [[NSNetServiceBrowser alloc] init];
	if(!serviceBrowser) {
        NSLog(@"The NSNetServiceBrowser couldn't be allocated and initialized.");
	}
	serviceBrowser.delegate = self;
	[serviceBrowser searchForServicesOfType:P2P_BONJOUR_SERVICE_TYPE inDomain:P2P_BONJOUR_SERVICE_DOMAIN];
}

- (void)netServiceWillPublish:(NSNetService *)netService
{
    NSLog(@"netServiceWillPublish");
    [services addObject:netService];
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    NSLog(@"netServiceDidPublish");
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    NSLog(@"didNotPublish");
}

- (void)netServiceDidResolveAddress:(NSNetService *)netService {
    NSLog(@"netServiceDidResolveAddress");
    NSString *name = nil;
    NSData *address = nil;
    struct sockaddr_in *socketAddress = nil;
    NSString *ipString = nil;
    int port;
    name = [netService name];
    address = [[netService addresses] objectAtIndex: 0];
    socketAddress = (struct sockaddr_in *) [address bytes];
    
    /*  Not sure what this is about yet..... come back to it
    ipString = [NSString stringWithFormat: @"%s",inet_ntoa(socketAddress->sin_addr)];
     */
    port = socketAddress->sin_port;
    // This will print the IP and port for you to connect to.
    NSLog(@"%@", [NSString stringWithFormat:@"Resolved:%@-->%@:%hu\n", [service hostName], ipString, port]);
    [self openStreams];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    NSLog(@"didNotResolve: %@",errorDict);
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data {
    NSLog(@"didUpdateTXTRecordData");
}

- (void)netServiceDidStop:(NSNetService *)netService {
    NSLog(@"netServiceDidStop");
    [services removeObject:netService];
}

#pragma mark - NSNetServiceBrowserDelegate Methods

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing {
    NSLog(@"didFindDomain");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing {
    NSLog(@"didRemoveDomain");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
    NSLog(@"didFindService: %@  lenght:%d",netService.name,[netService.name length]);
    if ( [netService.name isEqualToString:P2P_BONJOUR_SERVICE_NAME] )
    {
        NSLog(@"didFindService: %@",netService.addresses);
        NSInputStream		*inStream;
        NSOutputStream		*outStream;
        if (![netService getInputStream:&inStream outputStream:&outStream]) {
            NSLog(@"Failed connecting to server");
            return;
        }
        _inStream=inStream;
        _outStream=outStream;
    }
    else
    {
        NSLog(@"found other service: %@", netService.name);
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
    NSLog(@"didRemoveService");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo {
    NSLog(@"didNotSearch");
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser {
    NSLog(@"netServiceBrowserWillSearch");
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser {
    NSLog(@"netServiceBrowserDidStopSearch");
}


@end
