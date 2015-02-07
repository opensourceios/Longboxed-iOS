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

- (IBAction)sendTip:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch ([button tag]) {
        case 0:
            [LBXControllerServices showAlertWithTitle:@"Small Tip" andMessage:@"This is a small tip"];
            break;
        case 1:
            [LBXControllerServices showAlertWithTitle:@"Medium Tip" andMessage:@"This is a medium tip"];
            break;
        case 2:
            [LBXControllerServices showAlertWithTitle:@"Big Tip" andMessage:@"This is a big tip"];
            break;
    }
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
                [SVProgressHUD showSuccessWithStatus:@"Logged In!"];
                [LBXLogging logLogin];
            });
        }
        else {
            [LBXLogging logMessage:[NSString stringWithFormat:@"Unsuccessful dev toggle log in %@", [store stringForKey:@"username"]]];
            [LBXControllerServices removeCredentials];
            [LBXDatabaseManager flushBundlesAndPullList];
            
            dispatch_async(dispatch_get_main_queue(),^{
                [SVProgressHUD setForegroundColor: [UIColor blackColor]];
                [SVProgressHUD setBackgroundColor: [UIColor whiteColor]];
                [SVProgressHUD showErrorWithStatus:@"Unsuccessful Log In"];
                [_developmentServerSwitch setOn:NO animated:NO];
                [[RKObjectManager sharedManager] setHTTPClient:[AFHTTPClient clientWithBaseURL:[LBXEndpoints productionURL]]];
                RKObjectManager.sharedManager.HTTPClient.allowsInvalidSSLCertificate = NO;
                [UICKeyChainStore setString:[[LBXEndpoints productionURL] absoluteString] forKey:@"baseURLString"];
            });
        }
        [self.settingsTableView reloadData];
    }];
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
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if (![LBXControllerServices isLoggedIn]) return 2;
            if ([LBXControllerServices isAdmin]) return 2;
            else return 1;
            break;
        case 1:
            return 2;
            break;
        case 4:
            if ([LBXControllerServices isLoggedIn] && [LBXControllerServices isAdmin]) return 4;
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
            return @"Feedback";
            break;
        case 2:
            return @"Tip Jar";
            break;
        case 3:
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
        case 3:
            if (resetCacheToZero) return @"Less than 0.5 MB used";
            else return [NSString stringWithFormat:@"%@ used", [NSString diskUsage]];
            break;
        default:
            return @" ";
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2) {
        static NSString *CellIdentifier = @"TipJarTableViewCell";
        
        LBXTipJarTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            // Custom cell as explained here: https://medium.com/p/9bee5824e722
            [tableView registerNib:[UINib nibWithNibName:@"LBXTipJarTableViewCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell.smallTipButton addTarget:self action:@selector(sendTip:) forControlEvents:UIControlEventTouchUpInside];
        [cell.mediumTipButton addTarget:self action:@selector(sendTip:) forControlEvents:UIControlEventTouchUpInside];
        [cell.largeTipButton addTarget:self action:@selector(sendTip:) forControlEvents:UIControlEventTouchUpInside];
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
    if (indexPath.section == 2) {
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
            textArray = @[@"Send Feedback", @"Please Rate Longboxed"];
            break;
        case 3:
            textArray = @[@"Clear Image & Data Cache"];
            break;
        case 4:
            textArray = @[@"Show Tutorial", @"About", @"Delete Account And All Data", @"Force A Crash"];
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
    if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    if (indexPath.section == 4 && indexPath.row == 2 && [cell.textLabel.text isEqualToString:@"Delete Account And All Data"]) {
        cell.textLabel.textColor = [UIColor redColor];
    }
    if (indexPath.section == 4 && indexPath.row == 3) {
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
            break;
        case 1:
            // Send feedback email
            if (indexPath.row == 0) {
                [self sendEmail];
            }
            // Rate the app
            else if (indexPath.row == 1)  {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/longboxed/id965045339?ls=1&mt=8"]];
            }
            break;
        case 3:
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
        case 4:
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
            else if (indexPath.row == 3) {
                [[Crashlytics sharedInstance] crash];
            }
            break;
        default:
            break;
    }
}


@end
