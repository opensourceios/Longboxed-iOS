//
//  LBXTitleServices.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//
#import <MessageUI/MessageUI.h>
#import <sys/utsname.h>

#import "LBXControllerServices.h"
#import "LBXUser.h"
#import "UIFont+LBXCustomFonts.h"
#import "LBXBackButton.h"

#import "NSDate+DateUtilities.h"
#import "UIImage+LBXCreateImage.h"

#import "NSString+LBXStringUtilities.h"
#import "NSString+StringUtilities.h"
#import "UIColor+LBXCustomColors.h"
#import "SVProgressHUD.h"
#import "PaintCodeImages.h"

#import <UIImageView+AFNetworking.h>
#import <UICKeyChainStore.h>
#import "SIAlertView.h"

@interface LBXControllerServices ()

@end

@implementation LBXControllerServices

// This is for the publisher list
+ (void)setPublisherCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title
{
    cell.titleLabel.text = title.name;
    
    NSString *subtitleString = [NSString getSubtitleStringWithTitle:title uppercase:YES];
    
    if (title.latestIssue != nil) {
        cell.subtitleLabel.text = subtitleString;
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:title.latestIssue.coverImage]] placeholderImage:[UIImage defaultCoverImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            cell.latestIssueImageView.image = [UIImage defaultCoverImage];
        }];
    }
    else if (!title.publisher.name) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"Loading..."] uppercaseString];
        cell.latestIssueImageView.image = [UIImage defaultCoverImage];
    }
    else if (title.latestIssue.title.issueCount == 0) {
        cell.latestIssueImageView.image = [UIImage defaultCoverImage];
        cell.subtitleLabel.text = subtitleString;
    }
    else {
        cell.latestIssueImageView.image = [UIImage defaultCoverImage];
        cell.subtitleLabel.text = subtitleString;
    }
}

// This is for the pull list
+ (void)setPullListCell:(LBXPullListTableViewCell *)cell
              withTitle:(LBXTitle *)title
{
    cell.titleLabel.text = title.name;
    if (title.latestIssue) {
        NSString *subtitleString = [NSString stringWithFormat:@"%@  •  %@", title.latestIssue.publisher.name, [NSString timeStringSinceLastIssueForTitle:title]];
        
        cell.subtitleLabel.text = [subtitleString uppercaseString];
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:title.latestIssue.coverImage]] placeholderImage:[UIImage defaultCoverImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            cell.latestIssueImageView.image = [UIImage defaultCoverImage];
        }];
    }
    else if (!title.publisher.name) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"Loading..."] uppercaseString];
        cell.latestIssueImageView.image = [UIImage defaultCoverImage];
    }
    else if (!title.latestIssue) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage defaultCoverImage];
    }
    else {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage defaultCoverImage];
    }
}

+ (void)darkenCell:(LBXPullListTableViewCell *)cell
{
    // Darken the image
    UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.latestIssueImageView.frame.size.width, cell.latestIssueImageView.frame.size.height*2)];
    [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
    [cell.latestIssueImageView addSubview:overlay];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
}

// This is for the adding to the pull list
+ (void)setAddToPullListSearchCell:(LBXPullListTableViewCell *)cell
                         withTitle:(LBXTitle *)title
                       darkenImage:(BOOL)darken
{
    cell.titleLabel.text = title.name;
    if (title.latestIssue) {
        NSString *subtitleString = [NSString stringWithFormat:@"%@  •  %@", title.latestIssue.publisher.name, [NSString getSubtitleStringWithTitle:title uppercase:YES]];
        
        cell.subtitleLabel.text = [subtitleString uppercaseString];
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:title.latestIssue.coverImage]] placeholderImage:[UIImage defaultCoverImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
            if (darken) [self darkenCell:cell];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            cell.latestIssueImageView.image = [UIImage defaultCoverImage];
            if (darken) [self darkenCell:cell];
        }];
    }
    else if (!title.publisher.name) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"Loading..."] uppercaseString];
        cell.latestIssueImageView.image = [UIImage defaultCoverImage];
    }
    else if (!title.latestIssue) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage defaultCoverImage];
    }
    else {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage defaultCoverImage];
    }
    if (darken) [self darkenCell:cell];
}


// This is for the title view
+ (void)setTitleCell:(LBXPullListTableViewCell *)cell withIssue:(LBXIssue *)issue
{
    NSString *subtitleString = [NSString stringWithFormat:@"%@", [NSString localTimeZoneStringWithDate:issue.releaseDate]];
    
    NSString *modifiedTitleString = [NSString regexOutHTMLJunk:issue.completeTitle];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(issueNumber == %@) AND (title == %@)", issue.issueNumber, issue.title];
    NSArray *initialFind = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@  •  %@ variant covers", subtitleString, [NSNumber numberWithLong:initialFind.count - 1]].uppercaseString;
    if (initialFind.count == 1) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@", subtitleString].uppercaseString;
    }
    else if (initialFind.count == 2) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@  •  %@ variant cover", subtitleString, [NSNumber numberWithLong:initialFind.count - 1]].uppercaseString;
    }
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", modifiedTitleString];
    
    
    // For issues without a release date
    if ([subtitleString isEqualToString:@"(null)"]) {
        cell.subtitleLabel.text = @"Release Date Unknown";
    }
    
    // Get the image from the URL and set it
    [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage defaultCoverImage] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
        [UIView transitionWithView:cell.imageView
                          duration:0.5f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{[cell.latestIssueImageView setImage:image];}
                        completion:NULL];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        cell.latestIssueImageView.image = [UIImage defaultCoverImage];
    }];
}

+ (void)setLabel:(UILabel *)textView
      withString:(NSString *)string
            font:(UIFont *)font
  inBoundsOfView:(UIView *)view
{
    textView.font = font;
    
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = NSLineBreakByWordWrapping;
    textStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName: textStyle};
    CGRect bound = [string boundingRectWithSize:CGSizeMake(view.bounds.size.width-30, view.bounds.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    
    textView.bounds = bound;
    textView.text = string;
    CGFloat width = [string sizeWithAttributes: @{NSFontAttributeName:font}].width;
    textView.numberOfLines = (width > textView.frame.size.width) ? 2 : 1;
    [textView sizeToFit];
}

+ (void)setNumberOfLinesWithLabel:(UILabel *)label
                           string:(NSString *)string
                             font:(UIFont *)font
{
    CGFloat width = [string sizeWithAttributes: @{NSFontAttributeName:font}].width;
    label.numberOfLines = (width > label.frame.size.width) ? 2 : 1;
    label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, label.frame.size.width, label.numberOfLines * 2);
    [label sizeToFit];
}

+ (void)setSearchBar:(UISearchBar *)searchBar withTextColor:(UIColor *)color
{
    // Set the placeholder text and magnifying glass color
    UIImage *image = [PaintCodeImages imageOfMagnifyingGlassWithColor:color width:24];
    [searchBar setImage:image forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:color];
    
    // SearchBar cursor color
    searchBar.tintColor = color;
}

+ (void)copyImageToPasteboard:(UIImage *)image
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setImage:image];
    [SVProgressHUD showSuccessWithStatus:@"Copied" maskType:SVProgressHUDMaskTypeBlack];
}

+ (void)setViewWillAppearWhiteNavigationController:(UIViewController *)viewController
{
    viewController.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [viewController.navigationController.navigationBar.backItem.backBarButtonItem setImageInsets:UIEdgeInsetsMake(40, 40, -40, 40)];
    [viewController.navigationController.navigationBar setBackIndicatorImage:
     [UIImage imageNamed:@"arrow"]];
    [viewController.navigationController.navigationBar setBackIndicatorTransitionMaskImage:
     [UIImage imageNamed:@"arrow"]];
    viewController.navigationController.navigationBar.backItem.title = @" ";
    viewController.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    
    // Make the nav par translucent again
    if (viewController.isBeingPresented || viewController.isMovingToParentViewController) {
        viewController.navigationController.navigationBar.translucent = YES;
        viewController.navigationController.view.backgroundColor = [UIColor whiteColor];
        [viewController.navigationController.navigationBar setBackgroundImage:nil
                                                                forBarMetrics:UIBarMetricsDefault];
    }
}

+ (void)setViewDidAppearWhiteNavigationController:(UIViewController *)viewController
{
    [viewController.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    
    viewController.navigationController.navigationBar.translucent = YES;
    viewController.navigationController.view.backgroundColor = [UIColor whiteColor];
    viewController.navigationController.navigationBar.topItem.title = @" ";
    
   // viewController.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    viewController.navigationController.navigationBar.shadowImage = nil;
    
    [viewController.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0], NSFontAttributeName : [UIFont navTitleFont]}];
}

+ (void)setViewWillAppearClearNavigationController:(UIViewController *)viewController
{
    [viewController.navigationController setNavigationBarHidden:YES animated:YES];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

+ (void)setViewDidAppearClearNavigationController:(UIViewController *)viewController
{
    [viewController.navigationController setNavigationBarHidden:YES animated:YES];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

+ (void)setViewWillDisappearClearNavigationController:(UIViewController *)viewController
{
    BOOL keepNavBarTransparent = NO;
    UIViewController *previousVC = [viewController.navigationController.viewControllers objectAtIndex:viewController.navigationController.viewControllers.count-1];
    
    for (UIView *view in [previousVC.view subviews]) {
        if ([view isKindOfClass:[UINavigationBar class]]) {
            keepNavBarTransparent = YES;
        }
    }
    
    if (keepNavBarTransparent) [viewController.navigationController setNavigationBarHidden:YES animated:YES]; else [viewController.navigationController setNavigationBarHidden:NO animated:YES];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

// Custom transparent navigation bar with back button that pops correctly
// References: http://stackoverflow.com/questions/19918734/transitioning-between-transparent-navigation-bar-to-translucent
// http://keighl.com/post/ios7-interactive-pop-gesture-custom-back-button/
+ (void)setupTransparentNavigationBarForViewController:(UIViewController *)viewController
{
    UINavigationBar *transparentNavBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height, viewController.navigationController.navigationBar.frame.size.width, viewController.navigationController.navigationBar.frame.size.height)];
    [transparentNavBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    transparentNavBar.backIndicatorImage = [UIImage imageNamed:@"arrow"];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:@" "];
    LBXBackButton *button = [[LBXBackButton alloc] initWithFrame:CGRectMake(40, 40, -40, 40)];
    button.parentViewController = viewController;
    
    [button setImage:[UIImage imageNamed:@"arrow.png"] forState:UIControlStateNormal];
    //#pragma GCC diagnostic ignored "-Wundeclared-selector" // Ignore the warning about the following selector method
    [button addTarget:[LBXControllerServices class] action:@selector(backButtonClicked:)
     forControlEvents:UIControlEventTouchUpInside];
    button.tintColor = [UIColor whiteColor];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                       target:nil action:nil];
    negativeSpacer.width = -16;// it was -6 in iOS 6
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc]
                                   initWithCustomView:button];
    [transparentNavBar setShadowImage:[UIImage new]];
    
    navigationItem.leftBarButtonItems = @[negativeSpacer, buttonItem];
    navigationItem.leftBarButtonItem.tintColor = [UIColor whiteColor];
    
    [transparentNavBar pushNavigationItem:navigationItem animated:NO];
    
    viewController.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    
    [viewController.view addSubview:transparentNavBar];
}

+ (void)backButtonClicked:(id)sender
{
    [((LBXBackButton *)sender).parentViewController.navigationController popViewControllerAnimated:YES];
}

+ (BOOL)isLoggedIn
{
    if ([UICKeyChainStore stringForKey:@"id"]) return YES; else return NO;
}

+ (BOOL)isAdmin
{
    if ([self isLoggedIn]) {
        NSArray *users = [LBXUser MR_findAll];
        if (users.count) {
            for (LBXUser *user in users) {
                if ([user.roles containsObject:@"admin"] && [user.userID intValue] == [[UICKeyChainStore stringForKey:@"id"] intValue]) return YES;
            }
        };
    }
    return NO;
}

+ (void)removeCredentials
{
    [UICKeyChainStore removeItemForKey:@"username"];
    [UICKeyChainStore removeItemForKey:@"password"];
    [UICKeyChainStore removeItemForKey:@"id"];
}

+ (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    SIAlertView *alert = [[SIAlertView alloc] initWithTitle:title andMessage:message];
    [alert addButtonWithTitle:@"OK"
                         type:SIAlertViewButtonTypeCancel
                      handler:nil];
    alert.titleFont = [UIFont alertViewTitleFont];
    alert.messageFont = [UIFont alertViewMessageFont];
    alert.buttonFont = [UIFont alertViewButtonFont];
    alert.transitionStyle = SIAlertViewTransitionStyleDropDown;
    [alert show];
}

// NOTE: the delegate view controller being passed must conform to  <MFMailComposeViewControllerDelegate> and implement the below method to dismiss the mail view controller:
// - (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
//      [_dashboardViewController dismissViewControllerAnimated:YES completion:nil];
// }
+ (void)showCrashAlertWithDelegate:(id)delegate {
    SIAlertView *alert = [[SIAlertView alloc] initWithTitle:@"Oh No! Longboxed Crashed!" andMessage:@"It looks like Longboxed crashed last time. We're very sorry. Would you mind sending a quick email to help us fix the issue?"];
    [alert addButtonWithTitle:@"No Thanks"
                         type:SIAlertViewButtonTypeDefault
                      handler:nil];
    [alert addButtonWithTitle:@"Sure!"
                             type:SIAlertViewButtonTypeCancel
                          handler:^(SIAlertView *alert) {
                              NSString *feedbackString = @"<b>Steps to reproduce the problem:</b><br><br><br><br><br><br><br><b>Additional info that might help us fix the issue:</b>";
                              [self sendEmailWithMessageBody:[NSString stringWithFormat:@"%@%@", feedbackString, [NSString feedbackEmailTemplate]] delegate:delegate];
                          }];
    alert.titleFont = [UIFont alertViewTitleFont];
    alert.messageFont = [UIFont alertViewMessageFontForCrash];
    alert.buttonFont = [UIFont alertViewButtonFont];
    alert.transitionStyle = SIAlertViewTransitionStyleDropDown;
    [alert show];
}

// NOTE: the delegate view controller being passed must conform to  <MFMailComposeViewControllerDelegate> and implement the below method to dismiss the mail view controller:
// - (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
//      [_dashboardViewController dismissViewControllerAnimated:YES completion:nil];
// }
+ (void)sendEmailWithMessageBody:(NSString *)messageBody delegate:(id)delegate
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
        [composeViewController setMailComposeDelegate:delegate];
        [composeViewController setToRecipients:@[@"contact@longboxed.com"]];
        [composeViewController setSubject:@"Longboxed for iOS"];
        
        struct utsname systemInfo;
        uname(&systemInfo);
        [composeViewController setMessageBody:messageBody isHTML:YES];
        [delegate presentViewController:composeViewController animated:YES completion:nil];
    }
    else {
        [SVProgressHUD setForegroundColor: [UIColor blackColor]];
        [SVProgressHUD setBackgroundColor: [UIColor whiteColor]];
        [SVProgressHUD showErrorWithStatus:@"Your iOS email is not configured. contact@longboxed.com" maskType:SVProgressHUDMaskTypeBlack];
    }
}

+ (void)setupSearchController:(UISearchController *)searchController withSearchResultsController:(LBXSearchTableViewController *)searchResultsController andDelegate:(id)delegate
{
    searchController.searchResultsUpdater = searchResultsController;
    searchResultsController.tableView.delegate = delegate;
    searchResultsController.tableView.dataSource = delegate;
    searchController.dimsBackgroundDuringPresentation = YES;
    searchController.delegate = delegate;
    searchController.searchBar.delegate = delegate;
    ((UIViewController *)delegate).definesPresentationContext = YES;
    searchController.searchBar.barStyle = UISearchBarStyleMinimal;
    searchController.searchBar.backgroundImage = [[UIImage alloc] init];
    searchController.searchBar.backgroundColor = [UIColor clearColor];
    searchController.searchBar.placeholder = @"Search Comics";
    searchController.hidesNavigationBarDuringPresentation = NO;
    UIImage *image = [PaintCodeImages imageOfMagnifyingGlassWithColor:[UIColor whiteColor] width:24];
    [searchController.searchBar setImage:image forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    searchController.searchBar.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44);
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor blackColor]];
}

@end
