//
//  P2PFileInfo.m
//  P2PCache
//
//  Created by Alex Krebiehl on 3/20/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileInfo.h"
#import "P2PFileManager.h"

static NSString *P2PFileManagerInfoFileNameKey =    @"filename";
static NSString *P2PFileManagerInfoFileSizeKey =    @"size";

@implementation P2PFileInfo
{
    NSMutableSet *_chunksOnDisk;
    NSMutableSet *_chunksAvailable;
}
@synthesize chunksOnDisk = _chunksOnDisk;
@synthesize chunksAvailable = _chunksAvailable;
@synthesize totalChunks = _totalChunks;

- (id)init
{
    return [self initWithFileName:nil fileId:nil chunksOnDisk:nil totalFileSize:0];
}

- (id)initWithFileName:(NSString *)fileName fileId:(NSString *)fileId chunksOnDisk:(NSSet *)chunksOnDisk totalFileSize:(NSUInteger)totalFileSize
{
    if ( fileName == nil && fileId == nil )
    {
        return nil;
    }
    
    if ( self = [super init] )
    {
        _filename = fileName;
        _fileId = fileId;
        _totalFileSize = totalFileSize;
        
        if ( chunksOnDisk == nil )
        {
            _chunksOnDisk = [[NSMutableSet alloc] init];
        }
        else
        {
            _chunksOnDisk = [[NSMutableSet alloc] initWithSet:chunksOnDisk];
        }
    }
    return self;
}

- (id)initWithFileId:(NSString *)fileId info:(NSDictionary *)plist chunksOnDisk:(NSSet *)chunksOnDisk
{
    assert( plist != nil );
    NSString *filename = [plist objectForKey:P2PFileManagerInfoFileNameKey];
    NSUInteger totalFileSize = [[plist objectForKey:P2PFileManagerInfoFileSizeKey] unsignedIntegerValue];
    
    return [self initWithFileName:filename
                           fileId:fileId
                     chunksOnDisk:chunksOnDisk
                    totalFileSize:totalFileSize];
}

- (NSDictionary *)toDictionary
{
    NSDictionary *rootDict = [NSDictionary dictionaryWithObjects:@[self.filename, @(self.totalFileSize)] forKeys:@[P2PFileManagerInfoFileNameKey, P2PFileManagerInfoFileSizeKey]];
    return rootDict;

}

- (void)fileWasDeleted
{
    _chunksOnDisk = nil;
    _chunksAvailable = nil;
    _totalFileSize = 0;
    _totalChunks = 0;
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate fileInfo:self didUpdateChunksOnDisk:[_chunksOnDisk count]];
        [self.delegate fileInfo:self didUpdateChunksAvailableFromPeers:[_chunksAvailable count]];
        [self.delegate fileInfo:self didUpdateTotalChunks:self.totalChunks];
    });
    
}

- (void)chunkWasAddedToDisk:(NSNumber *)chunkId
{
    [_chunksOnDisk addObject:chunkId];
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate fileInfo:self didUpdateChunksOnDisk:[_chunksOnDisk count]];
    });
   
}

- (void)chunkBecameAvailable:(NSNumber *)chunkId
{
    if ( _chunksAvailable == nil )
    {
        _chunksAvailable = [[NSMutableSet alloc] init];
    }
    [_chunksAvailable addObject:chunkId];
    dispatch_async(dispatch_get_main_queue(), ^
    {
       [self.delegate fileInfo:self didUpdateChunksAvailableFromPeers:[_chunksAvailable count]];
    });
}

- (void)chunksBecameAvailable:(NSSet *)multipleChunkIds
{
    if ( _chunksAvailable == nil )
    {
        _chunksAvailable = [[NSMutableSet alloc] init];
    }
    [_chunksAvailable unionSet:multipleChunkIds];
    dispatch_async(dispatch_get_main_queue(), ^
    {
       [self.delegate fileInfo:self didUpdateChunksAvailableFromPeers:[_chunksAvailable count]];
    });
}

- (NSUInteger)totalChunks
{
    return ceil( self.totalFileSize / (float)P2PFileManagerFileChunkSize );
}

- (void)setTotalChunks:(NSUInteger)totalChunks
{
    _totalChunks = totalChunks;
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate fileInfo:self didUpdateTotalChunks:totalChunks];
    });
}

- (void)setTotalFileSize:(NSUInteger)totalFileSize
{
    _totalFileSize = totalFileSize;
    [[P2PFileManager sharedManager] saveFileInfoToDisk:self];
}

- (void)setFileId:(NSString *)fileId
{
    _fileId = fileId;
    [[P2PFileManager sharedManager] saveFileInfoToDisk:self];
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate fileInfo:self didUpdateFileId:fileId filename:self.filename];
    });
}

- (void)setFilename:(NSString *)filename
{
    _filename = filename;
    [[P2PFileManager sharedManager] saveFileInfoToDisk:self];
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate fileInfo:self didUpdateFileId:self.fileId filename:filename];
    });
}

@end
