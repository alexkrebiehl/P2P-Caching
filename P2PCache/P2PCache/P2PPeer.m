//
//  P2PPeer.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/31/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//



#import "P2PPeer.h"
#import "SimplePing.h"
#import "P2PFileRequest.h"
#import "P2PPeerFileAvailbilityResponse.h"
#import "P2PPeerFileAvailibilityRequest.h"

#import "P2PNetworkTool.h"

@interface P2PPeer() <NSNetServiceDelegate, NSStreamDelegate>//   <SimplePingDelegate>

// Private Properties
@property (nonatomic, strong) NSDate *lastPingSentTime;     // Track how long the ping took
@property (nonatomic, strong) SimplePing *pinger;           // Object pinging the peer
@property (nonatomic, strong) NSTimer *peerResponseTimer;   // Timer running the reoccouring pings

@end


@implementation P2PPeer
{
    NSInputStream *_inStream;
    NSOutputStream *_outStream;
    
    NSMutableData *_inStreamBuffer;
    NSMutableData *_outStreamBuffer;
    
    NSMutableArray *_pendingFileAvailibilityRequests;
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
        
        _peerIsReady = NO;
        
        _netService = netService;
        _netService.delegate = self;
    }
    return self;
}

- (void)preparePeer
{
    // Resolve addresses
    [_netService resolveWithTimeout:0];
    
    // open streams
    NSInputStream		*inStream;
    NSOutputStream		*outStream;
    if ( [_netService getInputStream:&inStream outputStream:&outStream] )
    {
        NSLog(@"PEER Successfully connected to peer's stream");
        _inStream = inStream;
        _outStream = outStream;
        
        _inStream.delegate = self;
        [_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_inStream open];
        
        _outStream.delegate = self;
        [_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_outStream open];
        
    }
    else
    {
        P2PLog( P2PLogLevelError, @"***** Failed connecting to server *******" );
        return;
    }
    
}


#pragma mark - Stream Delegate Methods
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSInputStream * istream;
    switch ( eventCode )
    {
        case NSStreamEventHasBytesAvailable:
            NSLog(@"PEER NSStreamEventHasBytesAvailable");
            uint8_t oneByte;
            NSInteger actuallyRead = 0;
            istream = (NSInputStream *)aStream;
            if ( _inStreamBuffer == nil )
            {
                _inStreamBuffer = [[NSMutableData alloc] initWithCapacity:2048];
            }
            actuallyRead = [istream read:&oneByte maxLength:1];
            if (actuallyRead == 1)
            {
                [_inStreamBuffer appendBytes:&oneByte length:1];
            }
            if (oneByte == '\n') {
                // We've got the carriage return at the end of the echo. Let's set the string.
                NSString * string = [[NSString alloc] initWithData:_inStreamBuffer encoding:NSUTF8StringEncoding];
                NSLog(@"PEER recieved data: %@",string);
                _inStreamBuffer = nil;
            }
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"PEER NSStreamEventEndEncountered");
            //[self closeStreams];
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"PEER %@ NSStreamEventHasSpaceAvailable", aStream);

            [self workOutputBuffer];

            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"PEER NSStreamEventErrorOccurred");
            break;
        case NSStreamEventOpenCompleted:
            NSLog(@"PEER %@ NSStreamEventOpenCompleted", aStream);
            break;
        case NSStreamEventNone:
            NSLog(@"PEER NSStreamEventNone");
        default:
            break;
    }

}


// Some insight from StackOverflow...
// http://stackoverflow.com/questions/938521/iphone-bonjour-nsnetservice-ip-address-and-port/4976808#4976808
// Convert binary NSNetService data to an IP Address string
- (void)getAddressAndPort
{
    if ( [[_netService addresses] count] > 0 )
    {
        NSData *data = [[_netService addresses] objectAtIndex:0];
        
        char addressBuffer[INET6_ADDRSTRLEN];
        
        memset(addressBuffer, 0, INET6_ADDRSTRLEN);
        
        typedef union
        {
            struct sockaddr sa;
            struct sockaddr_in ipv4;
            struct sockaddr_in6 ipv6;
        } ip_socket_address;
        
        ip_socket_address *socketAddress = (ip_socket_address *)[data bytes];
        
        if ( socketAddress && (socketAddress->sa.sa_family == AF_INET || socketAddress->sa.sa_family == AF_INET6) )
        {
            const char *addressStr = inet_ntop( socketAddress->sa.sa_family,
                                               (socketAddress->sa.sa_family == AF_INET ? (void *)&(socketAddress->ipv4.sin_addr) : (void *)&(socketAddress->ipv6.sin6_addr)),
                                               addressBuffer,
                                               sizeof(addressBuffer));
            
            int port = ntohs(socketAddress->sa.sa_family == AF_INET ? socketAddress->ipv4.sin_port : socketAddress->ipv6.sin6_port);
            
            if ( addressStr && port )
            {
                NSLog(@"Found service at %s:%d", addressStr, port);
                _ipAddress = [NSString stringWithCString:addressStr encoding:NSUTF8StringEncoding];
                _port = port;
            }
        }
    }
    else
    {
        _ipAddress = nil;
        _port = 0;
        [self peerIsNoLongerReady];
    }
}

- (void)peerDidBecomeReady
{
    _peerIsReady = YES;
    [self.delegate peerDidBecomeReady:self];
}

- (void)peerIsNoLongerReady
{
    _peerIsReady = NO;
    [self.delegate peerIsNoLongerReady:self];
}

- (void)transmitDataToPeer:(id)data
{
    NSData *preparedData;
    if ( [data conformsToProtocol:@protocol( NSCoding )] )
    {
        preparedData = prepareObjectForTransmission( data );
    }
    else if ( [data isMemberOfClass:[NSData class]] )
    {
        preparedData = prepareDataForTransmission( data );
    }
    else
    {
        NSAssert( NO, @"object must be NSData or implement NSCoding");
    }
    
    
    if ( _outStreamBuffer == nil )
    {
        _outStreamBuffer = [[NSMutableData alloc] initWithCapacity:preparedData.length];
    }
    
    
    
    
    // Add data to buffer
    [_outStreamBuffer appendData:preparedData];
    
    NSLog(@"sending: %@", _outStreamBuffer);
    
    [self workOutputBuffer];
}

- (void)workOutputBuffer
{
    if ( _outStreamBuffer != nil )
    {
        NSInteger bytesWritten = 0;
        while ( _outStreamBuffer.length > bytesWritten )
        {
            NSLog(@"working buffer");
            if ( ! _outStream.hasSpaceAvailable )
            {
                // If we're here, the buffer is full.  We should get an NSStreamEventHasSpaceAvailable event
                // soon, and then we'll call this method again.
                
                
                // Remove what we were able to write from the buffer.  This is a bad (slow) way of doing it though
                // Will have to replace this with a higher-performance method in the future
                [_outStreamBuffer replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
                return;
            }
            
            //sending NSData over to server
            NSInteger writeResult = [_outStream write:[_outStreamBuffer bytes] + bytesWritten
                                            maxLength:[_outStreamBuffer length] - bytesWritten];
            
            if ( writeResult == -1 )
                NSLog(@"error code here");
            else
            {
                bytesWritten += writeResult;
                NSLog(@"wrote %ld bytes to buffer", (long)writeResult );
            }
            
            
        }
        NSLog(@"finished transmitting data to peer");
        _outStreamBuffer = [[NSMutableData alloc] init]; // Reset buffer
    }
}

- (void)recievedDataFromPeer:(NSData *)data
{
    id recievedObject = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    // figure out what to do with the object
    if ( [recievedObject isMemberOfClass:[P2PPeerFileAvailbilityResponse class]] )
    {
        [self didRecieveFileAvailabilityResponse:recievedObject];
    }
}


#pragma mark - NetService Delegate Methods
- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    [self getAddressAndPort];
}






#pragma mark - File Handling
- (void)getFileAvailabilityForRequest:(P2PFileRequest *)request
{
    if ( _pendingFileAvailibilityRequests == nil )
    {
        _pendingFileAvailibilityRequests = [[NSMutableArray alloc] init];
    }
    
    [_pendingFileAvailibilityRequests addObject:request];
    
    // Package request up and send it off
    P2PPeerFileAvailibilityRequest *availibilityRequest = [[P2PPeerFileAvailibilityRequest alloc] initWithFileName:request.fileName];

    [self transmitDataToPeer:availibilityRequest];
    NSLog(@"File availability request sent to peer: %@", self);
    
}

- (void)didRecieveFileAvailabilityResponse:(P2PPeerFileAvailbilityResponse *)response
{
    // Find out what request this response is for...
    for ( P2PFileRequest *aRequest in _pendingFileAvailibilityRequests )
    {
        //good enough for now..
        if ( [aRequest.fileName isEqualToString:response.fileName] )
        {
            // found the request.....
            [aRequest peer:self didRecieveAvailibilityResponse:response];
            [_pendingFileAvailibilityRequests removeObject:aRequest];
            return;
        }
    }
}
















/* Designated initializer */
//- (id)initWithIpAddress:(NSString *)ipAddress port:(NSUInteger)port domain:(NSString *)domain
//{
//    if ( self = [super init] )
//    {
//        NSAssert(ipAddress != nil, @"Must supply an IP Address");
//        NSAssert(port != 0, @"Must provide a valid port");
//        
//        _ipAddress = ipAddress;
//        _port = port;
//        _domain = domain;
//        
//        _responseTime = P2PPeerNoResponse;
//        [self updateResponseTime];
//        [self startUpdatingResponseTime];
//    }
//    return self;
//}




//- (void)startUpdatingResponseTime
//{
//    // Dont do anything if there is already a timer going
//    if ( _peerResponseTimer == nil )
//    {
//        NSLog(@"%@ - starting ping loop", self);
//        _responseTime = P2PPeerNoResponse;
//        
//        
//        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:P2P_PEER_RESPONSE_INTERVAL
//                                                          target:self
//                                                        selector:@selector(updateResponseTime)
//                                                        userInfo:nil
//                                                         repeats:YES];
//        
//        // The tolerance allows the system to slightly vary when it fires our timer
//        // in order to have the least ammount of battery impact.
//        // ex 10 second timer with 10% tolerence will actually fire every 9-11 seconds
//        [timer setTolerance:P2P_PEER_RESPONSE_INTERVAL * P2P_PEER_RESPONSE_INTERVAL_TOLERANCE];
//        
//        _peerResponseTimer = timer;
//        _pinger = [SimplePing simplePingWithHostName:self.ipAddress];
//        _pinger.delegate = self;
//        [_pinger start];
//        
//        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
//    }
//}
//
//- (void)stopUpdatingResponseTime
//{
//    if ( _peerResponseTimer != nil )
//    {
//        NSLog(@"%@ - stopping ping", self);
//        [_peerResponseTimer invalidate];
//        _peerResponseTimer = nil;
//        _responseTime = P2PPeerNoResponse;
//        
//        [_pinger stop];
//        _pinger = nil;
//    }
//}
//
//- (void)updateResponseTime
//{
//    NSLog(@"%@ ping", self);
//    _lastPingSentTime = [NSDate new];
//    [_pinger sendPingWithData:nil];
//}
//
//
//
//#pragma mark - SimplePing Delegate Methods
//- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
//{
//    NSLog(@"%@ - ready to start pinging", self);
//    [self updateResponseTime];
//}
//
//- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
//{
//    _responseTime = ABS([_lastPingSentTime timeIntervalSinceNow]) * 1000;
//    _lastPingSentTime = nil;
//    
//    NSLog(@"Ping response: %fms", self.responseTime);
//}
//
//- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
//{
//    NSLog(@"%@ - ping failed: %@", self, error);
//    _responseTime = P2PPeerNoResponse;
//    _lastPingSentTime = nil;
//}
//
//- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error
//{
//    NSLog(@"%@ - ping failed: %@", self, error);
//    _responseTime = P2PPeerNoResponse;
//    _lastPingSentTime = nil;
//}






#pragma mark - Logging
- (NSString *)description
{
    NSString *r = self.responseTime == P2PPeerNoResponse ? @"No Response" : [NSString stringWithFormat:@"%lums", (unsigned long)self.responseTime];
    return [NSString stringWithFormat:@"<%@: %@:%lu -> %@>", NSStringFromClass([self class]), self.ipAddress, (unsigned long)self.port, r];
}

@end
