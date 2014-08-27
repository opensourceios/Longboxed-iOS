//
//  LBXTitleViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//
#import "LBXClient.h"
#import "LBXMessageBar.h"
#import "LBXPullListTableViewCell.h"
#import "LBXPullListTitle.h"
#import "LBXTitle.h"
#import "LBXTitleDetailView.h"
#import "LBXTitleDetailViewController.h"
#import "LBXTitleServices.h"
#import "LBXIssueDetailViewController.h"
#import "LBXIssueScrollViewController.h"
#import "LBXPublisherDetailViewController.h"

#import "UIFont+customFonts.h"
#import "NSArray+ArrayUtilities.h"
#import "JTSImageViewController.h"
#import "JGActionSheet.h"

#import <SVProgressHUD.h>
#import <QuartzCore/QuartzCore.h>

@interface LBXTitleDetailViewController () <UIScrollViewDelegate, JTSImageViewControllerInteractionsDelegate, JGActionSheetDelegate>

@property (nonatomic, copy) LBXTitle *detailTitle;
@property (nonatomic, copy) LBXClient *client;
@property (nonatomic, copy) LBXTitleDetailView *detailView;
@property (nonatomic, copy) NSArray *pullListArray;
@property (nonatomic, copy) NSArray *issuesForTitleArray;
@property (nonatomic) NSNumber *page;

@end

@implementation LBXTitleDetailViewController

static const NSUInteger ISSUE_TABLE_HEIGHT = 88;
static BOOL addToPullList = NO;
BOOL endOfIssues;
BOOL saveSheetVisible;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Calls perferredStatusBarStyle
    [self setNeedsStatusBarAppearanceUpdate];
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"clear"] style:UIBarButtonItemStylePlain target:self action:nil];
    self.navigationItem.rightBarButtonItem = actionButton;
    self.title = _detailTitle.name;
    
    endOfIssues = NO;
    
    _client = [LBXClient new];
    
    [self createPullListArray];
    [self createIssuesArray];
    
    [self setDetailView];
    [self setOverView:_detailView];
    
    [self fetchTitle];
    [self fetchPullList];
    [self fetchAllIssuesWithPage:@1];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar.backItem.backBarButtonItem setImageInsets:UIEdgeInsetsMake(40, 40, -40, 40)];
    [self.navigationController.navigationBar setBackIndicatorImage:
     [UIImage imageNamed:@"arrow"]];
    [self.navigationController.navigationBar setBackIndicatorTransitionMaskImage:
     [UIImage imageNamed:@"arrow"]];
    self.tableView.rowHeight = ISSUE_TABLE_HEIGHT;
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;

    if (_detailView.latestIssueImageView.image.size.height > 200.0) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                      forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        
        self.navigationController.navigationBar.translucent = YES;
        self.navigationController.view.backgroundColor = [UIColor clearColor];
    }
    else {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
    }
    
    [self setNavBarAlpha:@0];

    // Keep the section header on the top
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 64, 0);
    
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBar.topItem.title = _detailTitle.name;
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    if (self.tableView.contentOffset.y > 0) {
        // Set the title alpha properly when returning from the issue view
        [self setNavBarAlpha:@(1 - self.overView.alpha)];
    }
    else {
        [self setNavBarAlpha:@0];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self setNavBarAlpha:@1];
    self.navigationController.navigationBar.topItem.title = @" ";
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (void)setDetailView
{
    _detailView = [LBXTitleDetailView new];
    _detailView.frame = self.overView.frame;
    _detailView.bounds = self.overView.bounds;
    _detailView.titleLabel.font = [UIFont titleDetailTitleFont];
    _detailView.titleLabel.numberOfLines = 2;
    [_detailView.titleLabel sizeToFit];
    _detailView.publisherButton.titleLabel.font = [UIFont titleDetailPublisherFont];
    
    [self updateDetailView];
    
    [self setPullListButton];
    _detailView.addToPullListButton.titleLabel.font = [UIFont titleDetailAddToPullListFont];
    _detailView.addToPullListButton.layer.borderWidth = 1.0f;
    _detailView.addToPullListButton.layer.cornerRadius = 19.0f;
    _detailView.latestIssueImageView.image = _latestIssueImage;
    [_detailView.latestIssueImageView sizeToFit];
}

- (void)updateDetailView
{
    _detailView.titleLabel.text = _detailTitle.name;
    
    // When loading the title info
    if (_detailTitle.publisher.name == nil) {
        [_detailView.publisherButton setTitle:@"Loading..." forState:UIControlStateNormal];
        _detailView.issuesAndSubscribersLabel.text = @"";
        [_detailView.publisherButton setTitle:@"Loading..." forState:UIControlStateNormal];
        _detailView.publisherButton.userInteractionEnabled = NO;
    }
    else {
        _detailView.publisherButton.userInteractionEnabled = YES;
        [_detailView.publisherButton setTitle:[_detailTitle.publisher.name uppercaseString] forState:UIControlStateNormal];
        
        NSString *issuesString;
        if ([_detailTitle.issueCount isEqualToNumber:@1]) {
            issuesString = [NSString stringWithFormat:@"%@ Issue", _detailTitle.issueCount];
        }
        else {
            issuesString = [NSString stringWithFormat:@"%@ Issues", _detailTitle.issueCount];
        }
        
        NSString *subscribersString;
        if ([_detailTitle.subscribers isEqualToNumber:@1]) {
            subscribersString = [NSString stringWithFormat:@"%@ Subscriber", _detailTitle.subscribers];
        }
        else {
            NSLog(@"%@", _detailTitle.subscribers);
            subscribersString = [NSString stringWithFormat:@"%@ Subscribers", _detailTitle.subscribers];
        }
        
        _detailView.issuesAndSubscribersLabel.text = [NSString stringWithFormat:@"%@  •  %@", [issuesString uppercaseString], [subscribersString uppercaseString]];
        _detailView.issuesAndSubscribersLabel.font = [UIFont titleDetailSubscribersAndIssuesFont];
    }
    
    // Move the arrow so it is on the right side of the publisher text
    _detailView.publisherButton.titleEdgeInsets = UIEdgeInsetsMake(0, -_detailView.publisherButton.imageView.frame.size.width, 0, _detailView.publisherButton.imageView.frame.size.width);
    _detailView.publisherButton.imageEdgeInsets = UIEdgeInsetsMake(0, _detailView.publisherButton.titleLabel.frame.size.width + 8, 0, -_detailView.publisherButton.titleLabel.frame.size.width);
    _detailView.publisherButton.tag = 1;
    [_detailView.publisherButton addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _detailView.latestIssueLabel.font = [UIFont titleDetailLatestIssueFont];
    if ([LBXTitleServices lastIssueForTitle:_detailTitle] != nil) {
        LBXIssue *issue = [LBXTitleServices lastIssueForTitle:_detailTitle];
        NSString *timeSinceString = [LBXTitleServices timeSinceLastIssueForTitle:_detailTitle];
        
        NSString *subtitleString = [NSString stringWithFormat:@"Issue %@ released %@", issue.issueNumber, timeSinceString];
        if ([timeSinceString hasPrefix:@"in"]) {
            NSLog(@"%@", issue.issueNumber);
            subtitleString = [NSString stringWithFormat:@"Issue %@ will be released %@", issue.issueNumber, timeSinceString];
        }
        _detailView.latestIssueLabel.text = subtitleString;
    }
    else if (!_issuesForTitleArray.count) {
        _detailView.latestIssueLabel.text = @"No issues released";
    }
    else {
        _detailView.latestIssueLabel.text = @"";
    }
    
    _detailView.imageViewButton.tag = 2;
    [_detailView.imageViewButton addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view setNeedsDisplay];
}

- (void)setInitialDetailView
{
    // Move the arrow so it is on the right side of the publisher text
    _detailView.publisherButton.titleEdgeInsets = UIEdgeInsetsMake(0, -_detailView.publisherButton.imageView.frame.size.width, 0, _detailView.publisherButton.imageView.frame.size.width);
    _detailView.publisherButton.imageEdgeInsets = UIEdgeInsetsMake(0, _detailView.publisherButton.titleLabel.frame.size.width + 8, 0, -_detailView.publisherButton.titleLabel.frame.size.width);
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark JTSImageViewControllerInteractionsDelegate methods

- (void)imageViewerDidLongPress:(JTSImageViewController *)imageViewer
{
    if (!saveSheetVisible) {
        JGActionSheetSection *section1 = [JGActionSheetSection sectionWithTitle:nil message:nil buttonTitles:@[@"Save Image", @"Copy Image"] buttonStyle:JGActionSheetButtonStyleDefault];
        JGActionSheetSection *cancelSection = [JGActionSheetSection sectionWithTitle:nil message:nil buttonTitles:@[@"Cancel"] buttonStyle:JGActionSheetButtonStyleCancel];
        
        NSArray *sections = @[section1, cancelSection];
        
        JGActionSheet *sheet = [JGActionSheet actionSheetWithSections:sections];
        sheet.delegate = self;
        
        [sheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
            [sheet dismissAnimated:YES];
            saveSheetVisible = NO;
        }];
        saveSheetVisible = YES;
        [sheet showInView:imageViewer.view animated:YES];
    }
}

#pragma mark JGActionSheetDelegate methods

- (void)actionSheet:(JGActionSheet *)actionSheet pressedButtonAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                {
                    UIImageWriteToSavedPhotosAlbum(_detailView.latestIssueImageView.image, nil, nil, nil);
                    break;
                }
                case 1:
                {
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    [pasteboard setImage:_detailView.latestIssueImageView.image];
                    [SVProgressHUD showSuccessWithStatus:@"Copied!"];
                    break;
                }
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

- (BOOL)imageViewerShouldTemporarilyIgnoreTouches:(JTSImageViewController *)imageViewer
{
    if (saveSheetVisible) return YES;
    return NO;
}

#pragma mark - Private methods

- (void)setPullListButton
{
    _detailView.addToPullListButton.tag = 0;
    [_detailView.addToPullListButton addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
    LBXTitle *title = [LBXPullListTitle MR_findFirstByAttribute:@"titleID" withValue:_detailTitle.titleID];
    if (title) {
        [_detailView.addToPullListButton setTitle:@"     REMOVE FROM PULL LIST     " forState:UIControlStateNormal];
        _detailView.addToPullListButton.layer.borderColor = [[UIColor whiteColor] CGColor];
        addToPullList = YES;
    }
    else {
        [_detailView.addToPullListButton setTitle:@"     ADD TO PULL LIST     " forState:UIControlStateNormal];
        _detailView.addToPullListButton.layer.borderColor = [[UIColor whiteColor] CGColor];
        addToPullList = NO;
    }
}

- (IBAction)onClick:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch ([button tag]) {
        case 0: // Add title to pull list
        {
            if (addToPullList == YES) {
                [self deleteTitle:_detailTitle];
                addToPullList = NO;
                 [_detailView.addToPullListButton setTitle:@"     ADD TO PULL LIST     " forState:UIControlStateNormal];
            }
            else if (addToPullList == NO) {
                addToPullList = YES;
                [self addTitle:_detailTitle];
                [_detailView.addToPullListButton setTitle:@"     REMOVE FROM PULL LIST     " forState:UIControlStateNormal];
            }
            break;
        }
        case 1:
        {
            LBXPublisher *publisher = [LBXPublisher MR_findFirstByAttribute:@"publisherID" withValue:_detailTitle.publisher.publisherID];
            LBXPublisherDetailViewController *publisherViewController = [[LBXPublisherDetailViewController alloc] initWithMainImageURL:publisher.mediumLogoBW andTopViewFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * 3/8)];
            
            publisherViewController.publisherID = _detailTitle.publisher.publisherID;
            
            [self.navigationController pushViewController:publisherViewController animated:YES];
            break;
        }
        case 2:
        {
            // Create image info
            JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
            imageInfo.image = _detailView.latestIssueImageView.image;
            imageInfo.referenceRect = _detailView.latestIssueImageView.frame;
            imageInfo.referenceView = _detailView.latestIssueImageView.superview;
            
            // Setup view controller
            JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                                   initWithImageInfo:imageInfo
                                                   mode:JTSImageViewControllerMode_Image
                                                   backgroundStyle:JTSImageViewControllerBackgroundStyle_ScaledDimmedBlurred];
            imageViewer.interactionsDelegate = self;
            
            // Present the view controller.
            [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
            
            // Make the status bar white again for when dismissing the image view
            self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
            
            break;
        }
    }
}

- (void)setDetailTitleWithID:(NSNumber *)ID
{
    _detailTitle = [LBXTitle MR_findFirstByAttribute:@"titleID" withValue:ID];
}

- (void)fetchPullList
{
    // Fetch pull list titles
    [_client fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [self createPullListArray];
        }
        else {
            //[LBXMessageBar displayError:error];
        }
        [self.view setNeedsDisplay];
    }];
}

- (void)fetchTitle
{
    [_client fetchTitle:_titleID withCompletion:^(LBXTitle *title, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            _detailTitle = title;
            [self updateDetailView];
        }
        else {
            //[LBXMessageBar displayError:error];
        }
        [self.view setNeedsDisplay];
    }];
}

- (void)createPullListArray
{
    _pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
}

- (void)fetchAllIssuesWithPage:(NSNumber *)page
{
    // Fetch pull list titles
    [_client fetchIssuesForTitle:_titleID page:page withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            if (pullListArray.count == 0) {
                endOfIssues = YES;
            }
            
            // Fetch all the alternate titles too
            for (LBXIssue *issue in pullListArray) {
                for (NSDictionary *dict in issue.alternates) {
                    LBXClient *client = [LBXClient new];
                    [client fetchIssue:dict[@"id"] withCompletion:^(LBXIssue *issue, RKObjectRequestOperation *response, NSError *error) {
                        if (!error) {
                        }
                        else {
                            //[LBXMessageBar displayError:error];
                        }
                    }];
                }
            }
            
            [self createIssuesArray];
            [self.tableView reloadData];
            [self.view setNeedsDisplay];
        }
        else {
            //[LBXMessageBar displayError:error];
        }
    }];
}

- (void)createIssuesArray
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(title == %@) AND (isParent == 1)", _detailTitle];
    NSArray *initialFind = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    // Not all parents are actually the parents (sometimes a variant is a parent due to API bug)
    // so correct this by getting the issue with the shortest title
    // TODO: Get Tim to fix this
    NSMutableArray *correctedArray = [NSMutableArray new];
    for (LBXIssue *issue in initialFind) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(title == %@) AND (issueNumber == %@)", issue.title, issue.issueNumber];
        NSArray *issuesArray = [LBXIssue MR_findAllSortedBy:@"completeTitle" ascending:YES withPredicate:predicate];
        [correctedArray addObject:issuesArray[0]];
    }
    
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:correctedArray];
    
    NSSortDescriptor *sortByIssueID = [NSSortDescriptor sortDescriptorWithKey:@"issueID" ascending:NO];
    NSSortDescriptor *sortByIssueNumber = [NSSortDescriptor sortDescriptorWithKey:@"issueNumber" ascending:NO];
    NSSortDescriptor *sortByIssueReleaseDate = [NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:NO];
    
    // Combine the two
    NSArray *sortDescriptors = @[sortByIssueReleaseDate, sortByIssueNumber, sortByIssueID];
    

    _issuesForTitleArray = [mutableArray sortedArrayUsingDescriptors:sortDescriptors];
    
}

- (void)setNavBarAlpha:(NSNumber *)alpha
{
    if (_detailView.latestIssueImageView.image.size.height > 200.0) {
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:[alpha doubleValue]], NSFontAttributeName : [UIFont navTitleFont]}];
    }
    else {
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor], NSFontAttributeName : [UIFont navTitleFont]}];
    }
}

- (void)addTitle:(LBXTitle *)title
{
    LBXTitle *saveTitle = [LBXTitle MR_createEntity];
    saveTitle = title;
    LBXPullListTitle *pullListTitle = [LBXPullListTitle MR_createEntity];
    pullListTitle.name = title.name;
    pullListTitle.subscribers = title.subscribers;
    pullListTitle.publisher = title.publisher;
    pullListTitle.titleID = title.titleID;
    pullListTitle.issueCount = title.issueCount;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self createPullListArray];
    [self.client addTitleToPullList:title.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        if (!error) {
        }
        else {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Unable to add %@\n%@", title.name, error.localizedDescription]];
        }
    }];
}

- (void)deleteTitle:(LBXTitle *)title
{
    // Fetch pull list titles
    [self.client removeTitleFromPullList:title.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        if (!error) {
            _pullListArray = pullListArray;
        }
        else {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Unable to delete %@\n%@", title.name, error.localizedDescription]];
        }
    }];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"titleID == %@", title.titleID];
    [LBXPullListTitle deleteAllMatchingPredicate:predicate];
    [self createPullListArray];
}

#pragma mark - Setter overrides

- (void)setTitleID:(NSNumber *)titleID
{
    _titleID = titleID;
    [self setDetailTitleWithID:titleID];
}

#pragma mark - UITableView Delegate & Datasource

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return [super tableView:tableView viewForHeaderInSection:section];
    
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Background color
    view.tintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8];
    
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor blackColor]];
    header.textLabel.font = [UIFont titleDetailSubscribersAndIssuesFont];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 1)
        return @"Issues";
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return [super tableView:tableView heightForHeaderInSection:section];
    
    if(section == 1)
        return 18.0;
    
    return 0.0;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger mySections = 1;
    
    return mySections + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section != 1) {
        return 0;
    }
    if (_issuesForTitleArray.count <= 3) {
        return 3;
    }
    
    return _issuesForTitleArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PullListCell";
    
    LBXPullListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        // Custom cell as explained here: https://medium.com/p/9bee5824e722
        [tableView registerNib:[UINib nibWithNibName:@"LBXPullListTableViewCell" bundle:nil] forCellReuseIdentifier:@"PullListCell"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"PullListCell"];
        
        // Remove inset of iOS 7 separators.
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsZero;
        }
        
    }
    
    if ([indexPath row] == _issuesForTitleArray.count - 1 && !endOfIssues) {
        int value = [_page integerValue];
        _page = [NSNumber numberWithInt:value+1];
        [self fetchAllIssuesWithPage:_page];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(LBXPullListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    if (_issuesForTitleArray.count <= indexPath.row) {
        return;
    }

    LBXIssue *issue = [_issuesForTitleArray objectAtIndex:indexPath.row];
    
    cell.titleLabel.font = [UIFont pullListTitleFont];
    cell.titleLabel.text = issue.completeTitle;
    cell.titleLabel.numberOfLines = 2;
    cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    cell.subtitleLabel.font = [UIFont pullListSubtitleFont];
    cell.subtitleLabel.textColor = [UIColor grayColor];
    cell.subtitleLabel.numberOfLines = 2;
    
    cell.latestIssueImageView.image = nil;
    
    [LBXTitleServices setTitleCell:cell withIssue:issue];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    // Setting the background color of the cell.
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y > 0) {
        [self setNavBarAlpha:@(1 - self.overView.alpha)];
    }
    else {
        [self setNavBarAlpha:@0];
    }
    return [super scrollViewDidScroll:scrollView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Disselect and return immediately if selecting an empty cell
    // i.e., one below the last issue
    if (_issuesForTitleArray.count < indexPath.row+1) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    LBXIssue *issue = [_issuesForTitleArray objectAtIndex:indexPath.row];
    LBXPullListTableViewCell *cell = (LBXPullListTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    // Set up the scroll view controller containment if there are alternate issues
    if (issue.alternates.count) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(title == %@) AND (issueNumber == %@)", issue.title, issue.issueNumber];
        NSArray *issuesArray = [LBXIssue MR_findAllSortedBy:@"completeTitle" ascending:YES withPredicate:predicate];
        LBXIssueScrollViewController *scrollViewController = [[LBXIssueScrollViewController alloc] initWithIssues:issuesArray andImage:cell.latestIssueImageView.image];
        [self.navigationController pushViewController:scrollViewController animated:YES];
    }
    else {
        LBXIssueDetailViewController *titleViewController = [[LBXIssueDetailViewController alloc] initWithMainImage:cell.latestIssueImageView.image];
        titleViewController.issue = issue;
        [self.navigationController pushViewController:titleViewController animated:YES];
    }
    
}

@end
