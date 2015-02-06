//
//  LBXTitleServices.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXTitle.h"
#import "LBXIssue.h"
#import "LBXPullListTableViewCell.h"

#import <Foundation/Foundation.h>
#import "LBXSearchTableViewController.h"

@interface LBXControllerServices : NSObject

+ (void)setPublisherCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title;
+ (void)setPullListCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title;
+ (void)setAddToPullListSearchCell:(LBXPullListTableViewCell *)cell
                         withTitle:(LBXTitle *)title
                       darkenImage:(BOOL)darken;
+ (void)setTitleCell:(LBXPullListTableViewCell *)cell withIssue:(LBXIssue *)issue;

+ (void)setLabel:(UILabel *)textView
      withString:(NSString *)string
            font:(UIFont *)font
  inBoundsOfView:(UIView *)view;
+ (void)setNumberOfLinesWithLabel:(UILabel *)label
                           string:(NSString *)string
                             font:(UIFont *)font;
+ (void)setSearchBar:(UISearchBar *)searchBar withTextColor:(UIColor *)color;

+ (void)copyImageToPasteboard:(UIImage *)image;

+ (void)setViewWillAppearWhiteNavigationController:(UIViewController *)viewController;
+ (void)setViewDidAppearWhiteNavigationController:(UIViewController *)viewController;
+ (void)setViewWillAppearClearNavigationController:(UIViewController *)viewController;
+ (void)setViewDidAppearClearNavigationController:(UIViewController *)viewController;
+ (void)setViewWillDisappearClearNavigationController:(UIViewController *)viewController;

+ (void)setupTransparentNavigationBarForViewController:(UIViewController *)viewController;
+ (void)backButtonClicked:(id)sender;

+ (BOOL)isLoggedIn;
+ (BOOL)isAdmin;
+ (void)removeCredentials;

+ (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message;
+ (void)showCrashAlertWithDelegate:(id)delegate;
+ (void)sendEmailWithMessageBody:(NSString *)messageBody delegate:(id)delegate;

+ (void)setupSearchController:(UISearchController *)searchController withSearchResultsController:(LBXSearchTableViewController *)searchResultsController andDelegate:(id)delegate;

+ (void)showEmptyViewOverTableView:(UITableView *)tableView;

@end
