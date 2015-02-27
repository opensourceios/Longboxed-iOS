//
//  LBXAboutTableViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 1/31/15.
//  Copyright (c) 2015 Longboxed. All rights reserved.
//

#import "LBXAboutTableViewController.h"
#import "UIFont+LBXCustomFonts.h"

#import <UICKeyChainStore.h>
#import <SVProgressHUD.h>
#import <WebKit/WebKit.h>
#import "LBXControllerServices.h"

@interface LBXAboutTableViewController ()

@property (nonatomic, strong) NSDictionary *openSourceDict;
@property (nonatomic, strong) NSArray *openSourceKeys;
@property (nonatomic, strong) NSURL *selectedURL;

@end

@implementation LBXAboutTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self)
    {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"About";
    
    // Load the open source credits json file
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"OpenSource.json"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        _openSourceDict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path]
                                                          options:kNilOptions
                                                            error:nil];
        _openSourceKeys = [_openSourceDict.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark UITableView Methods

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Text Color and font
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:[UIColor blackColor]];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont settingsSectionHeaderFont]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_openSourceKeys.count) return 4;
    else return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 3;
            break;
        case 1:
            return 2;
            break;
        case 2:
            return 2;
            break;
        case 3:
            return _openSourceKeys.count;
            break;
        default:
            return 1;
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"APP INFO";
            break;
        case 1:
            return @"CREATORS";
            break;
        case 2:
            return @"SPECIAL THANKS";
            break;
        case 3:
            return @"OPEN SOURCE";
            break;
        default:
            return @"";
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView
                             dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleValue1
                reuseIdentifier:CellIdentifier];
    }
    return [self setCellViews:cell atIndexPath:indexPath];
}

- (UITableViewCell *)setCellViews:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    NSArray *textArray = [NSArray new];
    switch (indexPath.section) {
        case 0:
            textArray = @[@"Version", @"Build", @"Privacy Policy"];
            break;
        case 1:
            textArray = @[@"Jay Hickey", @"Tim Bueno"];
            break;
        case 2:
            textArray = @[@"Eric Bueno", @"Michael Bjelovuk"];
            break;
        case 3:
            textArray = _openSourceKeys;
            break;
    }
    
    if (indexPath.section == 0 && indexPath.row < 2) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = (indexPath.row == 0) ? version : buildNumber;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = @"";
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    cell.accessoryView = nil;
    
    cell.textLabel.text = [textArray objectAtIndex:indexPath.row];
    cell.textLabel.textColor = [UIColor blackColor];
    
    cell.detailTextLabel.font = [UIFont settingsTableViewFont];
    cell.textLabel.font = [UIFont settingsTableViewFont];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *urlString = [NSString new];
    NSString *titleString = [NSString new];
    
    // Privacy policy
    if (indexPath.section == 0 && indexPath.row == 2) {
        titleString = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        urlString = @"https://longboxed.com/privacy";
    }
    // Creators
    else if (indexPath.section == 1) {
        titleString = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        urlString = (indexPath.row == 0) ? @"http://jayhickey.com" : @"http://twitter.com/timbueno";
    }
    // Special Thanks
    else if (indexPath.section == 2) {
        titleString = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        urlString = (indexPath.row == 0) ? @"http://twitter.com/buen0_" : @"http://twitter.com/michaelbjelovuk";
    }
    // Open Source
    else if (indexPath.section == 3) {
        titleString = _openSourceKeys[indexPath.row];
        urlString = _openSourceDict[_openSourceKeys[indexPath.row]];
    }
    
    if (indexPath.section != 0 || indexPath.row == 2) {
        UIViewController *vc = [UIViewController new];
        WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.frame];
        UIView *view = [[UIView alloc] initWithFrame:self.view.frame];
        view.backgroundColor = [UIColor whiteColor];
        vc.view = view;
        [view addSubview:webView];
        vc.title = titleString;
        
        UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showShareSheet)];
        
        vc.navigationItem.rightBarButtonItem = actionButton;
        
        _selectedURL = [NSURL URLWithString:urlString];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:_selectedURL cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
        [webView loadRequest: request];

        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)showShareSheet {
    [LBXControllerServices showShareSheetWithArrayOfInfo:@[[_selectedURL absoluteString]]];
}

@end
