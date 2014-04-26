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

- (id)initWithFilenames:(NSArray *)filenames;

@end
