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

#define P2PCacheDirectory @"P2PCache"

static NSString *P2PFileManagerFilesInCachePlist =  @"files.plist";     // A list of all of the files and their IDs in the cache
static NSString *P2PFileManagerInfoPlistFile =      @"fileInfo.plist";  // Information for individual files in the cache
static NSString *P2PFileManagerInfoFileNameKey =    @"filename";
static NSString *P2PFileManagerInfoFileSizeKey =    @"size";


@implementation P2PFileManager
{
    NSMutableDictionary *_filesInCache;
}

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



- (id)init
{
    if ( self = [super init] )
    {
        [self loadFilesInCacheList];
    }
    return self;
}

- (void)cleanup
{
    [super cleanup];
    [self saveFilesInCacheList];
}

- (void)loadFilesInCacheList
{
    NSError *error;
//    NSString *plistLocation = [NSString stringWithFormat:@"%@%@", [self cacheDirectory].absoluteString, P2PFileManagerFilesInCachePlist];
    NSURL *plistURL = [NSURL URLWithString:P2PFileManagerFilesInCachePlist relativeToURL:[self cacheDirectory]];
//    NSData *plistData = [NSData dataWithContentsOfFile:plistLocation];
    NSData *plistData = [NSData dataWithContentsOfURL:plistURL];
    if ( plistData != nil )
    {
        NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
        NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:plistData options:0 format:&format error:&error];
        if ( error )
        {
            P2PLog( P2PLogLevelError, @"Failed to load files in cache plist: %@", error );
        }
        else
        {
            _filesInCache = [[NSMutableDictionary alloc] initWithDictionary:plist];
        }
    }
    if ( _filesInCache == nil )
    {
        _filesInCache = [[NSMutableDictionary alloc] init];
    }
}

- (void)saveFilesInCacheList
{
    NSError *error;
    NSData *plist = [NSPropertyListSerialization dataWithPropertyList:_filesInCache format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if ( error )
    {
        P2PLog( P2PLogLevelError, @"Couldn't create files plist: %@", error );
    }
    else
    {
        NSURL *plistURL = [NSURL URLWithString:P2PFileManagerFilesInCachePlist relativeToURL:[self cacheDirectory]];
        bool success = [plist writeToURL:plistURL atomically:YES];
        if ( success )
        {
            P2PLog( P2PLogLevelNormal, @"Wrote files in cache list to disk" );
        }
        else
        {
            P2PLog( P2PLogLevelError, @"Failed to write files in cache list to disk" );
        }
    }
}

/*  First we split the file into the P2P chunks we need.
    Then we create our directory using a hash id. As long 
        as the directory creation proceeds, we cache the file.
 */


-(void)cacheFile:(NSData *)file withFileName:(NSString *)filename {
    
    NSString *hashID = [file md5Hash];
    NSArray *chunksOData = [self splitData:file intoChunksOfSize:P2PFileManagerFileChunkSize withFileId:hashID fileName:filename];
    
    for ( P2PFileChunk *chunk in chunksOData )
    {
        [self writeChunk:chunk];
    }
}

- (void)fileRequest:(P2PFileRequest *)fileRequest didRecieveFileChunk:(P2PFileChunk *)chunk
{
    /** we should cache the chunks as we recieve them from other peers */
    [self writeChunk:chunk];
}

- (NSArray *)splitData:(NSData *)data intoChunksOfSize:(NSUInteger)chunkSize withFileId:(NSString *)fileId fileName:(NSString *)filename
{
    NSUInteger length = [data length];
    NSUInteger offset = 0;
    
    NSMutableArray *chunksOdata = [[NSMutableArray alloc] initWithCapacity:ceil( length / chunkSize )];
    
    do
    {
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        NSData *chunk = [data subdataWithRange:NSMakeRange(offset, thisChunkSize)];
        
        P2PFileChunk *p2pChunk = [[P2PFileChunk alloc] initWithData:chunk chunkId:offset fileId:fileId fileName:filename totalFileSize:length];
        [chunksOdata addObject:p2pChunk];
        
        offset += thisChunkSize;
    } while (offset < length);
    
    return chunksOdata;
}

- (NSDictionary *)plistForFileId:(NSString *)fileId
{
    NSError *error;
    NSURL *plistURL = [NSURL URLWithString:P2PFileManagerInfoPlistFile relativeToURL:[self pathForDirectoryWithHashID:fileId]];
//    NSString *plistLocation = [NSString stringWithFormat:@"%@%@", [self pathForDirectoryWithHashID:fileId], P2PFileManagerInfoPlistFile];
//    NSData *plistData = [NSData dataWithContentsOfFile:plistLocation];
    NSData *plistData = [NSData dataWithContentsOfURL:plistURL];
    if ( plistData == nil )
    {
        P2PLog( P2PLogLevelWarning, @"Information for FileID: %@ was requested, but no Plist was found", fileId );
        return nil;
    }
    else
    {
        NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
        NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:plistData options:0 format:&format error:&error];
        if ( error )
        {
            P2PLog( P2PLogLevelError, @"Unable to load Plist for FileID: %@ - %@", fileId, error );
            return nil;
        }
        else
        {
            return plist;
        }
        
    }
}

- (NSData *)createPlistForFileName:(NSString *)filename fileSize:(NSUInteger)fileSize error:(NSError *)error
{
    NSDictionary *rootDict = [NSDictionary dictionaryWithObjects:@[filename, @(fileSize)] forKeys:@[P2PFileManagerInfoFileNameKey, P2PFileManagerInfoFileSizeKey]];
    NSData *plist = [NSPropertyListSerialization dataWithPropertyList:rootDict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    return plist;
}

- (void)writeChunk:(P2PFileChunk *)chunk
{
    NSError *error;
    NSURL *directoryPath = [self pathForDirectoryWithHashID:chunk.fileId];
    BOOL isDirectory = YES;
    if ( ![self fileExistsAtPath:directoryPath.absoluteString isDirectory:&isDirectory] || !isDirectory )
    {
        [self createDirectoryAtURL:directoryPath withIntermediateDirectories:YES attributes:Nil error:&error];
        if ( error != nil )
        {
            P2PLog(P2PLogLevelError, @"ERROR: Unable to create directory for file");
            return;
        }
        else
        {
        
            // create plist
            NSData *plist = [self createPlistForFileName:chunk.fileName fileSize:chunk.totalFileSize error:error];
            if (error)
            {
                P2PLog(P2PLogLevelError, @"ERROR: Unable to create plist");
                return;
            }
            else
            {
                NSURL *plistURL = [NSURL URLWithString:P2PFileManagerInfoPlistFile relativeToURL:directoryPath];
                [plist writeToURL:plistURL atomically:YES];
            }
        }
    }
    
    NSMutableArray *idsForFilename = [_filesInCache objectForKey:chunk.fileName];
    if ( idsForFilename == nil )
    {
        idsForFilename = [[NSMutableArray alloc] init];
        [_filesInCache setObject:idsForFilename forKey:chunk.fileName];
    }
    if ( ![idsForFilename containsObject:chunk.fileId] )
    {
        [idsForFilename addObject:chunk.fileId];
        [self saveFilesInCacheList];
    }
    
    
    NSURL *urlWithFile = [NSURL URLWithString:[NSString stringWithFormat:@"%lu", (unsigned long)chunk.chunkId] relativeToURL:directoryPath];
    [chunk.dataBlock writeToURL:urlWithFile atomically:YES];
}

#pragma mark - File Path Methods
- (NSURL *)pathForDirectoryWithHashID:(NSString *)hashID
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/", hashID] relativeToURL:[self cacheDirectory]];
}

- (NSURL *)cacheDirectory
{
    NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                               inDomains:NSUserDomainMask] lastObject];
    NSURL *directory = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/", documents.absoluteString, P2PCacheDirectory]];
    return directory;
}


#pragma mark - Chunk availability methods
- (P2PPeerFileAvailbilityResponse *)fileAvailibilityForRequest:(P2PPeerFileAvailibilityRequest *)request
{
    // Respond to a client with what chunks of a file we have
    P2PPeerFileAvailbilityResponse *response = [[P2PPeerFileAvailbilityResponse alloc] initWithRequest:request];
    
    if ( [[response matchingFileIds] count] == 0 && request.fileName != nil )
    {
        // Only a file name was supplied... we have to file out what file IDs could match up to this filename
        // The client making the request will have to decide which file ID they want then send another request
        response.matchingFileIds = [_filesInCache objectForKey:request.fileName];
    }
    if ( [[response matchingFileIds] count] == 1 )
    {

        // We have one matching file ID... we can send information on that file
        NSString *fileId = [[response matchingFileIds] firstObject];
        NSDictionary *plist = [self plistForFileId:fileId];
        if ( plist != nil )
        {
            // We have some information on the file
            response.totalFileLength = [[plist objectForKey:P2PFileManagerInfoFileSizeKey] unsignedIntegerValue];
            response.availableChunks = [self availableChunksForFileID:fileId];
            response.chunkSizeInBytes = P2PFileManagerFileChunkSize;
        }
        
    }
    return response;
}



/*  Returns a list of chunk files available. If error, it returns nil.
 */

- (NSArray *)availableChunksForFileID:(NSString *)fileID {
    NSError *error;
    NSURL *path = [self pathForDirectoryWithHashID:fileID];
    
//    chunkIDs = [self contentsOfDirectoryAtPath:path.absoluteString error:&error];
    NSArray *filesFound = [self contentsOfDirectoryAtURL:path includingPropertiesForKeys:nil options:0 error:&error];
    
    if (error) {
        P2PLog(P2PLogLevelError, @"Unable to retrieve chunkIDs: %@", error);
        return nil;
    } else {
        NSMutableArray *chunkIds = [[NSMutableArray alloc] initWithCapacity:[filesFound count] - 1 ];
        
        for ( NSString *file in filesFound )
        {
            NSString *anId = [file lastPathComponent];
            
            if ( ![anId isEqualToString:P2PFileManagerInfoPlistFile] )
            {
                [chunkIds addObject:@( [anId integerValue] )];
            }
        }

        
        return chunkIds;
    }
}


#pragma mark - Chunk request methods

- (P2PFileChunk *)fileChunkForRequest:(P2PFileChunkRequest *)request
{
    NSDictionary *plist = [self plistForFileId:request.fileId];
//    NSString *path = [NSString stringWithFormat:@"%@%lu", [self pathForDirectoryWithHashID:request.fileId], (unsigned long)request.chunkId];
    NSURL *urlPath = [NSURL URLWithString:[NSString stringWithFormat:@"%lu", request.chunkId] relativeToURL:[self pathForDirectoryWithHashID:request.fileId]];
    P2PFileChunk *chunk = [[P2PFileChunk alloc] initWithData:[NSData dataWithContentsOfURL:urlPath]
                                                     chunkId:request.chunkId
                                                      fileId:request.fileId
                                                    fileName:[plist objectForKey:P2PFileManagerInfoFileNameKey]
                                               totalFileSize:[[plist objectForKey:P2PFileManagerInfoFileSizeKey] unsignedIntegerValue]];
    
    return chunk;
}

@end
