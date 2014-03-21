//
//  P2PFileInfoViewController.m
//  P2P Sample Application iOS
//
//  Created by Alex Krebiehl on 3/20/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileInfoViewController.h"
#import "P2PFileInfo.h"

static NSString *kChunksAvailableKeyPath =  @"chunksAvailable";
static NSString *kTotalChunksKeyPath =      @"totalChunks";
static NSString *kTotalFileSizeKeyPath =    @"totalFileSize";

@interface P2PFileInfoViewController ()

@end

@implementation P2PFileInfoViewController

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}
- (void)setFileInfo:(P2PFileInfo *)fileInfo
{
    if ( _fileInfo != nil )
    {
        // Stop observing old file
        [_fileInfo removeObserver:self forKeyPath:kChunksAvailableKeyPath];
        [_fileInfo removeObserver:self forKeyPath:kTotalFileSizeKeyPath];
        [_fileInfo removeObserver:self forKeyPath:kTotalChunksKeyPath];
    }
    
    _fileInfo = fileInfo;
    [fileInfo addObserver:self forKeyPath:kChunksAvailableKeyPath options:0 context:NULL];
    [fileInfo addObserver:self forKeyPath:kTotalChunksKeyPath options:0 context:NULL];
    [fileInfo addObserver:self forKeyPath:kTotalFileSizeKeyPath options:0 context:NULL];
    
    [self fileInfoDidUpdate];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    assert( object == _fileInfo );
    [self fileInfoDidUpdate];
}

- (void)fileInfoDidUpdate
{
    self.chunksOnDiskLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[_fileInfo.chunksOnDisk count]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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

- (IBAction)deleteFileButtonPressed:(id)sender {
}
@end
