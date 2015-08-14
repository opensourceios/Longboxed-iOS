//
//  LBXLoginViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/30/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//
#import <MessageUI/MessageUI.h>
#import <sys/utsname.h>

#import "LBXSettingsViewController.h"
#import "LBXDashboardViewController.h"
#import "LBXLoginViewController.h"
#import "LBXDeleteAccountViewController.h"
#import "LBXTipJarTableViewCell.h"
#import "LBXPullListTableViewCell.h"
#import "LBXAboutTableViewController.h"
#import "LBXSignupViewController.h"
#import "LBXDatabaseManager.h"
#import "LBXControllerServices.h"
#import "LBXClient.h"
#import "LBXEndpoints.h"
#import "LBXLogging.h"
#import "LBXUser.h"
#import "LBXAppDelegate.h"
#import "LBXCustomURLViewController.h"
#import "LBXNotificationsViewController.h"

#import "UIFont+LBXCustomFonts.h"
#import "NSString+StringUtilities.h"

#import "RestKit/RestKit.h"
#import <UICKeyChainStore.h>
#import <SVProgressHUD.h>
#import <JGActionSheet.h>
#import <OnboardingContentViewController.h>
#import <WebKit/WebKit.h>

#import <Crashlytics/Crashlytics.h>

@interface LBXSettingsViewController () <UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate>

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
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
    self.navigationItem.rightBarButtonItem = actionButton;
    
    [LBXControllerServices setViewDidAppearWhiteNavigationController:self];
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
    if (!self.isBeingDismissed) {
        [self.settingsTableView reloadData];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.navigationController.navigationBar.topItem.title = @"Settings";
    [self.settingsTableView flashScrollIndicators];
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

- (void)sendEmail
{
    [LBXControllerServices sendEmailWithMessageBody:[NSString feedbackEmailTemplate] delegate:self];
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if (![LBXControllerServices isLoggedIn]) return 2;
            if ([LBXControllerServices isAdmin]) return 2;
            else return 1;
            break;
        case 1:
            return ([LBXControllerServices isLoggedIn]) ? 1 : 0;
            break;
        case 2:
            return 2;
            break;
        case 5:
            if ([LBXControllerServices isLoggedIn] && [LBXControllerServices isAdmin]) return 3;
            if ([LBXControllerServices isLoggedIn]) return 3;
            else return 2;
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
            return ([LBXControllerServices isLoggedIn]) ? @"Notifications" : nil;
            break;
        case 2:
            return @"Feedback";
            break;
        case 3:
            return @"Tip Jar";
            break;
        case 4:
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
            return ([LBXControllerServices isLoggedIn]) ? @" " : nil;
            break;
        case 4:
            if (resetCacheToZero) return @"Less than 0.5 MB used";
            else return [NSString stringWithFormat:@"%@ used", [NSString diskUsage]];
            break;
        default:
            return @" ";
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 3) {
        static NSString *CellIdentifier = @"TipJarTableViewCell";
        
        LBXTipJarTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            // Custom cell as explained here: https://medium.com/p/9bee5824e722
            [tableView registerNib:[UINib nibWithNibName:@"LBXTipJarTableViewCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
        
    }
    else {
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
}

- (UITableViewCell *)setCellViews:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 3) {
        return cell;
    }
    NSString *logInString = ([LBXControllerServices isLoggedIn]) ? @"Email" : @"Sign Up";
    NSString *devServerOrLogInString = ([LBXControllerServices isLoggedIn]) ? @"Use Development Server" : @"Log In";
    NSArray *textArray = [NSArray new];
    switch (indexPath.section) {
        case 0:
            textArray = @[logInString, devServerOrLogInString];
            break;
        case 1:
            textArray = @[@"Bundle Release Notifications"];
            break;
        case 2:
            textArray = @[@"Send Feedback", @"Please Rate Longboxed"];
            break;
        case 4:
            textArray = @[@"Clear Image & Data Cache"];
            break;
        case 5:
            textArray = @[@"Show Tutorial", @"About", @"Delete Account And All Data"];
            break;
    }
    
    cell.accessoryView = nil; // Sets any views that previously had UISwitches back to normal
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [textArray objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = @"";
    cell.textLabel.textColor = [UIColor blackColor];
    
    // Account Section
    if (indexPath.section == 0) {
        if (indexPath.row == 0 && [LBXControllerServices isLoggedIn]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.detailTextLabel.text = [store stringForKey:@"username"];
        }
    }
    
    if (indexPath.section == 1 && ![LBXControllerServices isLoggedIn]) {
        cell.hidden = YES;
    }
    
    // Storage Section
    if (indexPath.section == 4) {
        if (indexPath.row == 0) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    if (indexPath.section == 5 && indexPath.row == 2 && [cell.textLabel.text isEqualToString:@"Delete Account And All Data"]) {
        cell.textLabel.textColor = [UIColor redColor];
    }
    if (indexPath.section == 5 && indexPath.row == 3) {
        cell.accessoryType = UITableViewCellAccessoryNone;
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
            // Development server
            else if (indexPath.row == 1 && [LBXControllerServices isAdmin]) {
                LBXCustomURLViewController *urlVC = [LBXCustomURLViewController new];
                [self.navigationController pushViewController:urlVC animated:YES];
            }
            break;
        case 1:
            if (indexPath.row == 0) {
                LBXNotificationsViewController *notificationsVC = [LBXNotificationsViewController new];
                [self.navigationController pushViewController:notificationsVC animated:YES];
            }
            break;
        case 2:
            // Send feedback email
            if (indexPath.row == 0) {
                [self sendEmail];
            }
            // Rate the app
            else if (indexPath.row == 1)  {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/longboxed-comic-tracker/id965045339?ls=1&mt=8"]];
                [self.settingsTableView deselectRowAtIndexPath:indexPath animated:YES];
            }
            break;
        case 4:
            // Cleared cache
            if (indexPath.row == 0) {
                [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
                [LBXLogging logMessage:[NSString stringWithFormat:@"Clearing cache"]];
                [LBXDatabaseManager flushDatabase];
                if ([LBXControllerServices isLoggedIn]) {
                    [self.client fetchLogInWithCompletion:^(LBXUser *user, RKObjectRequestOperation *response, NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (!error) {
                               [SVProgressHUD showSuccessWithStatus:@"Cache Cleared"];
                                //[self.settingsTableView reloadData];
                                [tableView footerViewForSection:indexPath.section].textLabel.text = @"Less than 0.5 MB used";
                                [tableView footerViewForSection:indexPath.section].textLabel.numberOfLines = 1;
                                [[tableView footerViewForSection:indexPath.section].textLabel sizeToFit];
                                [[tableView footerViewForSection:indexPath.section].textLabel updateConstraintsIfNeeded];
                            }
                            else {
                                [LBXControllerServices showAlertWithTitle:@"Error" andMessage:@"Unable to clear cache"];
                                [SVProgressHUD dismiss];
                            }
                        });
                    }];
                }
                else {
                    [SVProgressHUD showSuccessWithStatus:@"Cache Cleared"];
                    //[self.settingsTableView reloadData];
                    [tableView footerViewForSection:indexPath.section].textLabel.text = @"Less than 0.5 MB used";
                    [tableView footerViewForSection:indexPath.section].textLabel.numberOfLines = 1;
                    [[tableView footerViewForSection:indexPath.section].textLabel sizeToFit];
                    [[tableView footerViewForSection:indexPath.section].textLabel updateConstraintsIfNeeded];
                }
                [self.settingsTableView deselectRowAtIndexPath:indexPath animated:YES];
                resetCacheToZero = YES;
                
            }
            break;
        case 5:
            if (indexPath.row == 0) {
                OnboardingViewController *onboardingVC = [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] generateOnboardingVC];
                [(LBXAppDelegate *)[[UIApplication sharedApplication] delegate] externallySetRootViewController:onboardingVC];
            }
            else if (indexPath.row == 1) {
                LBXAboutTableViewController *aboutController = [LBXAboutTableViewController new];
                [self.navigationController pushViewController:aboutController animated:YES];   
            }
            // Delete Account
            else if (indexPath.row == 2) {
                LBXDeleteAccountViewController *deleteViewController = [LBXDeleteAccountViewController new];
                [self.navigationController pushViewController:deleteViewController animated:YES];
            }
            break;
        default:
            break;
    }
}


@end
