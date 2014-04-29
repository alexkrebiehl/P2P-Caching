//
//  P2PFileInfoViewController.m
//  P2P Sample Application iOS
//
//  Created by Alex Krebiehl on 3/20/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileInfoViewController.h"
#import "P2PFileInfo.h"
#import "P2PFileManager.h"
#import "P2PFileRequest.h"

#define kLabelUpdateInterval 1

NSString *P2PFileInfoStoryboardViewIdentifier = @"P2PFileInfoStoryboardViewIdentifier";

static NSString *kChunksAvailableKeyPath =  @"chunksAvailable";
static NSString *kTotalChunksKeyPath =      @"totalChunks";
static NSString *kTotalFileSizeKeyPath =    @"totalFileSize";

@interface P2PFileInfoViewController () <P2PFileInfoDelegate, P2PFileRequestDelegate, UIAlertViewDelegate>
{
    NSTimer *_labelUpdateTimer;
    NSUInteger _totalFileChunksDownloaded;
}

@end

@implementation P2PFileInfoViewController

- (void)setFileInfo:(P2PFileInfo *)fileInfo
{
    _fileInfo = fileInfo;
    fileInfo.delegate = self;

    // Look to see if there is an active download for this fileInfo
    for ( P2PFileRequest *request in [P2PFileRequest pendingFileRequests] )
    {
        if ( request.fileInfo == fileInfo )
        {
            request.delegate = self;
            break;
        }
    }
    
    [self updateAllFileInfo];
}

- (void)updateAllFileInfo
{
    self.navigationItem.title = self.fileInfo.filename;
    [self updateChunksAvailableLabel];
    [self updateChunksOnDiskLabel];
    [self updateTotalChunksLabel];
}

- (void)updateChunksOnDiskLabel
{
    self.chunksOnDiskLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self.fileInfo.chunksOnDisk count]];
    [self updatePercentCompleteLabel];
    [self updateFileSizeLabel];
}

- (void)updateChunksAvailableLabel
{
    if ( self.fileInfo.chunksAvailable == nil )
    {
        self.chunksAvailableLabel.text = @"?";
    }
    else
    {
        self.chunksAvailableLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self.fileInfo.chunksAvailable count]];
    }
}

- (void)updateTotalChunksLabel
{
    self.totalChunksLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self.fileInfo totalChunks]];
    [self updatePercentCompleteLabel];
    [self updateTransferRateLabel];
}

- (void)updatePercentCompleteLabel
{
    if ( [self.fileInfo totalChunks] == 0 )
    {
        self.percentCompleteLabel.text = [NSString stringWithFormat:@"%d %%", 0];
    }
    else
    {
        self.percentCompleteLabel.text = [NSString stringWithFormat:@"%d %%", (int)(((float)[self.fileInfo.chunksOnDisk count] / [self.fileInfo totalChunks]) * 100)];
    }
}

- (void)updateFileSizeLabel
{
    NSUInteger sizeInBytes = self.fileInfo.chunksOnDisk.count * P2PFileManagerFileChunkSize;
    NSString *s = [NSByteCountFormatter stringFromByteCount:sizeInBytes countStyle:NSByteCountFormatterCountStyleFile];
    self.sizeOnDiskLabel.text = s;
}

- (void)updateTransferRateLabel
{
    NSUInteger totalSizeOnDisk = [self.fileInfo.chunksOnDisk count] * P2PFileManagerFileChunkSize;
    NSUInteger deltaSize = totalSizeOnDisk - _totalFileChunksDownloaded;
    _totalFileChunksDownloaded = totalSizeOnDisk;
    
    NSString *s = [NSByteCountFormatter stringFromByteCount:deltaSize countStyle:NSByteCountFormatterCountStyleFile];
    self.transferRateLabel.text = [NSString stringWithFormat:@"%@/s", s];
}


#pragma mark - P2PFileInfo Delegate Methods
- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateChunksAvailableFromPeers:(NSUInteger)chunksAvailable
{
    // No-op
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateChunksOnDisk:(NSUInteger)chunksOnDisk
{
    // No-op
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateTotalChunks:(NSUInteger)totalChunks
{
    // No-op
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateFileId:(NSString *)fileId filename:(NSString *)filename
{
    // No-op
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateAllFileInfo];
    
    _labelUpdateTimer = [NSTimer timerWithTimeInterval:kLabelUpdateInterval target:self selector:@selector(updateAllFileInfo) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_labelUpdateTimer forMode:NSDefaultRunLoopMode];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.fileInfo = nil;
    [_labelUpdateTimer invalidate];
    _labelUpdateTimer = nil;
}

- (IBAction)retreiveRestOfFileButtonPressed:(id)sender
{
    P2PFileRequest *request = [[P2PFileRequest alloc] initWithFileInfo:self.fileInfo];
    [request getFile];
#warning To Do
}

- (IBAction)deleteFileButtonPressed:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.fileInfo.filename message:@"Are you sure you want to delete this file?" delegate:self cancelButtonTitle:@"no" otherButtonTitles:@"delete", nil];
    [alert show];
}

#pragma mark - File Request Delegate Methods
- (void)fileRequest:(P2PFileRequest *)fileRequest didFindMultipleIds:(NSArray *)fileIds forFileName:(NSString *)filenamee
{
    // No-op
}

- (void)fileRequestDidComplete:(P2PFileRequest *)fileRequest
{
    // No-op
}

- (void)fileRequestDidFail:(P2PFileRequest *)fileRequest withError:(P2PFileRequestError)errorCode
{
    // No-op
}



#pragma mark - AlertView Delegate Methods
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ( [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"delete"] )
    {
        [[P2PFileManager sharedManager] deleteFileFromCache:self.fileInfo];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
