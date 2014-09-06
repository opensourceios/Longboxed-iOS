//
//  LBXPublisherCollectionViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/4/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXPublisherCollectionViewController.h"
#import "LBXClient.h"
#import "ParallaxFlowLayout.h"
#import "ParallaxPhotoCell.h"
#import "LBXNavigationViewController.h"
#import "LBXTitleAndPublisherServices.h"
#import "LBXPublisherDetailViewController.h"
#import "UIFont+customFonts.h"

#import <UIImageView+AFNetworking.h>

@interface LBXPublisherCollectionViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic) LBXClient *client;
@property (nonatomic) NSArray *publishersArray;
@property (nonatomic, strong) UILabel *noResultsLabel;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation LBXPublisherCollectionViewController

LBXNavigationViewController *navigationController;

// 2 publishers: 252    3 publishers: 168    4 publishers: 126
static const NSUInteger TABLE_HEIGHT_FOUR = 126;
static const NSUInteger TABLE_HEIGHT_THREE = 168;
static const NSUInteger TABLE_HEIGHT_TWO = 252;
static const NSUInteger TABLE_HEIGHT_ONE = 504;

NSInteger tableViewRows;
CGFloat cellWidth;
BOOL endOfPublishers;
int page;

- (id)init
{
    ParallaxFlowLayout *layout = [[ParallaxFlowLayout alloc] init];
    layout.minimumLineSpacing = 0; // Spacing between each cell
    //layout.sectionInset = UIEdgeInsetsMake(16, 16, 16, 16); // Cell insets
    
    self = [super initWithCollectionViewLayout:layout];
    
    if (self == nil) {
        return nil;
    }
    
    return self;
}

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    return [self init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[RKObjectManager sharedManager].operationQueue cancelAllOperations];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    _noResultsLabel = [UILabel new];
    
    // TODO: Use autolayout constraints
    _noResultsLabel.frame = CGRectMake(self.view.frame.origin.x + 30, self.view.frame.origin.y, self.view.frame.size.width - 60, self.view.frame.size.height);
    _noResultsLabel.textAlignment = NSTextAlignmentCenter;
    _noResultsLabel.textColor = [UIColor whiteColor];
    _noResultsLabel.font = [UIFont noResultsFont];
    _noResultsLabel.numberOfLines = 0;
    
    _noResultsLabel.frame = CGRectMake(self.view.frame.origin.x + 20, self.view.frame.origin.y, self.view.frame.size.width - 40, self.view.frame.size.height);
    _noResultsLabel.alpha = 0.0;
    
    _noResultsLabel.text = @"No Results";
    
    [self.view addSubview:_noResultsLabel];
    
    page = 1;
    endOfPublishers = NO;
    
    // Calls perferredStatusBarStyle
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.collectionView.alwaysBounceVertical = YES;
    [self.collectionView registerClass:[ParallaxPhotoCell class] forCellWithReuseIdentifier:@"PhotoCell"];
    
    // Special attribute set for title text color
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    tableViewRows = 0;
    
    // Add refresh
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refreshControlAction)
              forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:_refreshControl];
    
    // Add a footer loading spinner
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    spinner.frame = CGRectMake(0, 0, 320, 44);
    
    _publishersArray = [NSArray new];
    
    _client = [LBXClient new];
    
    [self setPublisherArrayWithPublishers];
    
    tableViewRows = _publishersArray.count;
    [self.collectionView reloadData];
    [_refreshControl endRefreshing];
    
    // Refresh the collection view
    if (!_publishersArray.count)[self refreshControlAction];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.shadowImage = nil;
    self.navigationController.navigationBar.topItem.title = @"Comics";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    
    [self setPublisherArrayWithPublishers];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    navigationController = (LBXNavigationViewController *)self.navigationController;
    [navigationController.menu setNeedsLayout];
}

- (void)refreshControlAction
{
    [_refreshControl beginRefreshing];
    [self refreshViewWithPage:@1];
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
                [self.collectionView reloadData];
                [_refreshControl endRefreshing];
            });
        }
        else {
            //[LBXMessageBar displayError:error];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_refreshControl endRefreshing];
            });
        }
    }];
}

- (void)setPublisherArrayWithPublishers
{
    // Get the latest issue in the database
   _publishersArray = [LBXPublisher MR_findAllSortedBy:@"name" ascending:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return tableViewRows;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"PhotoCell";
    __weak ParallaxPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    LBXPublisher *publisher = [_publishersArray objectAtIndex:indexPath.row];
    
    // grab bound for contentView
    CGRect contentViewBound = cell.comicImageView.bounds;
    
    NSString *publisherNameString = publisher.name;
    NSString *issueCountString =  [NSString stringWithFormat:@"%@ Issues",  [publisher.issueCount stringValue]];
    NSString *titleCountString =  [NSString stringWithFormat:@"%@ Titles",  [publisher.titleCount stringValue]];
    
    // If an image exists, fetch it. Else use the generated UIImage
    if (publisher.mediumSplash) {
        
        NSString *urlString = publisher.mediumSplash;
        
        // Show the network activity icon
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        cell.comicTitleLabel.text = nil;
        cell.comicPublisherLabel.text = nil;
        cell.comicIssueLabel.text = nil;
        
        [cell.activityIndicator startAnimating];
        
        // Get the image from the URL and set it
        [cell.comicImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] placeholderImage:[UIImage imageNamed:@"black"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [cell.activityIndicator stopAnimating];
            
            // Darken the image
            UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.comicImageView.frame.size.width, cell.comicImageView.frame.size.height*2)];
            [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
            NSArray *viewsToRemove = [cell.comicImageView subviews];
            for (UIView *v in viewsToRemove) [v removeFromSuperview];
            [cell.comicImageView addSubview:overlay];
            
            // Hide the network activity icon
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            if (request) {
                
                // Hide the network activity icon
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                
                [UIView transitionWithView:cell.comicImageView
                                  duration:0.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{[cell.comicImageView setImage:image];}
                                completion:NULL];
                
                [UIView transitionWithView:cell.comicTitleLabel
                                  duration:0.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{// Set the image label properties to center it in the cell
                                    [LBXTitleAndPublisherServices setLabel:cell.comicTitleLabel withString:publisherNameString inBoundsOfView:cell.comicImageView];}
                                completion:NULL];
                
                [UIView transitionWithView:cell.comicPublisherLabel
                                  duration:0.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{[cell.comicPublisherLabel setText:titleCountString];}
                                completion:NULL];
                
                [UIView transitionWithView:cell.comicIssueLabel
                                  duration:0.5f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{[cell.comicIssueLabel setText:issueCountString];}
                                completion:NULL];
            }
            else {
                // Set the image label properties to center it in the cell
                [LBXTitleAndPublisherServices setLabel:cell.comicTitleLabel withString:publisherNameString inBoundsOfView:cell.comicImageView];
                cell.comicImageView.image = image;
                cell.comicPublisherLabel.text = titleCountString;
                cell.comicIssueLabel.text =  issueCountString;
            }
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            
            [cell.activityIndicator stopAnimating];
            
            // Hide the network activity icon
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            [self setPublisher:publisher forCell:cell];
        }];
        
        CGRect imageViewFrame = cell.comicImageView.frame;
        // change x position
        imageViewFrame.origin.y = contentViewBound.size.height - imageViewFrame.size.height;
        // assign the new frame
        cell.comicImageView.frame = imageViewFrame;
        cell.comicImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    else {
        [self setPublisher:publisher forCell:cell];
    }
    
    
    // Pass the maximum parallax offset to the cell.
    // The cell needs this information to configure the constraints for its image view.
    ParallaxFlowLayout *layout = (ParallaxFlowLayout *)self.collectionViewLayout;
    cell.maxParallaxOffset = layout.maxParallaxOffset;
    
    if ([indexPath row] == _publishersArray.count - 1 && !endOfPublishers) {
        page += 1;
        [self refreshViewWithPage:[NSNumber numberWithInt:page]];
    }

    return cell;
}

- (void)setPublisher:(LBXPublisher *)publisher forCell:(ParallaxPhotoCell *)cell
{
    
    NSString *publisherNameString = publisher.name;
    NSString *issueCountString =  [NSString stringWithFormat:@"%@ Issues",  [publisher.issueCount stringValue]];
    NSString *titleCountString =  [NSString stringWithFormat:@"%@ Titles",  [publisher.titleCount stringValue]];
    
    CGSize size = CGSizeMake(cell.comicImageView.frame.size.width, cell.comicImageView.frame.size.width);
    
    UIImage *defaultImage = [LBXTitleAndPublisherServices generateImageForPublisher:publisher size:size];
    
    cell.comicPublisherLabel.text = issueCountString;
    cell.comicIssueLabel.text =  titleCountString;
    
    // Darken the image
    UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.comicImageView.frame.size.width, cell.comicImageView.frame.size.height*2)];
    [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    NSArray *viewsToRemove = [cell.comicImageView subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];
    [cell.comicImageView addSubview:overlay];
    
    cell.comicImageView.image = defaultImage;
    
    // Set the image label properties to center it in the cell
    [LBXTitleAndPublisherServices setLabel:cell.comicTitleLabel withString:publisherNameString inBoundsOfView:cell.comicImageView];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    LBXPublisher *publisher = [_publishersArray objectAtIndex:indexPath.row];
    
    LBXPublisherDetailViewController *publisherViewController = [[LBXPublisherDetailViewController alloc] initWithTopViewFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * 3/8)];
    
    publisherViewController.publisherID = publisher.publisherID;
    
    [self.navigationController pushViewController:publisherViewController animated:YES];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Compute cell size according to image aspect ratio.
    // Cell height must take maximum possible parallax offset into account.
    ParallaxFlowLayout *layout = (ParallaxFlowLayout *)self.collectionViewLayout;
    cellWidth = CGRectGetWidth(self.collectionView.bounds) - layout.sectionInset.left - layout.sectionInset.right;
    switch (_publishersArray.count) {
        case 0:
        case 1:
            return CGSizeMake(cellWidth, TABLE_HEIGHT_ONE);
            break;
        case 2:
            return CGSizeMake(cellWidth, TABLE_HEIGHT_TWO);
            break;
        case 3:
            return CGSizeMake(cellWidth, TABLE_HEIGHT_THREE);
            break;
        default:
            return CGSizeMake(cellWidth, TABLE_HEIGHT_FOUR);
            break;
    }
    return CGSizeMake(cellWidth, TABLE_HEIGHT_FOUR);
}


@end
