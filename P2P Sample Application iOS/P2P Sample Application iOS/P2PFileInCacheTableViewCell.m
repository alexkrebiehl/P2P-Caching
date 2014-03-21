//
//  P2PFileInCacheTableViewCell.m
//  P2P Sample Application iOS
//
//  Created by Alex Krebiehl on 3/21/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileInCacheTableViewCell.h"
#import "P2PFileInfo.h"

@interface P2PFileInCacheTableViewCell() <P2PFileInfoDelegate>
@end

@implementation P2PFileInCacheTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setFileInfo:(P2PFileInfo *)fileInfo
{
    _fileInfo.delegate = nil;
    _fileInfo = fileInfo;
    _fileInfo.delegate = self;
    
    [self updateFilename];
    [self updatePercentComplete];
}

#pragma mark - FileInfo Delegate Methods
- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateChunksAvailableFromPeers:(NSUInteger)chunksAvailable
{
    // Nothing for here as of yet
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateChunksOnDisk:(NSUInteger)chunksOnDisk
{
    [self updatePercentComplete];
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateFileId:(NSString *)fileId filename:(NSString *)filename
{
    [self updateFilename];
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateTotalChunks:(NSUInteger)totalChunks
{
    [self updatePercentComplete];
}

- (void)updateFilename
{
    NSString *labelText;
    if ( !(labelText = self.fileInfo.filename) )
    {
        labelText = @"<searching... >";
    }
    self.textLabel.text = labelText;
}

- (void)updatePercentComplete
{
    if ( self.fileInfo.totalChunks == 0 )
    {
        self.detailTextLabel.text = [NSString stringWithFormat:@"%d %%", 0];
    }
    else
    {
        self.detailTextLabel.text = [NSString stringWithFormat:@"%d %%", (int)(((float)[self.fileInfo.chunksOnDisk count] / [self.fileInfo totalChunks]) * 100)];
    }
}

@end
