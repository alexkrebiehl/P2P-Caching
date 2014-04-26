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
#define kTableViewSectionDownloadingFiles           0

static NSString *SeguePushFileInfo =                @"pushFileInfo";
static NSString *SeguePushAddFile =                 @"pushAddFile";

static NSString *FilesInCacheCellIdentifier =       @"P2PFilesInCacheCell";
static NSString *ActiveTransfersCellIdentifier =    @"P2PActiveTransfersCell";


@interface P2PCachedFilesViewController () <P2PAddFileViewControllerDelegate, P2PFileRequestDelegate, P2PFileInfoDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@end

@implementation P2PCachedFilesViewController
{
    NSArray *_searchResults;
}

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
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    self.searchDisplayController.delegate = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchDisplayController.searchResultsDataSource = self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfTableSections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *footerText = nil;
    if ( tableView != self.searchDisplayController.searchResultsTableView )
    {
        footerText = @"Files on disk";
    }
    return footerText;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *footerText = nil;
    if ( tableView != self.searchDisplayController.searchResultsTableView )
    {
        footerText = [NSString stringWithFormat:@"%lu files", (unsigned long)[[[P2PFileManager sharedManager] allFileIds] count]];
    }
    return footerText;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    if ( tableView == self.searchDisplayController.searchResultsTableView )
    {
//        P2PPeerFileAvailibilityRequest *request = [P2PPeerFileAvailibilityRequest al]
        rows = [_searchResults count];
    }
    else
    {
        rows = [[[P2PFileManager sharedManager] allFileIds] count];
    }
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SearchCellIdentifier = @"SearchCellIdentifier";
    UITableViewCell *cell = nil;
    if ( tableView == self.searchDisplayController.searchResultsTableView )
    {
        cell = [tableView dequeueReusableCellWithIdentifier:SearchCellIdentifier];
        if ( cell == nil )
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SearchCellIdentifier];
        }
        cell.textLabel.text = [_searchResults objectAtIndex:indexPath.row];
    }
    else
    {
        P2PFileInCacheTableViewCell *infoCell = [tableView dequeueReusableCellWithIdentifier:FilesInCacheCellIdentifier];
        NSString *currentId = [[[P2PFileManager sharedManager] allFileIds] objectAtIndex:indexPath.row];
        infoCell.fileInfo = [[P2PFileManager sharedManager] fileInfoForFileId:currentId filename:nil];
        cell = infoCell;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView != self.searchDisplayController.searchResultsTableView;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( editingStyle == UITableViewCellEditingStyleDelete )
    {
        P2PFileInCacheTableViewCell *cell = (P2PFileInCacheTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        assert( [cell isMemberOfClass:[P2PFileInCacheTableViewCell class]] );
                 
        [[P2PFileManager sharedManager] deleteFileFromCache:cell.fileInfo];
//        [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.destinationViewController isKindOfClass:[P2PAddFileViewController class]] )
    {
        ((P2PAddFileViewController *)segue.destinationViewController).delegate = self;
    }
    else if ( [segue.destinationViewController isKindOfClass:[P2PFileInfoViewController class]] )
    {
        P2PFileInfoViewController *infoViewController = (P2PFileInfoViewController *)segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString *currentId = [[[P2PFileManager sharedManager] allFileIds] objectAtIndex:indexPath.row];
        
        P2PFileInfo *info = [[P2PFileManager sharedManager] fileInfoForFileId:currentId filename:nil];
        infoViewController.fileInfo = info;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The files tableview is handled by storyboard segue
    // We only need to handle search results here
    if ( tableView == self.searchDisplayController.searchResultsTableView )
    {
        
        
        NSString *filename = [_searchResults objectAtIndex:indexPath.row];
        [self startRequestingFile:filename];
        
        [self performSegueWithIdentifier:SeguePushFileInfo sender:self];
//        [self.searchDisplayController setActive:NO animated:YES];
    }
}

#pragma mark - Add File View Controller Delegate Methods
- (void)addFileController:(P2PAddFileViewController *)controller didSelectFileToAdd:(NSString *)filename
{
    [self startRequestingFile:filename];
    [self.tableView reloadData];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)startRequestingFile:(NSString *)filename
{
    P2PFileRequest *request = [[P2PFileRequest alloc] initWithFilename:filename];
    request.delegate = self;
    request.fileInfo.delegate = self;
    [request getFile];
}

#pragma mark - File Request Delegate Methods
- (void)fileRequest:(P2PFileRequest *)fileRequest didFindMultipleIds:(NSArray *)fileIds forFileName:(NSString *)filename
{
//    NSLog( @"%@", NSStringFromSelector(_cmd) );
}

- (void)fileRequestDidComplete:(P2PFileRequest *)fileRequest
{
//    NSLog( @"%@", NSStringFromSelector(_cmd) );
//    if ( [self.navigationController.topViewController isMemberOfClass:[P2PFileInfoViewController class]] )
//    {
//        P2PFileInfoViewController *vc = (P2PFileInfoViewController *)self.navigationController.topViewController;
//        [vc forceUpdateLabels];
//    }
}

- (void)fileRequestDidFail:(P2PFileRequest *)fileRequest withError:(P2PFileRequestError)errorCode
{
    NSString *detailMessage;
    switch ( errorCode )
    {
        case P2PFileRequestErrorCanceled:
            detailMessage = @"The request was canceled";
            break;
        case P2PFileRequestErrorMissingChunks:
            detailMessage = @"Could not locate all of the chunks for the file";
            break;
        case P2PFileRequestErrorMultipleIdsForFile:
            detailMessage = @"Multiple IDs were found for a filename.  An explicit fileId must be supplied";
            break;
        case P2PFileRequestErrorFileNotFound:
            detailMessage = @"Could not find the file on any connected peers";
            break;
        case P2PFileRequestErrorNone:
        default:
            assert( NO );
            break;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"File request failed" message:detailMessage delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
    [alert show];
}


#pragma mark - FileInfo Delegate Methods
- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateChunksAvailableFromPeers:(NSUInteger)chunksAvailable
{
    // Not handled here
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateChunksOnDisk:(NSUInteger)chunksOnDisk
{
    // Not handled here
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateFileId:(NSString *)fileId filename:(NSString *)filename
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kTableViewSectionDownloadingFiles] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateTotalChunks:(NSUInteger)totalChunks
{
    // Not handled here
}


#pragma mark - Search Bar Delegate
//- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//{
//    NSArray *allFileNames = [[[P2PFileManager sharedManager] filenamesToFileIds] allKeys];
//    NSPredicate *searchPredicate = [NSPredicate predicateWithBlock:^BOOL(NSString *evaluatedObject, NSDictionary *bindings)
//    {
//        return [evaluatedObject rangeOfString:searchText options:NSCaseInsensitiveSearch].length != 0;
//    }];
//    _searchResults = [allFileNames filteredArrayUsingPredicate:searchPredicate];
//}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSArray *allFileNames = [[[P2PFileManager sharedManager] filenamesToFileIds] allKeys];
    NSPredicate *searchPredicate = [NSPredicate predicateWithBlock:^BOOL(NSString *evaluatedObject, NSDictionary *bindings)
    {
        return [evaluatedObject rangeOfString:searchString options:NSCaseInsensitiveSearch].length != 0;
    }];
    _searchResults = [allFileNames filteredArrayUsingPredicate:searchPredicate];
    return YES;
}

//- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
//{
//    _searchResults = nil;
//    [self.tableView reloadData];
//}


@end
