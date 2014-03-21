//
//  P2PCachedFilesViewController.m
//  P2P Sample Application iOS
//
//  Created by Tyler Darby on 2/27/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PCachedFilesViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "P2PFileManager.h"
#import "P2PFileRequest.h"
#import "P2PAddFileViewController.h"
#import "P2PFileInfoViewController.h"
#import "P2PFileInfo.h"
#import "P2PFileInCacheTableViewCell.h"

#define kNumberOfTableSections                      1
#define kTableViewSectionFilesOnDisk                0
//#define kTableViewSectionActiveRequests             1

static NSString *FilesInCacheCellIdentifier =       @"P2PFilesInCacheCell";
static NSString *ActiveTransfersCellIdentifier =    @"P2PActiveTransfersCell";


@interface P2PCachedFilesViewController () <P2PAddFileViewControllerDelegate, P2PFileRequestDelegate, P2PFileInfoDelegate>

@end

@implementation P2PCachedFilesViewController
@synthesize headerView = _headerView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    CALayer *bottomBorder = [CALayer layer];
    
    bottomBorder.frame = CGRectMake(0.0f, 63.0f, _headerView.frame.size.width, 1.0f);
    
    bottomBorder.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    [_headerView.layer addSublayer:bottomBorder];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfTableSections;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title;
//    switch ( section )
//    {
//        case kTableViewSectionFilesOnDisk:
            title = @"Files on disk";
//            break;
//            
//        case kTableViewSectionActiveRequests:
//            title = @"Active Requests";
//            break;
//    }
    return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *title;
//    switch ( section )
//    {
//        case kTableViewSectionFilesOnDisk:
            title = [NSString stringWithFormat:@"%lu files", (unsigned long)[[[P2PFileManager sharedManager] allFileIds] count]];
//            break;
//            
//        case kTableViewSectionActiveRequests:
//            title = [NSString stringWithFormat:@"%lu requests", (unsigned long)[[P2PFileRequest pendingFileRequests] count]];
//            break;
//    }
    return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
//    switch ( section )
//    {
//        case kTableViewSectionFilesOnDisk:
            rows = [[[P2PFileManager sharedManager] allFileIds] count];
//            break;
//        case kTableViewSectionActiveRequests:
//            rows = [[P2PFileRequest pendingFileRequests] count];
//            break;
//        default:
//            break;
//    }
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    P2PFileInCacheTableViewCell *cell;
    
    
//    if ( indexPath.section == kTableViewSectionFilesOnDisk )
//    {
        cell = [tableView dequeueReusableCellWithIdentifier:FilesInCacheCellIdentifier];
        assert( cell != nil );
        
        NSString *currentId = [[[P2PFileManager sharedManager] allFileIds] objectAtIndex:indexPath.row];
        cell.fileInfo = [[P2PFileManager sharedManager] fileInfoForFileId:currentId filename:nil];
//        info.delegate = self;
//        cell.textLabel.text = info.filename;
//        
//        if ( [info totalChunks] == 0 )
//        {
//            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d %%", 0];
//        }
//        else
//        {
//            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d %%", (int)(((float)[info.chunksOnDisk count] / [info totalChunks]) * 100)];
//        }
        
//    }
//    else if ( indexPath.section == kTableViewSectionActiveRequests )
//    {
//        cell = [tableView dequeueReusableCellWithIdentifier:ActiveTransfersCellIdentifier];
//        assert( cell != nil );
//        
//        P2PFileRequest *request = [[P2PFileRequest pendingFileRequests] objectAtIndex:indexPath.row];
//        cell.textLabel.text = request.fileInfo.filename;
//        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)[request.fileInfo.chunksOnDisk count], (unsigned long)[request.fileInfo.chunksAvailable count]];
//    }
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.destinationViewController isKindOfClass:[P2PAddFileViewController class]] )
    {
        ((P2PAddFileViewController *)segue.destinationViewController).delegate = self;
    }
    else if ( [segue.destinationViewController isKindOfClass:[P2PFileInfoViewController class]] )
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        P2PFileInfo *info;
//        switch ( indexPath.section )
//        {
//            case kTableViewSectionFilesOnDisk:
//            {
                NSString *currentId = [[[P2PFileManager sharedManager] allFileIds] objectAtIndex:indexPath.row];
                info = [[P2PFileManager sharedManager] fileInfoForFileId:currentId filename:nil];
//                break;
//            }
//            case kTableViewSectionActiveRequests:
//            {
//                P2PFileRequest *request = [[P2PFileRequest pendingFileRequests] objectAtIndex:indexPath.row];
//                info = request.fileInfo;
//            }
//                
//            default:
//            {
//                assert( NO );
//                break;
//            }
//                
//        }
        ((P2PFileInfoViewController *)segue.destinationViewController).fileInfo = info;
        
    }
}

#pragma mark - Add File View Controller Delegate Methods
- (void)addFileController:(P2PAddFileViewController *)controller didSelectFileToAdd:(NSString *)filename
{
    P2PFileRequest *request = [[P2PFileRequest alloc] initWithFilename:filename];
    request.delegate = self;
    [request getFile];
    
    P2PFileInfoViewController *fileInfoVC = [self.storyboard instantiateViewControllerWithIdentifier:P2PFileInfoStoryboardViewIdentifier];
    fileInfoVC.fileInfo = request.fileInfo;
    [self.navigationController pushViewController:fileInfoVC animated:NO];
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - File Request Delegate Methods
- (void)fileRequest:(P2PFileRequest *)fileRequest didRecieveChunk:(P2PFileChunk *)chunk
{
    NSLog( @"%@", NSStringFromSelector(_cmd) );
//    NSUInteger index = [[P2PFileRequest pendingFileRequests] indexOfObject:fileRequest];
//    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:kTableViewSectionActiveRequests]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)fileRequest:(P2PFileRequest *)fileRequest didFindMultipleIds:(NSArray *)fileIds forFileName:(NSString *)filename
{
    NSLog( @"%@", NSStringFromSelector(_cmd) );
}

- (void)fileRequestDidComplete:(P2PFileRequest *)fileRequest
{
    NSLog( @"%@", NSStringFromSelector(_cmd) );
}

- (void)fileRequestDidFail:(P2PFileRequest *)fileRequest withError:(P2PFileRequestError)errorCode
{
    NSLog( @"%@", NSStringFromSelector(_cmd) );
}

@end
