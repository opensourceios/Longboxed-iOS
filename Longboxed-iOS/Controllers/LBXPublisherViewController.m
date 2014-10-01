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
#import "LBXPublisher.h"
#import "LBXClient.h"

#import "UIFont+customFonts.h"
#import "UIImage+CreateImage.h"
#import "UIImage+DrawOnImage.h"

#import <UIImageView+AFNetworking.h>

@interface LBXPublisherViewController () <UIToolbarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) LBXClient *client;
@property (nonatomic) NSArray *publishersArray;

@end

@implementation LBXPublisherViewController

static const NSUInteger PUBLISHER_LIST_TABLE_HEIGHT = 88;

NSInteger tableViewRows;
BOOL endOfPublishers;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _client = [LBXClient new];
    
    _tableView = [UITableView new];
    _tableView.frame = self.view.frame;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    // A little trick for removing the cell separators
    _tableView.tableFooterView = [UIView new];
    
    [self.view addSubview:_tableView];
    
    _tableView.scrollIndicatorInsets = _tableView.contentInset;
    
    [self setPublisherArrayWithPublishers];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.rowHeight = PUBLISHER_LIST_TABLE_HEIGHT;
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [self.navigationController.navigationBar.backItem.backBarButtonItem setImageInsets:UIEdgeInsetsMake(40, 40, -40, 40)];
    [self.navigationController.navigationBar setBackIndicatorImage:
     [UIImage imageNamed:@"arrow"]];
    [self.navigationController.navigationBar setBackIndicatorTransitionMaskImage:
     [UIImage imageNamed:@"arrow"]];
    
    // Make the nav par translucent again
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 16);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.shadowImage = nil;
    self.navigationController.navigationBar.topItem.title = @"Publishers";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    
    [self refreshViewWithPage:@1];
}

#pragma mark Private methods

- (void)setPublisherArrayWithPublishers
{
    // Get the latest issue in the database
    _publishersArray = [LBXPublisher MR_findAllSortedBy:@"name" ascending:YES];
}

- (void)refreshViewWithPage:(NSNumber *)page
{
    // Fetch this weeks comics
    [self.client fetchPublishersWithPage:page completion:^(NSArray *publisherArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            if (publisherArray.count == 0) {
                endOfPublishers = YES;
            }
            
            [self setPublisherArrayWithPublishers];
            
            tableViewRows = _publishersArray.count;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        else {
            [self setPublisherArrayWithPublishers];
            
            tableViewRows = _publishersArray.count;
            //[LBXMessageBar displayError:error];
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
    
    NSString *titleString = ([publisher.titleCount isEqual:@1]) ? ([NSString stringWithFormat:@"%@ Title", publisher.titleCount]) : ([NSString stringWithFormat:@"%@ Titles", publisher.titleCount]);
    
    NSString *issueString = ([publisher.titleCount isEqual:@1]) ? ([NSString stringWithFormat:@"%@ Issue", publisher.issueCount]) : ([NSString stringWithFormat:@"%@ Issues", publisher.issueCount]);
    
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@  •  %@", titleString, issueString];
    
    UIImage *defaultImage = [UIImage imageByDrawingInitialsOnImage:[UIImage imageWithColor:[UIColor clearColor] rect:cell.latestIssueImageView.frame] withInitials:publisher.name font:[UIFont defaultPublisherInitialsFont]];
    
    [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:publisher.smallLogo]] placeholderImage:defaultImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
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
    cell.subtitleLabel.numberOfLines = 2;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    // Setting the background color of the cell.
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LBXPublisher *publisher = [_publishersArray objectAtIndex:indexPath.row];
    
    LBXPublisherDetailViewController *publisherViewController = [[LBXPublisherDetailViewController alloc] initWithTopViewFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * 3/8)];
    
    publisherViewController.publisherID = publisher.publisherID;
    
    [self.navigationController pushViewController:publisherViewController animated:YES];
}

@end
