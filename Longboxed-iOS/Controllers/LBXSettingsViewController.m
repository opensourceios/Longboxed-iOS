//
//  LBXLoginViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/30/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXSettingsViewController.h"
#import "LBXDashboardViewController.h"
#import "LBXLoginViewController.h"
#import "LBXDeleteAccountViewController.h"
#import "LBXSignupViewController.h"
#import "LBXDatabaseManager.h"
#import "LBXControllerServices.h"
#import "LBXClient.h"
#import "LBXEndpoints.h"
#import "LBXLogging.h"
#import "LBXUser.h"

#import "RestKit/RestKit.h"

#import "UIFont+customFonts.h"
#import <UICKeyChainStore.h>
#import <SVProgressHUD.h>
#import <JGActionSheet.h>

@interface LBXSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UISwitch *developmentServerSwitch;
@property (nonatomic, strong) IBOutlet UITableView* settingsTableView;
@property (nonatomic) LBXClient *client;

@end

@implementation LBXSettingsViewController

bool resetCacheToZero;
UICKeyChainStore *store;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        resetCacheToZero = NO;
        store = [UICKeyChainStore keyChainStore];
        _client = [[LBXClient alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILabel *label = [UILabel new];
    label.text = @"Settings";
    label.font = [UIFont navTitleFont];
    [label sizeToFit];
    
    self.navigationItem.titleView = label;
    
    _developmentServerSwitch = [UISwitch new];
    [_developmentServerSwitch setOnTintColor:[UIColor blackColor]];
    
    [_developmentServerSwitch addTarget:self
                                 action:@selector(stateChanged:)
                       forControlEvents:UIControlEventValueChanged];
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
    self.navigationItem.rightBarButtonItem = actionButton;
    
    [LBXControllerServices setViewDidAppearWhiteNavigationController:self];
    [_developmentServerSwitch setOn:YES animated:NO];
    RKResponseDescriptor *responseDescriptor = [RKObjectManager sharedManager].responseDescriptors[0];
    if ([[responseDescriptor.baseURL absoluteString] isEqualToString:[[LBXEndpoints productionURL] absoluteString]]) {
        [_developmentServerSwitch setOn:NO animated:NO];
    }
    [self.navigationItem setHidesBackButton:YES animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [LBXControllerServices setViewWillAppearWhiteNavigationController:self];
    NSIndexPath *tableSelection = [self.settingsTableView indexPathForSelectedRow];
    [self.settingsTableView deselectRowAtIndexPath:tableSelection animated:YES];
}

- (void)viewWillLayoutSubviews
{
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
    _developmentServerSwitch.hidden = ([LBXControllerServices isAdmin]) ? NO : YES;
    [self.settingsTableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.navigationBar.topItem.title = @"Settings";
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark Private Methods

- (void)donePressed
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"reloadDashboardTableView"
     object:self];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

// Development Server UISwitch
- (void)stateChanged:(UISwitch *)switchState
{
    // Use staging server
    if ([switchState isOn]) {
        // Set the response descriptors and the shared manager to the new base URL
        for (RKResponseDescriptor *descriptor in [RKObjectManager sharedManager].responseDescriptors) {
            descriptor.baseURL = [LBXEndpoints stagingURL];
        }
        [[RKObjectManager sharedManager] setHTTPClient:[AFHTTPClient clientWithBaseURL:[LBXEndpoints stagingURL]]];
        RKObjectManager.sharedManager.HTTPClient.allowsInvalidSSLCertificate = YES;
        [UICKeyChainStore setString:[[LBXEndpoints stagingURL] absoluteString] forKey:@"baseURLString"];
        [store synchronize];
        
        [self login];
    }
    // Use production server
    else {
        // Set the response descriptors and the shared manager to the new base URL
        for (RKResponseDescriptor *descriptor in [RKObjectManager sharedManager].responseDescriptors) {
            descriptor.baseURL = [LBXEndpoints productionURL];
        }
        [[RKObjectManager sharedManager] setHTTPClient:[AFHTTPClient clientWithBaseURL:[LBXEndpoints productionURL]]];
        RKObjectManager.sharedManager.HTTPClient.allowsInvalidSSLCertificate = NO;
        [UICKeyChainStore setString:[[LBXEndpoints productionURL] absoluteString] forKey:@"baseURLString"];
        [store synchronize];
        
        [self login];
    }
}

- (void)login
{
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    [LBXDatabaseManager flushBundlesAndPullList];
    [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
        if (response.HTTPRequestOperation.response.statusCode == 200) {
            dispatch_async(dispatch_get_main_queue(),^{
                [LBXLogging logMessage:[NSString stringWithFormat:@"Successful dev toggle log in %@", [store stringForKey:@"username"]]];
                [store synchronize];
                [SVProgressHUD showSuccessWithStatus:@"Logged In!"];
                [LBXLogging logLogin];
            });
        }
        else {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Unsuccessful dev toggle log in %@", [store stringForKey:@"username"]]];
            [LBXControllerServices removeCredentials];
            [LBXDatabaseManager flushBundlesAndPullList];
            
            dispatch_async(dispatch_get_main_queue(),^{
                [SVProgressHUD showErrorWithStatus:@"Unsuccessful Log In"];
            });
        }
        [self.settingsTableView reloadData];
    }];
}

# pragma mark UITableView Methods

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Text Color and font
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:[UIColor blackColor]];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont settingsSectionHeaderFont]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && [LBXControllerServices isAdmin]) return 2;
    switch (section) {
        case 0:
            if (![LBXControllerServices isLoggedIn]) return 2;
            if ([LBXControllerServices isAdmin]) return 2;
            else return 1;
            break;
        case 1:
            return 2;
            break;
        case 3:
            if ([LBXControllerServices isLoggedIn]) return 2;
            else return 1;
            break;
        default:
            return 1;
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Account";
            break;
        case 1:
            return @"Feedback";
            break;
        case 2:
            return @"Storage";
            break;
        default:
            return @" ";
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case 1:
            return @" ";
            break;
        case 2:
            if (resetCacheToZero) return @"Less than 0.5 MB";
            else return [NSString stringWithFormat:@"%@ used", [LBXControllerServices diskUsage]];
            break;
        default:
            return @" ";
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView
                             dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleValue1
                reuseIdentifier:CellIdentifier];
    }
    
    NSString *logInString = ([LBXControllerServices isLoggedIn]) ? @"Email" : @"Sign Up";
    NSString *devServerOrLogInString = ([LBXControllerServices isLoggedIn]) ? @"Use Development Server" : @"Log In";
    
    
    NSArray *textArray = [NSArray new];
    switch (indexPath.section) {
        case 0:
            textArray = @[logInString, devServerOrLogInString];
            break;
        case 1:
            textArray = @[@"Send Feedback", @"Please Rate Longboxed"];
            break;
        case 2:
            textArray = @[@"Clear Image & Data Cache"];
            break;
        case 3:
            textArray = ([LBXControllerServices isLoggedIn]) ? @[@"About", @"Delete Account And All Data"] : @[@"About"];
            break;
    }
    
    cell.accessoryView = nil; // Sets any views that previously had UISwitches back to normal
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [textArray objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = @"";
    
    // Account Section
    if (indexPath.section == 0) {
        if (indexPath.row == 1 && [LBXControllerServices isLoggedIn]) {
            cell.accessoryView = _developmentServerSwitch;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else if (indexPath.row == 0 && [LBXControllerServices isLoggedIn]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.detailTextLabel.text = [store stringForKey:@"username"];
        }

    }
    
    // Storage Section
    if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    if (indexPath.section == 3 && indexPath.row == 1) {
        cell.textLabel.textColor = [UIColor redColor];
    }
    
    cell.detailTextLabel.font = [UIFont settingsTableViewFont];
    cell.textLabel.font = [UIFont settingsTableViewFont];
    
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                // User is logged in - show email and stuff
                if ([LBXControllerServices isLoggedIn]) {
                    JGActionSheetSection *section1 = [JGActionSheetSection sectionWithTitle:nil message:nil buttonTitles:@[@"Log Out"] buttonStyle:JGActionSheetButtonStyleRed];
                    JGActionSheetSection *cancelSection = [JGActionSheetSection sectionWithTitle:nil message:nil buttonTitles:@[@"Cancel"] buttonStyle:JGActionSheetButtonStyleCancel];
                    
                    NSArray *sections = @[section1, cancelSection];
                    
                    JGActionSheet *sheet = [JGActionSheet actionSheetWithSections:sections];
                    
                    [sheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                        switch (indexPath.section) {
                            case 0:
                                switch (indexPath.row) {
                                    case 0:
                                        [LBXLogging logLogout];
                                        [LBXControllerServices removeCredentials];
                                        [LBXDatabaseManager flushBundlesAndPullList];
                                        [SVProgressHUD showSuccessWithStatus:@"Logged Out"];
                                        [self.settingsTableView deselectRowAtIndexPath:indexPath animated:YES];
                                        [self.settingsTableView reloadData];
                                        break;
                                }
                            case 1:
                                [self.settingsTableView deselectRowAtIndexPath:indexPath animated:YES];
                                break;
                        }
                        [sheet dismissAnimated:YES];
                    }];
                    
                    [sheet showInView:self.view animated:YES];
                    
                }
                // User is not logged in - show sign up
                else {
                    LBXSignupViewController *signupViewController = [LBXSignupViewController new];
                    [self.navigationController pushViewController:signupViewController animated:YES];
                }
            }
            else if (indexPath.row == 1 && ![LBXControllerServices isLoggedIn]) {
                LBXLoginViewController *loginViewController = [LBXLoginViewController new];
                [self.navigationController pushViewController:loginViewController animated:YES];
            }
            break;
        case 2:
            // Cleared cache
            if (indexPath.row == 0) {
                [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
                [LBXLogging logMessage:[NSString stringWithFormat:@"Clearing cache"]];
                [LBXDatabaseManager flushDatabase];
                if ([LBXControllerServices isLoggedIn]) {
                    [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                           [SVProgressHUD showSuccessWithStatus:@"Cache Cleared"];
                            [self.settingsTableView reloadData];
                        });
                    }];
                }
                [self.settingsTableView deselectRowAtIndexPath:indexPath animated:YES];
                resetCacheToZero = YES;
            }
            break;
        case 3:
            // Delete Account
            if (indexPath.row == 1) {
                LBXDeleteAccountViewController *deleteViewController = [LBXDeleteAccountViewController new];
                [self.navigationController pushViewController:deleteViewController animated:YES];
            }
            break;
        default:
            break;
    }
}


@end
