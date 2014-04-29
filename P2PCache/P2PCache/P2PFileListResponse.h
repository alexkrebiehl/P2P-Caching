//
//  P2PFileListResponse.h
//  P2PCache
//
//  Created by Alex Krebiehl on 4/25/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

@interface P2PFileListResponse : P2PTransmittableObject

/** An array of filenames that the node has information about */
@property (strong, nonatomic, readonly) NSArray *filenames;

/** Creates a new file list response listing details about all of the files available from a node
 
 @param filenames An array of filenames available from a node
 @return A new file list response object
 */
- (id)initWithFilenames:(NSArray *)filenames;

@end
