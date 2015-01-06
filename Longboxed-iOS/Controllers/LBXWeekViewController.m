//
//  LBXWeekTableViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 9/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXWeekViewController.h"
#import "LBXWeekTableViewCell.h"
#import "LBXClient.h"
#import "LBXIssueScrollViewController.h"
#import "LBXIssueDetailViewController.h"
#import "LBXLogging.h"
#import "LBXControllerServices.h"
#import "ESDatePicker.h"

#import "UIFont+LBXCustomFonts.h"
#import "NSDate+DateUtilities.h"
#import "UIFont+LBXCustomFonts.h"
#import "NSArray+LBXArrayUtilities.h"
#import "UIColor+LBXCustomColors.h"
#import "UIImage+LBXCreateImage.h"

#import <FontAwesomeKit/FontAwesomeKit.h>
#import <SVProgressHUD.h>
#import "Masonry.h"

@interface LBXWeekViewController () <UIToolbarDelegate, UITableViewDelegate, UITableViewDataSource,
                                     ESDatePickerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UIToolbar *toolBar;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, copy) LBXClient *client;
@property (nonatomic, copy) NSArray *issuesForWeekArray;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSArray *sectionArray;
@property (nonatomic, strong) NSString *customNavTitle;

@property (nonatomic, strong) UINavigationController *calendarNavController;
@property (nonatomic, strong) ESDatePicker *calendarView;
@property (nonatomic, strong) NSDate *selectedWednesday;
@property (nonatomic, strong) UIView *maskLoadingView;

@end

@implementation LBXWeekViewController

static const NSUInteger ISSUE_TABLE_HEIGHT = 88;

CGFloat cellWidth;
BOOL _segmentedShowBool;
BOOL _displayReleasesOfDate;
BOOL _showedCalendar;
int _page;

- (id)init
{
    _segmentedShowBool = YES;
    _displayReleasesOfDate = YES;
    _showedCalendar = NO;
    _issuesForWeekArray = [NSArray new];
    self = [super init];
    
    if (self == nil) {
        return nil;
    }
    
    return self;
}

// When selecting a date from an issue detail
- (instancetype)initWithDate:(NSDate *)date andShowThisAndNextWeek:(BOOL)segmentedShowBool {
    if(self = [super init]) {
        _selectedWednesday = date;
        _segmentedControl.selectedSegmentIndex = 999;
        _displayReleasesOfDate = YES;
        _showedCalendar = NO;
        _segmentedShowBool = segmentedShowBool;
        _issuesForWeekArray = [NSArray new];
    }
    return self;
}

- (instancetype)initWithIssues:(NSArray *)issues andTitle:(NSString *)title {
    if(self = [super init]) {
        _selectedWednesday = nil;
        _segmentedControl.selectedSegmentIndex = 999;
        _segmentedShowBool = NO;
        _showedCalendar = NO;
        _displayReleasesOfDate = NO;
        _issuesForWeekArray = issues;
        _customNavTitle = title;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _client = [LBXClient new];
    
    _page = 1;
    
    _tableView = [UITableView new];
    _tableView.frame = self.view.frame;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    // A little trick for removing the cell separators
    _tableView.tableFooterView = [UIView new];

    [self.view addSubview:_tableView];
    
    if (_segmentedShowBool) {
        
        NSArray *itemArray = [NSArray arrayWithObjects: @"This Week", @"Next Week", nil];
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
        [_segmentedControl addTarget:self
                              action:@selector(segmentedControlToggle:)
                    forControlEvents:UIControlEventValueChanged];
        
        _toolBar = [UIToolbar new];
        _toolBar.frame = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y, self.view.frame.size.width, self.navigationController.navigationBar.frame.size.height*2);
        
        _toolBar.delegate = self;
        [_toolBar addSubview:self.segmentedControl];
        [self setToolbarItems:@[_segmentedControl]];
        
        [self.view addSubview:_toolBar];
        
        // Autolayout the segmented control
        [_segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
            //        make.bottom.equalTo(_toolBar.mas_centerY).with.offset(self.navigationController.navigationBar.frame.size.height-8);
            //        make.centerX.equalTo(self.view);
            make.edges.equalTo(_toolBar).insets(UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height+8, 16, 8, 16));
        }];
        _segmentedControl.tintColor = [UIColor blackColor];
        UIFont *font = [UIFont segmentedControlFont];
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
                                                               forKey:NSFontAttributeName];
        [_segmentedControl setTitleTextAttributes:attributes
                                         forState:UIControlStateNormal];
        _tableView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height, 0, 0, 0);
        
    }
    
    _tableView.scrollIndicatorInsets = _tableView.contentInset;
   
    _maskLoadingView = [[UIView alloc] initWithFrame:_tableView.frame];
    _maskLoadingView.backgroundColor = [UIColor whiteColor];

    // Add refresh
    if (_displayReleasesOfDate) {
        self.refreshControl = [UIRefreshControl new];
        [self.refreshControl addTarget:self action:@selector(refreshControlAction)
                  forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:self.refreshControl];
    }
    
    
    // If not initialized with initWithDate
    if (!_selectedWednesday && _displayReleasesOfDate) {
        _segmentedControl.selectedSegmentIndex = 0;
        [self setIssuesForWeekArrayWithThisWeekIssues];
    }
    else if (_displayReleasesOfDate) {
        [self setIssuesForWeekArrayWithDate:_selectedWednesday];
    }
    else if ([_customNavTitle isEqualToString:@"Bundles"]) {
        _sectionArray = [NSArray getBundleTableViewSectionArrayForArray:_issuesForWeekArray];
    }
    else {
        _sectionArray = [NSArray getPublisherTableViewSectionArrayForArray:_issuesForWeekArray];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [LBXControllerServices setViewWillAppearWhiteNavigationController:self];
    
    // Calendar button
    // TODO: Move this out of viewWillAppear for performance reasons
    int calendarSize = 20;
    FAKFontAwesome *calendarIcon = [FAKFontAwesome calendarIconWithSize:calendarSize];
    [calendarIcon addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
    UIImage *iconImage = [calendarIcon imageWithSize:CGSizeMake(calendarSize, calendarSize)];
    
    CGRect frameimg = CGRectMake(0, 0, calendarSize, calendarSize);
    UIButton *someButton = [[UIButton alloc] initWithFrame:frameimg];
    [someButton setBackgroundImage:iconImage forState:UIControlStateNormal];
    [someButton addTarget:self action:@selector(showCalendar)
         forControlEvents:UIControlEventTouchUpInside];
    [someButton setShowsTouchWhenHighlighted:YES];
    
    if (_segmentedShowBool) {
        UIBarButtonItem *calendarButton =[[UIBarButtonItem alloc] initWithCustomView:someButton];
        self.navigationItem.rightBarButtonItem = calendarButton;
    }

    self.tableView.rowHeight = ISSUE_TABLE_HEIGHT;
    
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
    
    if (_showedCalendar) {
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
        [self.view addSubview:_maskLoadingView];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [LBXControllerServices setViewDidAppearWhiteNavigationController:self];
    [self setNavTitle];
    
    if ((_segmentedControl.selectedSegmentIndex == -1 || _segmentedControl == nil) && _selectedWednesday) {
        [self fetchDate:_selectedWednesday withPage:@1];
    }
    else if (_segmentedControl.selectedSegmentIndex == 0 && !_showedCalendar) {
        [self refreshControlAction];
        [self fetchThisWeekWithPage:@1];
    }
    else if (_segmentedControl.selectedSegmentIndex == 1 && !_showedCalendar) {
        [self refreshControlAction];
        [self fetchNextWeekWithPage:@1];
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    [self setNavTitle];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.topItem.title = @" ";
    [SVProgressHUD dismiss];
    [_maskLoadingView removeFromSuperview];
}


#pragma mark Private Methods

- (UIBarPosition)positionForBar:(id)bar {
    return UIBarPositionTopAttached;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)setNavTitle
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM dd, yyyy"];
    
    // Custom Nav Title
    if (_customNavTitle) {
        self.navigationController.navigationBar.topItem.title = _customNavTitle;
    }
    // Specific Date
    else if (_displayReleasesOfDate && _selectedWednesday) {
        self.title = [NSString stringWithFormat:@"%@", [formatter stringFromDate:[NSDate getThisWednesdayOfDate:_selectedWednesday]]];
    }
    // This Week
    else if (_segmentedControl.selectedSegmentIndex == 0 && _displayReleasesOfDate) {
        self.navigationController.navigationBar.topItem.title = [formatter stringFromDate:[NSDate getThisWednesdayOfDate:[NSDate getLocalDate]]];
    }
    // Next Week
    else if (_segmentedControl.selectedSegmentIndex == 1 && _displayReleasesOfDate) {
        self.navigationController.navigationBar.topItem.title = [formatter stringFromDate:[NSDate getNextWednesdayOfDate:[NSDate getLocalDate]]];
    }
}

- (IBAction)segmentedControlToggle:(id)sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
    NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM dd, yyyy"];
    
    if (selectedSegment == 0) {
        self.navigationController.navigationBar.topItem.title = [formatter stringFromDate:[NSDate getThisWednesdayOfDate:[NSDate getLocalDate]]];
        _issuesForWeekArray = nil;
        [self setIssuesForWeekArrayWithThisWeekIssues];
        [self.tableView reloadData];
        [self refreshControlAction];
        [self fetchThisWeekWithPage:@1];
    
    }
    else if (selectedSegment == 1) {
        self.navigationController.navigationBar.topItem.title = [formatter stringFromDate:[NSDate getNextWednesdayOfDate:[NSDate getLocalDate]]];
        _issuesForWeekArray = nil;
        [self setIssuesForWeekArrayWithNextWeekIssues];
        [self.tableView reloadData];
        [self refreshControlAction];
        [self fetchNextWeekWithPage:@1];
    }
}

- (void)refreshControlAction
{
    if (_segmentedControl == nil) return;
    else if (_segmentedControl.selectedSegmentIndex == 0) {
        [self fetchThisWeekWithPage:@1];
    }
    else if (_segmentedControl.selectedSegmentIndex == 1) {
        [self fetchNextWeekWithPage:@1];
    }
    else if (_segmentedControl.selectedSegmentIndex == -1) {
        [self fetchDate:_selectedWednesday withPage:@1];
    }
}

- (void)setIssuesForWeekArrayWithThisWeekIssues
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(isParent == 1)"];
    NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"publisher.name" ascending:YES withPredicate:predicate];
    if (allIssuesArray.count > 1) {
        NSDate *localDateTime = [NSDate getLocalDate];
        NSMutableArray *nextWeekArray = [NSMutableArray new];
        for (LBXIssue *issue in allIssuesArray) {
            // Check if the issue is this week
            if ([issue.releaseDate timeIntervalSinceDate:localDateTime] > -3*DAY &&
                [issue.releaseDate timeIntervalSinceDate:localDateTime] <= 4*DAY && issue.releaseDate) {
                [nextWeekArray addObject:issue];
            }
        }
        _issuesForWeekArray = nextWeekArray;
        if ([_customNavTitle isEqualToString:@"Bundles"]) {
            _sectionArray = [NSArray getBundleTableViewSectionArrayForArray:_issuesForWeekArray];
        }
        else _sectionArray = [NSArray getPublisherTableViewSectionArrayForArray:_issuesForWeekArray];
    }
}

- (void)setIssuesForWeekArrayWithNextWeekIssues
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(isParent == 1)"];
    NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"publisher.name" ascending:YES withPredicate:predicate];
    if (allIssuesArray.count > 1) {
        NSDate *localDateTime = [NSDate getLocalDate];
        NSMutableArray *nextWeekArray = [NSMutableArray new];
        for (LBXIssue *issue in allIssuesArray) {
            // Check if the issue is next week
            if ([issue.releaseDate timeIntervalSinceDate:localDateTime] > 5*DAY &&
                [issue.releaseDate timeIntervalSinceDate:localDateTime] <= 12*DAY && issue.releaseDate) {
                [nextWeekArray addObject:issue];
            }
        }
        _issuesForWeekArray = nextWeekArray;
        if ([_customNavTitle isEqualToString:@"Bundles"]) {
            _sectionArray = [NSArray getBundleTableViewSectionArrayForArray:_issuesForWeekArray];
        }
        else _sectionArray = [NSArray getPublisherTableViewSectionArrayForArray:_issuesForWeekArray];
    }
}

- (void)setIssuesForWeekArrayWithDate:(NSDate *)date
{
    int daysToAdd = 1;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(isParent == 1) AND (releaseDate >= %@) AND (releaseDate <= %@)", [date dateByAddingTimeInterval:-60*60*24*daysToAdd], [date dateByAddingTimeInterval:60*60*24*daysToAdd]];
    NSArray *allIssuesArray = [LBXIssue MR_findAllSortedBy:@"publisher.name" ascending:YES withPredicate:predicate];
    _issuesForWeekArray = allIssuesArray;
    if ([_customNavTitle isEqualToString:@"Bundles"]) {
        _sectionArray = [NSArray getBundleTableViewSectionArrayForArray:_issuesForWeekArray];
    }
    else _sectionArray = [NSArray getPublisherTableViewSectionArrayForArray:_issuesForWeekArray];
}

- (void)completeRefresh
{
    if (!_segmentedControl) {
        if (_selectedWednesday) {
            [self setIssuesForWeekArrayWithDate:_selectedWednesday];
        }
        if ([_customNavTitle isEqualToString:@"Bundles"]) {
            _sectionArray = [NSArray getBundleTableViewSectionArrayForArray:_issuesForWeekArray];
        }
        else _sectionArray = [NSArray getPublisherTableViewSectionArrayForArray:_issuesForWeekArray];
    }
    else if (_segmentedControl.selectedSegmentIndex == 0) {
        [self setIssuesForWeekArrayWithThisWeekIssues];
    }
    else if (_segmentedControl.selectedSegmentIndex == 1) {
        [self setIssuesForWeekArrayWithNextWeekIssues];
    }
    else {
        [self setIssuesForWeekArrayWithDate:_selectedWednesday];
    }
    
    if (!_sectionArray.count) {
        // TODO: Display empty view for week
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    });
}

- (void)fetchThisWeekWithPage:(NSNumber *)page
{
        // Fetch this weeks comics
        [self.client fetchThisWeeksComicsWithPage:page completion:^(NSArray *thisWeekArray, RKObjectRequestOperation *response, NSError *error) {
            
            if (!error) {
                if (!thisWeekArray.count) {
                    [self completeRefresh];
                }
                else {
                    _page += 1;
                    [self fetchThisWeekWithPage:[NSNumber numberWithInt:_page]];
                    [self completeRefresh];
                }
            }
            else {
                //[LBXMessageBar displayError:error];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.refreshControl endRefreshing];
                });
            }
        }];
}

- (void)fetchNextWeekWithPage:(NSNumber *)page
{
    // Fetch this weeks comics
    [self.client fetchNextWeeksComicsWithPage:page completion:^(NSArray *nextWeekArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            if (!nextWeekArray.count) {
                [self completeRefresh];
            }
            else {
                _page += 1;
                [self fetchNextWeekWithPage:[NSNumber numberWithInt:_page]];
                [self completeRefresh];
            }
        }
        else {
            //[LBXMessageBar displayError:error];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
            });
        }
    }];
}

- (void)fetchDate:(NSDate *)date withPage:(NSNumber *)page
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate getThisWednesdayOfDate:date]    ];
    
    // Fetch this weeks comics
    [self.client fetchIssuesCollectionWithDate:[dateFormatter dateFromString:dateString] page:page completion:^(NSArray *issuesForDateArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            if (!issuesForDateArray.count) {
                [self completeRefresh];
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Scroll to top
                    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
                    if (_showedCalendar) {
                        [SVProgressHUD dismiss];
                        [_maskLoadingView removeFromSuperview];
                    }
                });
            }
            else {
                _page += 1;
                [self fetchDate:date withPage:[NSNumber numberWithInt:_page]];
            }
        }
        else {
            //[LBXMessageBar displayError:error];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
            });
        }
    }];
}

- (void)showCalendar
{
    [SVProgressHUD dismiss];
    [_maskLoadingView removeFromSuperview];
    // Set the start date of the calendar to Feb 1, 2014
    NSDateComponents *comps = [NSDateComponents new];
    [comps setDay:1];
    [comps setMonth:2];
    [comps setYear:2014];
    NSDate *startDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    // Initialize the calendar view
    _calendarView = [[ESDatePicker alloc] initWithFrame:CGRectMake(20, 50, 280, 300)];
    _calendarView.beginOfWeek = 1;
    [_calendarView setDelegate:self];
    NSDate *now = [NSDate date];
    [_calendarView showDates:startDate:[now dateByAddingTimeInterval:60*60*24*7]];
    [_calendarView setSelectedDate:nil];

    // Initialize the view
    UIViewController *viewController = [UIViewController new];
    viewController.automaticallyAdjustsScrollViewInsets = YES;
    _calendarNavController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [_calendarNavController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    
    viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelCalendar:)];
    
    viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Today" style:UIBarButtonItemStylePlain target:self action:@selector(goToToday:)];
    
    viewController.title = @"Select Week";
    
    _calendarNavController.navigationBar.translucent = NO;
    viewController.view = _calendarView;
    _showedCalendar = YES;
    //_calendarNavController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:_calendarNavController animated:YES completion:nil];
}

- (void)datePicker:(ESDatePicker *)datePicker dateSelected:(NSDate *)date
{
    _issuesForWeekArray = nil;
    _selectedWednesday = [NSDate getThisWednesdayOfDate:date];
    
    [self setNavTitle];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Check if the issue is this week
    if ([_selectedWednesday timeIntervalSinceDate:[NSDate getLocalDate]] > -3*DAY &&
        [_selectedWednesday timeIntervalSinceDate:[NSDate getLocalDate]] <= 4*DAY) {
        [self refreshControlAction];
        _segmentedControl.selectedSegmentIndex = 0;
    }
    
    // Check if the issue is next week
    else if ([_selectedWednesday timeIntervalSinceDate:[NSDate getLocalDate]] > 5*DAY &&
        [_selectedWednesday timeIntervalSinceDate:[NSDate getLocalDate]] <= 12*DAY) {
        [self refreshControlAction];
        _segmentedControl.selectedSegmentIndex = 1;
    }
    else {
        [self fetchDate:_selectedWednesday withPage:@1];
        _segmentedControl.selectedSegmentIndex = -1;
    }
}

- (IBAction)cancelCalendar:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self setNavTitle];
    [SVProgressHUD dismiss];
    [_maskLoadingView removeFromSuperview];
    _showedCalendar = NO;
    
}

- (IBAction)goToToday:(id)sender
{
    [_calendarView setSelectedDate:nil];
    [_calendarView scrollToDate:[NSDate date] animated:YES];
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Background color
    view.tintColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    
    // Text Color and font
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:[UIColor blackColor]];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont titleDetailSubscribersAndIssuesFont]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 18.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (!_sectionArray.count) {
        return nil;
    }
    NSDictionary *dict = [_sectionArray objectAtIndex:section];
    return dict.allKeys.firstObject;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    NSMutableArray *arr = [NSMutableArray new];
    for (NSDictionary *dict in _sectionArray) {
        [arr addObject:dict.allKeys[0]];
    }
    return [arr indexOfObject:title];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!_sectionArray.count) {
        return 0;
    }
    return _sectionArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!_sectionArray.count) {
        return 0;
    }
    NSDictionary *dict = [_sectionArray objectAtIndex:section];
    NSArray *arr = [dict valueForKey:dict.allKeys[0]];
    return [arr count];
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
   
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"WeekTableViewCell";
    
    LBXWeekTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        // Custom cell as explained here: https://medium.com/p/9bee5824e722
        [tableView registerNib:[UINib nibWithNibName:@"LBXWeekTableViewCell" bundle:nil] forCellReuseIdentifier:@"WeekTableViewCell"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"WeekTableViewCell"];
    }
    
    cell.titleLabel.font = [UIFont pullListTitleFont];
    
    if (!_sectionArray.count) {
        return cell;
    }
    NSDictionary *dict = [_sectionArray objectAtIndex:indexPath.section];
    NSArray *array = [dict objectForKey:dict.allKeys[0]];
    LBXIssue *issue = [array objectAtIndex:indexPath.row];
    cell.titleLabel.text = issue.title.name;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(issueNumber == %@) AND (title == %@)", issue.issueNumber, issue.title];
    NSArray *initialFind = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    cell.subtitleLabel.text = [NSString stringWithFormat:@"Issue %@  •  $%.02f  •  %@ Variant Covers", issue.issueNumber, [issue.price floatValue], [NSNumber numberWithFloat:initialFind.count-1]].uppercaseString;
    
    NSString *issueString = (issue.issueNumber) ? [NSString stringWithFormat:@"Issue %@  •  ", issue.issueNumber] : @"";
    
    if (initialFind.count == 1) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@$%.02f", issueString, [issue.price floatValue]].uppercaseString;
    }
    else if (initialFind.count == 2) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@$%.02f  •  %@ Variant Cover", issueString, [issue.price floatValue], [NSNumber numberWithFloat:initialFind.count-1]].uppercaseString;
    }
    
    [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage defaultCoverImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
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
        
        cell.latestIssueImageView.image = [UIImage defaultCoverImage];
    }];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(LBXWeekTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    if (_issuesForWeekArray.count <= indexPath.row) {
        return;
    }
    
    cell.titleLabel.font = [UIFont pullListTitleFont];
    cell.titleLabel.numberOfLines = 2;
    cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    cell.subtitleLabel.font = [UIFont pullListSubtitleFont];
    cell.subtitleLabel.textColor = [UIColor grayColor];
    cell.subtitleLabel.numberOfLines = 2;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    // Setting the background color of the cell.
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Reset the showed calendar bool
    _showedCalendar = NO;
    
    // Disselect and return immediately if selecting an empty cell
    // i.e., one below the last issue
    if (_issuesForWeekArray.count < indexPath.row+1) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    NSDictionary *dict = [_sectionArray objectAtIndex:indexPath.section];
    NSArray *array = [dict objectForKey:dict.allKeys[0]];
    LBXIssue *issue = [array objectAtIndex:indexPath.row];
    [LBXLogging logMessage:[NSString stringWithFormat:@"Selected issue %@", issue]];
    LBXWeekTableViewCell *cell = (LBXWeekTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
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
