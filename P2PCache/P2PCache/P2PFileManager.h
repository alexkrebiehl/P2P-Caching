//
//  P2PFileManager.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>


static const NSUInteger P2PFileManagerFileChunkSize = 1024 * 64;  // 64k File chunk size



@class P2PPeerFileAvailibilityRequest, P2PPeerFileAvailbilityResponse, P2PFileChunk, P2PFileChunkRequest, P2PFileRequest, P2PFileInfo;

@interface P2PFileManager : NSFileManager

@property (strong, nonatomic, readonly) NSOrderedSet *allFileIds;
@property (strong, nonatomic, readonly) NSURL *cacheDirectory;



+ (P2PFileManager *)sharedManager;



- (P2PPeerFileAvailbilityResponse *)fileAvailibilityForRequest:(P2PPeerFileAvailibilityRequest *)request;
- (P2PFileChunk *)fileChunkForRequest:(P2PFileChunkRequest *)request;
- (void)fileRequest:(P2PFileRequest *)fileRequest didRecieveFileChunk:(P2PFileChunk *)chunk;

- (void)cacheFile:(NSData *)file withFileName:(NSString *)filename;


/** Returns info about a file given either it's ID, or a file name.  If a filename is given, this will return a P2PFileInfo object if exactly one match to the name is found.  If there are multiple matches, nil is returned and a fileId must be supplied.
 
 @param fileId The identifier unique to a file
 @param filename The name of a file to retrieve info on
 
 @return Returns information if a match is found, otherwise nil 
 */
- (P2PFileInfo *)fileInfoForFileId:(NSString *)fileId filename:(NSString *)filename;

- (void)saveFileInfoToDisk:(P2PFileInfo *)fileInfo;
//- (P2PFileInfo *)generateFileInfoForFileId:(NSString *)fileId fileName:(NSString *)filename totalFileSize:(NSUInteger)totalSize;

//- (NSArray *)availableChunksForFileID:(NSString *)fileID;

@end

