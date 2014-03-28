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
#import "P2PFileInfo.h"
#import "P2PFileRequest.h"

#import "NSData+mD5Hash.h"

#define P2PCacheDirectory @"P2PCache"

static NSString *P2PFileManagerFilesInCachePlist =  @"files.plist";     // A list of all of the files and their IDs in the cache
static NSString *P2PFileManagerInfoPlistFile =      @"fileInfo.plist";  // Information for individual files in the cache


typedef NSMutableSet file_id_list_t;


@implementation P2PFileManager
{
    // Dictionary mapping a filename to a set of matching fileIds
    // Contains all of the file names and Ids that we have on disk
    NSMutableDictionary *_filenameToFileIds;

    // Dictionary mapping a fileId to a fileInfo object
    // Note... this will only contain recently accessed files whose information is cached
    NSMutableDictionary *_cachedFileInfo;
}
@synthesize cacheDirectory = _cacheDirectory;

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
        _cachedFileInfo = [[NSMutableDictionary alloc] init];
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
    NSURL *plistURL = [NSURL URLWithString:P2PFileManagerFilesInCachePlist relativeToURL:[self cacheDirectory]];
    NSData *plistData = [NSData dataWithContentsOfURL:plistURL];
    
    _filenameToFileIds = [[NSMutableDictionary alloc] init];
    
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
            // Sets can't be saved to a plist, so they were converted to an array.
            // Now we have to convert them back
            for ( NSString *filename in [plist allKeys] )
            {
                NSArray *ids = [plist objectForKey:filename];
                [_filenameToFileIds setObject:[[file_id_list_t alloc] initWithArray:ids] forKey:filename];
            }
        }
    }
}

- (void)saveFilesInCacheList
{
    // Sets can't be saved to a plist, so they have to be converted to arrays.
    NSMutableDictionary *dictionaryToSerialize = [[NSMutableDictionary alloc] init];
    for ( NSString *filename in [_filenameToFileIds allKeys] )
    {
        file_id_list_t *ids = [_filenameToFileIds objectForKey:filename];
        [dictionaryToSerialize setObject:[ids allObjects] forKey:filename];
    }
    
    
    NSError *error;
    NSData *plist = [NSPropertyListSerialization dataWithPropertyList:dictionaryToSerialize format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
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

- (NSOrderedSet *)allFileIds
{
    NSMutableOrderedSet *all = [[NSMutableOrderedSet alloc] init];
    for ( file_id_list_t *ids in [_filenameToFileIds allValues] )
    {
        [all unionSet:ids];
    }
    return all;
}

/*  First we split the file into the P2P chunks we need.
    Then we create our directory using a hash id. As long 
        as the directory creation proceeds, we cache the file.
 */
- (void)cacheFile:(NSData *)file withFileName:(NSString *)filename {
    
    NSString *hashID = [file md5Hash];
    P2PFileInfo *fileInfo = [self fileInfoForFileId:hashID filename:filename];
    fileInfo.totalFileSize = [file length];
    NSArray *chunksOData = [self splitData:file intoChunksOfSize:P2PFileManagerFileChunkSize withFileId:hashID fileName:filename];
    
    for ( P2PFileChunk *chunk in chunksOData )
    {
        [self writeChunk:chunk withFileInfo:fileInfo];
    }
}

- (void)fileRequest:(P2PFileRequest *)fileRequest didRecieveFileChunk:(P2PFileChunk *)chunk
{
    /** we should cache the chunks as we recieve them from other peers */
    [self writeChunk:chunk withFileInfo:fileRequest.fileInfo];
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

- (void)writeChunk:(P2PFileChunk *)chunk withFileInfo:(P2PFileInfo *)fileInfo
{
    assert( fileInfo != nil );
    NSURL *directoryPath = [self pathForDirectoryWithHashID:chunk.fileId];
    
    NSURL *urlWithFile = [NSURL URLWithString:[NSString stringWithFormat:@"%lu", (unsigned long)chunk.chunkId] relativeToURL:directoryPath];
    assert( [chunk.dataBlock writeToURL:urlWithFile atomically:YES] );
    [fileInfo chunkWasAddedToDisk:@( chunk.chunkId )];
}

- (bool)deleteFileFromCache:(P2PFileInfo *)fileInfo
{
    // Make sure we actually have information about this file
    assert( [_cachedFileInfo objectForKey:fileInfo.fileId] == fileInfo );
    
    if ( fileInfo.fileId != nil )
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            NSError *error;
            [self removeItemAtURL:[self pathForDirectoryWithHashID:fileInfo.fileId] error:&error];
            if ( error != nil )
            {
                P2PLog( P2PLogLevelWarning, @"%@ - Unable to delete file: %@ - %@", self, fileInfo.filename, error );
            }
        });
        
        
        // The file's been removed from disk.  Just update revelant objects now
        [fileInfo fileWasDeleted];
        
        NSMutableSet *a = [_filenameToFileIds objectForKey:fileInfo.filename];
        [a removeObject:fileInfo.fileId];
        if ( a.count == 0 )
        {
            [_filenameToFileIds removeObjectForKey:fileInfo.filename];
        }
        [self saveFilesInCacheList];
        return YES;
    }
    return NO;
}



#pragma mark - File Path Methods
- (NSURL *)pathForDirectoryWithHashID:(NSString *)hashID
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/", hashID] relativeToURL:[self cacheDirectory]];
}

- (NSURL *)cacheDirectory
{
    if ( _cacheDirectory == nil )
    {
        NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                   inDomains:NSUserDomainMask] lastObject];
        _cacheDirectory = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/", documents.absoluteString, P2PCacheDirectory]];
    }
    return _cacheDirectory;
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
        response.matchingFileIds = [[self matchingIdsForFilename:request.fileName] allObjects];
    }
    if ( [[response matchingFileIds] count] == 1 )
    {

        // We have one matching file ID... we can send information on that file
        NSString *fileId = [[response matchingFileIds] firstObject];
        P2PFileInfo *info = [self fileInfoForFileId:fileId filename:request.fileName];
        
        if ( info != nil )
        {
            response.totalChunks = info.totalChunks;
            response.availableChunks = [NSMutableSet setWithSet:info.chunksOnDisk];
            response.chunkSizeInBytes = P2PFileManagerFileChunkSize;
        }
    }
    return response;
}



/*  Returns a list of chunk files available. If error, it returns nil.
 */
- (NSArray *)chunkIdsOnDiskForFileId:(NSString *)fileID
{
    NSError *error;
    NSURL *path = [self pathForDirectoryWithHashID:fileID];

    NSArray *filesFound = [self contentsOfDirectoryAtURL:path includingPropertiesForKeys:nil options:0 error:&error];
    
    if (error) {
        P2PLog(P2PLogLevelError, @"Unable to retrieve chunkIDs: %@", error);
        return nil;
    } else {
        NSMutableArray *chunkIds = [[NSMutableArray alloc] initWithCapacity:[filesFound count] - 1 ];
        
        for ( NSString *file in filesFound )
        {
            NSString *anId = [file lastPathComponent];
            
            if ( ![anId isEqualToString:P2PFileManagerInfoPlistFile] && ![anId isEqualToString:@".DS_Store"] )
            {
                [chunkIds addObject:@( [anId integerValue] )];
            }
        }
        
        return chunkIds;
    }
}




#pragma mark - Chunk request methods
/** Returns a file chunk for a given request, or nil if the request could not be completed */
- (P2PFileChunk *)fileChunkForRequest:(P2PFileChunkRequest *)request
{
    P2PFileInfo *fileInfo = [self fileInfoForFileId:request.fileId filename:nil];
    P2PFileChunk *aChunk;
    if ( fileInfo != nil )
    {
        NSURL *urlPath = [NSURL URLWithString:[NSString stringWithFormat:@"%lu", (unsigned long)request.chunkId]
                                relativeToURL:[self pathForDirectoryWithHashID:request.fileId]];
        NSData *chunkData = [NSData dataWithContentsOfURL:urlPath];
        
        if ( chunkData != nil )
        {
            aChunk = [[P2PFileChunk alloc] initWithData:chunkData
                                                chunkId:request.chunkId
                                                 fileId:request.fileId
                                               fileName:fileInfo.filename
                                          totalFileSize:fileInfo.totalFileSize];
            aChunk.responseForRequestId = request.requestId;
        }
    }
    
    return aChunk;
}

- (file_id_list_t *)matchingIdsForFilename:(NSString *)filename
{
    file_id_list_t *ids = [_filenameToFileIds objectForKey:filename];
    if ( ids == nil )
    {
        ids = [[file_id_list_t alloc] init];
    }
    return ids;
}

- (void)addFileId:(NSString *)fileId toFilename:(NSString *)filename
{
    file_id_list_t *ids = [_filenameToFileIds objectForKey:filename];
    if ( ids == nil )
    {
        ids = [[file_id_list_t alloc] init];
        [_filenameToFileIds setObject:ids forKey:filename];
    }
    
    [ids addObject:fileId];
    [self saveFilesInCacheList];
}

- (P2PFileInfo *)fileInfoForFileId:(NSString *)fileId filename:(NSString *)filename
{
    P2PFileInfo *info;
    if ( fileId == nil && [[self matchingIdsForFilename:filename] count] == 1 )
    {
        // A file ID was not given, but we only have one name in our cache that matches 'filename',
        // so we'll just use that ID
        fileId = [[self matchingIdsForFilename:filename] anyObject];
    }
    
    
    if ( !(info = [_cachedFileInfo objectForKey:fileId]) )
    {
        // No Cached file info... see if we can pull it up
        NSDictionary *plist = [self plistForFileId:fileId];
        if ( plist != nil )
        {
            info = [[P2PFileInfo alloc] initWithFileId:fileId info:plist chunksOnDisk:[self chunkIdsOnDiskForFileId:fileId]];
        }
        else
        {
            // See if we can generate one off of the information given
            info = [self generateFileInfoForFileId:fileId fileName:filename totalFileSize:0];
        }
    }
    
    if ( info.fileId != nil )
    {
        // Cache the file info
        [_cachedFileInfo setObject:info forKey:info.fileId];
    }
    
    return info;
}

- (P2PFileInfo *)generateFileInfoForFileId:(NSString *)fileId fileName:(NSString *)filename totalFileSize:(NSUInteger)totalSize
{
    // If there was an ID, we at least created a directory for it
    P2PFileInfo *fileInfo = [[P2PFileInfo alloc] initWithFileName:filename fileId:fileId chunksOnDisk:@[ ] totalFileSize:totalSize];
    if ( fileInfo.fileId != nil )
    {
        [self saveFileInfoToDisk:fileInfo];
    }
    else
    {
        P2PLog(P2PLogLevelWarning, @"%@ - Unable to save generated fileInfo (no fileId): %@", self, filename);
    }
    return fileInfo;
}

- (void)saveFileInfoToDisk:(P2PFileInfo *)fileInfo
{
    // create plist
    NSError *error;
    NSDictionary *plistDictionary = [fileInfo toDictionary];
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:plistDictionary format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if ( error )
    {
        P2PLog( P2PLogLevelError, @"ERROR: Unable to serialize fileInfo to plist: %@ for %@", error, fileInfo );
    }
    else
    {
        if ( fileInfo.fileId != nil )
        {
            NSError *error;
            NSURL *directoryPath = [self pathForDirectoryWithHashID:fileInfo.fileId];
            BOOL isDirectory = YES;
            if ( ![self fileExistsAtPath:directoryPath.absoluteString isDirectory:&isDirectory] || !isDirectory )
            {
                [self createDirectoryAtURL:directoryPath withIntermediateDirectories:YES attributes:Nil error:&error];
                
                if ( error != nil )
                {
                    P2PLog(P2PLogLevelError, @"ERROR: Unable to create directory for file: %@", error);
                    return;
                }
            }
                
            
            NSURL *plistURL = [NSURL URLWithString:P2PFileManagerInfoPlistFile relativeToURL:[self pathForDirectoryWithHashID:fileInfo.fileId]];
            [plistData writeToURL:plistURL atomically:YES];
            
            // Cache the file info
            file_id_list_t *idsForFilename = [self matchingIdsForFilename:fileInfo.filename];
            if ( ![idsForFilename containsObject:fileInfo.filename] )
            {
                [self addFileId:fileInfo.fileId toFilename:fileInfo.filename];
            }
            [_cachedFileInfo setObject:fileInfo forKey:fileInfo.fileId];
        }
        else
        {
            P2PLog( P2PLogLevelWarning, @"%@ - Can't save file info with no fileId: %@", self, fileInfo );
        }
    }
}

@end
