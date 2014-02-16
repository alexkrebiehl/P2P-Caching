//
//  P2PFileManager.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileManager.h"
#import "P2PPeerFileAvailbilityResponse.h"
#import "P2PPeerFileAvailibilityRequest.h"
#import "P2PFileChunk.h"
#import "P2PFileChunkRequest.h"

#import "NSData+mD5Hash.h"

@implementation P2PFileManager

static P2PFileManager *sharedInstance = nil;
+ (P2PFileManager *)sharedManager
{
    if (sharedInstance == nil)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ sharedInstance = [[[self class] alloc] init]; });
    }
    return sharedInstance;
}





/*  First we split the file into the P2P chunks we need. 
    Then we create our directory using a hash id. As long 
        as the directory creation proceeds, we cache the file.
 */


-(void)cacheFile:(NSData *)file withFileName:(NSString *)filename {
    
    NSString *hashID = [file md5Hash];
    NSArray *chunksOData = [self splitData:file intoChunksOfSize:P2PFileManagerFileChunkSize withFileId:hashID];
    
    
    NSError *error;
    NSString *directoryPath = [self pathForFileWithHashID:hashID];
    [self createDirectoryAtPath:directoryPath withIntermediateDirectories:NO attributes:nil error:&error];
    
    
    if (error) {
        P2PLog(0, @"ERROR: Unable to create directory for file");
    } else {
        id plist = [self createPlistForData:file withFileName:filename error:error];
        for (P2PFileChunk  *chunk in chunksOData) {
            [self writeChunk:chunk toPath:directoryPath];
        }
        if (error) {
            P2PLog(0, @"ERROR: Unable to create plist");
        } else {
            [plist writeToFile:[directoryPath stringByAppendingString:@"fileInfo.plist"] atomically:YES];
        }
    }
    
    
}



- (NSArray *)splitData:(NSData *)data intoChunksOfSize:(NSUInteger)chunkSize withFileId:(NSString *)fileId
{
    NSUInteger length = [data length];
    NSUInteger offset = 0;
    
    NSMutableArray *chunksOdata = [[NSMutableArray alloc] initWithCapacity:ceil( length / chunkSize )];
    
    do
    {
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        //        NSData *chunk = [NSData dataWithBytesNoCopy:(char *)[data bytes] + offset
        //                                             length:thisChunkSize
        //                                       freeWhenDone:NO];
        NSData *chunk = [data subdataWithRange:NSMakeRange(offset, thisChunkSize)];
        
//        P2PFileChunk *p2pChunk = [[P2PFileChunk alloc] initWithData:chunk startPosition:offset fileName:filename];
        P2PFileChunk *p2pChunk = [[P2PFileChunk alloc] initWithData:chunk chunkId:offset fileId:fileId];
        [chunksOdata addObject:p2pChunk];
        
        offset += thisChunkSize;
    } while (offset < length);
    
    return chunksOdata;
}



- (id)createPlistForData:(NSData *)data withFileName:(NSString *)filename error:(NSError *)error {
    NSDictionary *rootDict;
    NSNumber *fileSize = [NSNumber numberWithInteger:[data length]];
    rootDict = [NSDictionary dictionaryWithObjects:@[filename, fileSize] forKeys:@[@"filename", @"size"]];
    
    id plist = [NSPropertyListSerialization dataWithPropertyList:(id)rootDict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    return plist;
    
}

- (void)writeChunk:(P2PFileChunk *)chunk toPath:(NSString *)path
{
    [chunk.dataBlock writeToFile:[path stringByAppendingString:[NSString stringWithFormat:@"%lu", (unsigned long)chunk.chunkId]] atomically:YES];
}

#pragma mark - File Path Methods
- (NSString *)pathForFileWithHashID:(NSString *)hashID
{
	
    return [[self applicationDocumentsDirectory].path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/", hashID]];
    
}
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Chunk availability methods
- (P2PPeerFileAvailbilityResponse *)fileAvailibilityForRequest:(P2PPeerFileAvailibilityRequest *)request
{
    // Respond to a client with what chunks of a file we have
    
    //    P2PPeerFileAvailbilityResponse *response = [[P2PPeerFileAvailbilityResponse alloc] initWithFileName:request.fileName
    //                                                                                        availableChunks:@[ @(1) ]
    //                                                                                              chunkSize:P2PFileManagerFileChunkSize];
    P2PPeerFileAvailbilityResponse *response = [[P2PPeerFileAvailbilityResponse alloc] initWithRequest:request];
    
    
    
    response.availableChunks = [self availableChunksForFileID:request.fileId];
    response.chunkSizeInBytes = P2PFileManagerFileChunkSize;
    
    return response;
}



/*  Returns a list of chunk files available. If error, it returns nil.
 */

- (NSArray *)availableChunksForFileID:(NSString *)fileID {
    NSArray *chunkIDs;
    NSError *error;
    NSString *path = [self pathForFileWithHashID:fileID];
    
    chunkIDs = [self contentsOfDirectoryAtPath:path error:&error];
    
    if (error) {
        P2PLog(P2PLogLevelError, @"Unable to retrieve chunkIDs");
        return nil;
    } else {
        return chunkIDs;
    }
}


#pragma mark - Chunk request methods

- (P2PFileChunk *)fileChunkForRequest:(P2PFileChunkRequest *)request
{

    NSString *path = [NSString stringWithFormat:@"%@%lu", [self pathForFileWithHashID:request.fileId], (unsigned long)request.chunkId];
//    P2PFileChunk *chunk = [[P2PFileChunk alloc] initWithData: startPosition:request.chunkId fileName:request.fileId];
    P2PFileChunk *chunk = [[P2PFileChunk alloc] initWithData:[NSData dataWithContentsOfFile:path] chunkId:request.chunkId fileId:request.fileId];
    
    return chunk;
}

@end
