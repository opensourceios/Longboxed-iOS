//
//  LBXPublisherViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/30/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXPublisherTableViewController.h"
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
#import <Doppelganger.h>

@interface LBXPublisherTableViewController () <UIToolbarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) LBXClient *client;
@property (nonatomic) NSArray *publishersArray;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation LBXPublisherTableViewController

static const NSUInteger PUBLISHER_LIST_TABLE_HEIGHT = 88;

NSInteger tableViewRows;
BOOL endOfPublishers;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _client = [LBXClient new];
    
    UILabel *label = [UILabel new];
    label.text = @"Publishers";
    label.font = [UIFont navTitleFont];
    [label sizeToFit];
    
    self.navigationItem.titleView = label;
    
    // Add refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl]; // So that the swipe cells aren't blocked
    
    self.tableView = [UITableView new];
    self.tableView.frame = self.view.frame;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    [self setPublisherArrayWithPublishers];
    // Do any additional setup after loading the view.
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
    
    [self refresh];
}

#pragma mark Private methods

- (void)refresh
{
    [self refreshViewWithPage:@1];
}

- (void)setPublisherArrayWithPublishers
{
    // Get the latest issue in the database
    NSArray *previousPublishersArray = _publishersArray;
    _publishersArray = [LBXPublisher MR_findAllSortedBy:@"name" ascending:YES];
    if (previousPublishersArray) {
        NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:_publishersArray
                                                    previousArray:previousPublishersArray];
        [self.tableView wml_applyBatchChanges:diffs
                                    inSection:0
                             withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView reloadData];
    }
    else [self.tableView reloadData];
}

- (void)refreshViewWithPage:(NSNumber *)page
{
    // Fetch this weeks comics
    [self.client fetchPublishersWithPage:page completion:^(NSArray *publisherArray, RKObjectRequestOperation *response, NSError *error) {
        [self.refreshControl endRefreshing];
        if (!error) {
            if (publisherArray.count == 0) {
                endOfPublishers = YES;
            }
            
            NSArray *previousPublishersArray = _publishersArray;
            _publishersArray = publisherArray;
            
            tableViewRows = _publishersArray.count;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (previousPublishersArray) {
                    NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:_publishersArray
                                                                previousArray:previousPublishersArray];
                    [self.tableView wml_applyBatchChanges:diffs
                                                inSection:0
                                         withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableView reloadData];
                }
                else [self.tableView reloadData];
            });
        }
        else {
            [self setPublisherArrayWithPublishers];
            
            tableViewRows = _publishersArray.count;
        }
    }];
}

#pragma mark UITableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _publishersArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PublisherListTableViewCell";
    
    LBXPublisherListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        // Custom cell as explained here: https://medium.com/p/9bee5824e722
        [tableView registerNib:[UINib nibWithNibName:@"LBXPublisherListTableViewCell" bundle:nil] forCellReuseIdentifier:@"PublisherListTableViewCell"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"PublisherListTableViewCell"];
    }
    
    cell.titleLabel.font = [UIFont pullListTitleFont];
    
    LBXPublisher *publisher = [_publishersArray objectAtIndex:indexPath.row];
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
    
    return cell;
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
    LBXPublisher *publisher = [_publishersArray objectAtIndex:indexPath.row];
    
    LBXPublisherDetailViewController *publisherViewController = [LBXPublisherDetailViewController new];
    publisherViewController.publisherID = publisher.publisherID;
    
    [self.navigationController pushViewController:publisherViewController animated:YES];
}

@end
