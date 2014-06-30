//
//  NavigationViewController.m
//  REMenuExample
//
//  Created by Roman Efimov on 4/18/13.
//  Copyright (c) 2013 Roman Efimov. All rights reserved.
//
//  Sample icons from http://icons8.com/download-free-icons-for-ios-tab-bar
//

#import "LBXNavigationViewController.h"

@interface LBXNavigationViewController ()

@property (strong, readwrite, nonatomic) REMenu *menu;

@end

@implementation LBXNavigationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    __typeof (self) __weak weakSelf = self;
    REMenuItem *homeItem = [[REMenuItem alloc] initWithTitle:@"Home"
                                                       image:[UIImage imageNamed:@"Icon_Home"]
                                            highlightedImage:nil
                                                      action:^(REMenuItem *item) {
                                                          NSLog(@"Item: %@", item);
//                                                          LBXThisWeekCollectionViewController *controller = [[LBXThisWeekCollectionViewController alloc] init];
//                                                          [weakSelf setViewControllers:@[controller] animated:NO];
                                                      }];
    
    REMenuItem *activityItem = [[REMenuItem alloc] initWithTitle:@"Pull List"
                                                           image:[UIImage imageNamed:@"Icon_Activity"]
                                                highlightedImage:nil
                                                          action:^(REMenuItem *item) {
                                                              NSLog(@"Item: %@", item);
//                                                              LBXThisWeekCollectionViewController *controller = [[LBXThisWeekCollectionViewController alloc] init];
//                                                              [weakSelf setViewControllers:@[controller] animated:NO];
                                                          }];
    
//    activityItem.badge = @"12";
    
    REMenuItem *profileItem = [[REMenuItem alloc] initWithTitle:@"This Week"
                                                          image:[UIImage imageNamed:@"Icon_Profile"]
                                               highlightedImage:nil
                                                         action:^(REMenuItem *item) {
                                                             NSLog(@"Item: %@", item);
//                                                             LBXThisWeekCollectionViewController *controller = [[LBXThisWeekCollectionViewController alloc] init];
//                                                             [weakSelf setViewControllers:@[controller] animated:NO];
                                                         }];
    
    homeItem.tag = 0;
    activityItem.tag = 2;
    profileItem.tag = 3;
    self.menu = [[REMenu alloc] initWithItems:@[homeItem, activityItem, profileItem]];
    self.menu.backgroundAlpha = 0.5;
    self.menu.backgroundColor = [UIColor whiteColor];
    self.menu.textColor = [UIColor blackColor];
    self.menu.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:20];
    self.menu.textShadowOffset = CGSizeMake(0, 0);
    self.menu.textShadowColor = [UIColor clearColor];
    self.menu.textOffset = CGSizeMake(0, 0);
    self.menu.subtitleTextShadowOffset = CGSizeMake(0, 0);
    self.menu.separatorHeight = 1.0;
    self.menu.separatorColor = [UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:0.5];
    self.menu.borderWidth = 0.0;
    self.menu.highlightedTextShadowOffset = CGSizeMake(0, 0);
    self.menu.highlightedTextColor = [UIColor whiteColor];
    
    self.menu.imageOffset = CGSizeMake(5, -1);
    self.menu.waitUntilAnimationIsComplete = NO;
    self.menu.badgeLabelConfigurationBlock = ^(UILabel *badgeLabel, REMenuItem *item) {
        badgeLabel.backgroundColor = [UIColor colorWithRed:0 green:179/255.0 blue:134/255.0 alpha:1];
        badgeLabel.layer.borderColor = [UIColor colorWithRed:0.000 green:0.648 blue:0.507 alpha:1.000].CGColor;
    };
    
    
    [self.menu setClosePreparationBlock:^{
        NSLog(@"Menu will close");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"raiseCollectionView" object:nil];
    }];
    
    [self.menu setCloseCompletionHandler:^{
        NSLog(@"Menu did close");
    }];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    // Blurred background in iOS 7
    //
    self.menu.liveBlur = YES;
    self.menu.liveBlurBackgroundStyle = REMenuLiveBackgroundStyleLight;
}

- (void)toggleMenu
{
    if (self.menu.isOpen)
        return [self.menu close];
    
    [self.menu showFromNavigationController:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dropCollectionView" object:nil];
}

@end
