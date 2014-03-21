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

NSString *P2PFileInfoStoryboardViewIdentifier = @"P2PFileInfoStoryboardViewIdentifier";

static NSString *kChunksAvailableKeyPath =  @"chunksAvailable";
static NSString *kTotalChunksKeyPath =      @"totalChunks";
static NSString *kTotalFileSizeKeyPath =    @"totalFileSize";

@interface P2PFileInfoViewController () <P2PFileInfoDelegate>

@end

@implementation P2PFileInfoViewController

- (void)setFileInfo:(P2PFileInfo *)fileInfo
{
    _fileInfo = fileInfo;
    fileInfo.delegate = self;
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
    self.chunksOnDiskLabel.text = [NSString stringWithFormat:@"%lu", [self.fileInfo.chunksOnDisk count]];
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
        self.chunksAvailableLabel.text = [NSString stringWithFormat:@"%lu", [self.fileInfo.chunksAvailable count]];
    }
}

- (void)updateTotalChunksLabel
{
    self.totalChunksLabel.text = [NSString stringWithFormat:@"%lu", [self.fileInfo totalChunks]];
    [self updatePercentCompleteLabel];
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


#pragma mark - P2PFileInfo Delegate Methods
- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateChunksAvailableFromPeers:(NSUInteger)chunksAvailable
{
    [self updateChunksAvailableLabel];
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateChunksOnDisk:(NSUInteger)chunksOnDisk
{
    [self updateChunksOnDiskLabel];
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateTotalChunks:(NSUInteger)totalChunks
{
    [self updateTotalChunksLabel];
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateFileId:(NSString *)fileId filename:(NSString *)filename
{
    [self updateAllFileInfo];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateAllFileInfo];
    // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.fileInfo = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)retreiveRestOfFileButtonPressed:(id)sender
{
    P2PFileRequest *request = [[P2PFileRequest alloc] initWithFileInfo:self.fileInfo];
    [request getFile];
#warning To Do
}

- (IBAction)deleteFileButtonPressed:(id)sender
{
#warning To Do
}
@end
