//
//  LBXPublisherViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/30/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXPublisherViewController.h"
#import "LBXPublisherListTableViewCell.h"
#import "LBXPublisherDetailViewController.h"
#import "LBXControllerServices.h"
#import "LBXPublisher.h"
#import "LBXClient.h"

#import "UIFont+LBXCustomFonts.h"
#import "UIImage+LBXCreateImage.h"
#import "UIImage+DrawOnImage.h"

#import <UIImageView+AFNetworking.h>
#import <UIImage+CreateImage.h>
#import "LBXLogging.h"
#import "SVProgressHUD.h"
#import "LBXEmptyViewController.h"
#import <CBStoreHouseRefreshControl.h>

@interface LBXPublisherViewController () <UIToolbarDelegate, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) LBXClient *client;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) CBStoreHouseRefreshControl *storeHouseRefreshControl;

@end

@implementation LBXPublisherViewController

static const NSUInteger PUBLISHER_LIST_TABLE_HEIGHT = 88;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _client = [LBXClient new];
    
    UILabel *label = [UILabel new];
    label.text = @"Publishers";
    label.font = [UIFont navTitleFont];
    [label sizeToFit];
    
    self.navigationItem.titleView = label;
    
    self.tableView = [UITableView new];
    self.tableView.frame = self.view.frame;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    // Add refresh
    self.storeHouseRefreshControl = [CBStoreHouseRefreshControl attachToScrollView:self.tableView target:self refreshAction:@selector(refresh) plist:@"storehouse" color:[UIColor blackColor] lineWidth:1
                                                                        dropHeight:80
                                                                             scale:1
                                                              horizontalRandomness:150
                                                           reverseLoadingAnimation:YES
                                                           internalAnimationFactor:0.7];
    
    [self.view addSubview:self.tableView];
    
    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        [LBXLogging logMessage:[NSString stringWithFormat:@"Unresolved error %@, %@", error, [error userInfo]]];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.rowHeight = PUBLISHER_LIST_TABLE_HEIGHT;
    
    [LBXControllerServices setViewWillAppearWhiteNavigationController:self];
    
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 16);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [LBXControllerServices setViewDidAppearWhiteNavigationController:self];
    
    // There are at least 9 publishers
    if (_fetchedResultsController.fetchedObjects.count < 9) {
        self.tableView.hidden = YES;
        [SVProgressHUD showAtPosY:self.view.frame.size.height/2];
    }
    
    [self refresh];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
    [SVProgressHUD setForegroundColor: [UIColor blackColor]];
    [SVProgressHUD setBackgroundColor: [UIColor whiteColor]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.storeHouseRefreshControl scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.storeHouseRefreshControl scrollViewDidEndDragging];
}

#pragma mark Private methods

- (void)refresh
{
    [self refreshViewWithPage:@1];
}

- (void)refreshViewWithPage:(NSNumber *)page
{
    // Fetch this weeks comics
    [self.client fetchPublishersWithPage:page completion:^(NSArray *publisherArray, RKObjectRequestOperation *response, NSError *error) {
        [self.storeHouseRefreshControl finishingLoading];
        if (!error) {
            if (publisherArray.count == 0) {
                self.tableView.hidden = NO;
                if (!_fetchedResultsController.fetchedObjects.count) {
                    [LBXControllerServices showEmptyViewOverTableView:self.tableView];
                }
                [SVProgressHUD dismiss];
            }
            else {
                int value = [page intValue];
                [self refreshViewWithPage:[NSNumber numberWithInt:value + 1]];
            }
        }
        else if (!_fetchedResultsController.fetchedObjects.count) {
            self.tableView.hidden = NO;
            [SVProgressHUD dismiss];
            [LBXControllerServices showEmptyViewOverTableView:self.tableView];
        }
    }];
}

#pragma mark UITableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _fetchedResultsController.fetchedObjects.count;
}

- (LBXPublisherListTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PublisherListTableViewCell";
    
    LBXPublisherListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        // Custom cell as explained here: https://medium.com/p/9bee5824e722
        [tableView registerNib:[UINib nibWithNibName:@"LBXPublisherListTableViewCell" bundle:nil] forCellReuseIdentifier:@"PublisherListTableViewCell"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"PublisherListTableViewCell"];
    }
    
    cell.titleLabel.font = [UIFont pullListTitleFont];

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(LBXPublisherListTableViewCell *)cell atIndexPath:(NSIndexPath*)indexPath {
    
    LBXPublisher *publisher = [_fetchedResultsController objectAtIndexPath:indexPath];
    cell.titleLabel.text = publisher.name;
    
    NSString *titleString = ([publisher.titleCount isEqual:@1]) ? ([NSString stringWithFormat:@"%@ TITLE", publisher.titleCount]) : ([NSString stringWithFormat:@"%@ TITLES", publisher.titleCount]);
    
    NSString *issueString = ([publisher.titleCount isEqual:@1]) ? ([NSString stringWithFormat:@"%@ ISSUE", publisher.issueCount]) : ([NSString stringWithFormat:@"%@ ISSUES", publisher.issueCount]);
    
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@  •  %@", titleString, issueString];
    
    UIImage *defaultImage = [UIImage imageByDrawingInitialsOnImage:[UIImage imageWithColor:[UIColor clearColor] rect:cell.latestIssueImageView.frame] withInitials:publisher.name font:[UIFont defaultPublisherInitialsFont]];
    cell.latestIssueImageView.image = defaultImage;
    
    [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:publisher.smallLogo]] placeholderImage:[UIImage singlePixelImageWithColor:[UIColor clearColor]] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
        // Only fade in the image if it was fetched (not from cache)
        if (request) {
            [UIView transitionWithView:cell.latestIssueImageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{cell.latestIssueImageView.image = image;}
                            completion:NULL];
        }
        else {
            cell.latestIssueImageView.image = image;
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        cell.latestIssueImageView.image = defaultImage;
    }];
    
    cell.latestIssueImageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.latestIssueImageView.clipsToBounds = YES;
    
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(LBXPublisherListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.titleLabel.font = [UIFont pullListTitleFont];
    cell.titleLabel.numberOfLines = 2;
    cell.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    cell.subtitleLabel.font = [UIFont pullListSubtitleFont];
    cell.subtitleLabel.textColor = [UIColor grayColor];
    cell.subtitleLabel.numberOfLines = 1;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    // Setting the background color of the cell.
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LBXPublisher *publisher = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    LBXPublisherDetailViewController *publisherViewController = [LBXPublisherDetailViewController new];
    publisherViewController.publisherID = publisher.publisherID;
    
    [self.navigationController pushViewController:publisherViewController animated:YES];
}

#pragma mark NSFetchedResultsController Methods

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    _fetchedResultsController = [LBXPublisher MR_fetchAllSortedBy:@"name" ascending:YES withPredicate:nil groupBy:nil delegate:self];
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(LBXPublisherListTableViewCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

@end
