//
//  NavigationViewController.m
//  REMenuExample
//
//  Created by Roman Efimov on 4/18/13.
//  Copyright (c) 2013 Roman Efimov. All rights reserved.
//
//  Sample icons from http://icons8.com/download-free-icons-for-ios-tab-bar
//

#import "LBXHomeViewController.h"
#import "LBXLoginViewController.h"
#import "LBXNavigationViewController.h"
#import "LBXPullListViewController.h"
#import "LBXThisWeekCollectionViewController.h"
#import "PaperButton.h"
#import "UIColor+customColors.h"
#import "UIFont+customFonts.h"

#import <POP/POP.h>
#import <FontAwesomeKit/FontAwesomeKit.h>

@interface LBXNavigationViewController ()<UINavigationControllerDelegate>

@property (strong, readwrite, nonatomic) REMenu *menu;

@end

@implementation LBXNavigationViewController

PaperButton *button;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    __typeof (self) __weak weakSelf = self;
    int checksize = 25;
    
    // Home icon
    FAKFontAwesome *homeIcon = [FAKFontAwesome homeIconWithSize:checksize];
    [homeIcon addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
    UIImage *iconImage = [homeIcon imageWithSize:CGSizeMake(checksize, checksize)];
    
    REMenuItem *homeItem = [[REMenuItem alloc] initWithTitle:@"Home"
                                                            image:iconImage
                                                 highlightedImage:nil
                                                           action:^(REMenuItem *item) {
                                                               LBXHomeViewController *controller = [[LBXHomeViewController alloc] init];
                                                               controller.title = @"Home";
                                                               
                                                               [self addPaperButtonToViewController:controller];
                                                               
                                                               [self performSelector:@selector(setViewController:) withObject:controller afterDelay:0.1];
                                                           }];
    
    FAKFontAwesome *comicsIcon = [FAKFontAwesome bookIconWithSize:checksize];
    [comicsIcon addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
    iconImage = [comicsIcon imageWithSize:CGSizeMake(checksize, checksize)];
    
    REMenuItem *comicsItem = [[REMenuItem alloc] initWithTitle:@"Comics"
                                                           image:iconImage
                                                highlightedImage:nil
                                                          action:^(REMenuItem *item) {
                                                              LBXThisWeekCollectionViewController *controller = [[LBXThisWeekCollectionViewController alloc] init];
                                                              controller.title = @"Comics";
                                                              
                                                              [self addPaperButtonToViewController:controller];
                                                              
                                                              [self performSelector:@selector(setViewController:) withObject:controller afterDelay:0.1];
                                                          }];
    
    // Arrow with down circle icon
    FAKFontAwesome *thisWeekIcon = [FAKFontAwesome arrowCircleODownIconWithSize:checksize];
    [thisWeekIcon addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
    iconImage = [thisWeekIcon imageWithSize:CGSizeMake(checksize, checksize)];
    
    REMenuItem *thisWeekItem = [[REMenuItem alloc] initWithTitle:@"This Week"
                                                           image:iconImage
                                                highlightedImage:nil
                                                          action:^(REMenuItem *item) {
                                                              LBXThisWeekCollectionViewController *controller = [[LBXThisWeekCollectionViewController alloc] init];
                                                              controller.title = @"This Week";
                                                              
                                                              [self addPaperButtonToViewController:controller];
                                                              
                                                              [self performSelector:@selector(setViewController:) withObject:controller afterDelay:0.1];
                                                          }];
    
    // List Icon
    FAKFontAwesome *pullListIcon = [FAKFontAwesome listIconWithSize:checksize];
    [pullListIcon addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
    iconImage = [pullListIcon imageWithSize:CGSizeMake(checksize, checksize)];
    
    REMenuItem *activityItem = [[REMenuItem alloc] initWithTitle:@"Pull List"
                                                           image:iconImage
                                                highlightedImage:nil
                                                          action:^(REMenuItem *item) {
                                                              LBXPullListViewController *controller = [[LBXPullListViewController alloc] init];
                                                              controller.title = @"Pull List";
                                                              
                                                              [self addPaperButtonToViewController:controller];
                                                              
                                                              [self performSelector:@selector(setViewController:) withObject:controller afterDelay:0.1];
                                                          }];
    
    
//    activityItem.badge = @"12";
    
    // Sign In Icon
    FAKFontAwesome *signInIcon = [FAKFontAwesome signInIconWithSize:checksize];
    [signInIcon addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor]];
    iconImage = [signInIcon imageWithSize:CGSizeMake(checksize, checksize)];
    
    REMenuItem *profileItem = [[REMenuItem alloc] initWithTitle:@"Log In"
                                                          image:iconImage
                                               highlightedImage:nil
                                                         action:^(REMenuItem *item) {
                                                             LBXLoginViewController *controller = [[LBXLoginViewController alloc] init];
                                                             controller.title = @"Log In";
                                                             
                                                             [self addPaperButtonToViewController:controller];
                                                             
                                                             [self performSelector:@selector(setViewController:) withObject:controller afterDelay:0.15];
                                                         }];
    
    homeItem.tag = 0;
    thisWeekItem.tag = 1;
    activityItem.tag = 2;
    profileItem.tag = 3;
    
    self.menu = [[REMenu alloc] initWithItems:@[homeItem, comicsItem, thisWeekItem, activityItem, profileItem]];
    
    // Set up the menu visual properties
    [self setupMenu];
    
    [self.menu setClosePreparationBlock:^{
        
        [weakSelf raiseView];
    }];
    
    [self.menu setCloseCompletionHandler:^{
        //NSLog(@"Menu did close");
    }];
    
    self.menu.badgeLabelConfigurationBlock = ^(UILabel *badgeLabel, REMenuItem *item) {
        badgeLabel.backgroundColor = [UIColor whiteColor];
        badgeLabel.layer.borderColor = [UIColor blackColor].CGColor;
        badgeLabel.textColor = [UIColor blackColor];
    };
    
}

- (void)viewWillAppear:(BOOL)animated
{
    // Blurred background in iOS 7
    self.menu.liveBlur = NO;
    self.menu.liveBlurBackgroundStyle = REMenuLiveBackgroundStyleLight;
}

# pragma mark Public Methods

- (void)addPaperButtonToViewController:(UIViewController *)viewController
{
    button = [PaperButton button];
    [button addTarget:viewController.navigationController action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    button.tintColor = [UIColor blackColor];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    viewController.navigationItem.leftBarButtonItem = barButton;
    
    [viewController.navigationItem.leftBarButtonItem setTintColor:[UIColor blackColor]];
    NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               [UIColor blackColor], NSForegroundColorAttributeName, nil];
    [[UIBarButtonItem appearance] setTitleTextAttributes:fontDict forState:UIControlStateNormal];
}

# pragma mark Private Methods

- (void)setupMenu
{
    self.menu.backgroundAlpha = 0.5;
    self.menu.backgroundColor = [UIColor whiteColor];
    self.menu.textColor = [UIColor blackColor];
    self.menu.font = [UIFont menuFont];
    self.menu.textShadowOffset = CGSizeMake(0, 0);
    self.menu.textOffset = CGSizeMake(0, 0);
    self.menu.subtitleTextShadowOffset = CGSizeMake(0, 0);
    self.menu.separatorHeight = 1.0;
    self.menu.separatorColor = [UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:0.5];
    self.menu.borderWidth = 0.0;
    self.menu.highlightedTextShadowOffset = CGSizeMake(0, 0);
    self.menu.highlightedTextColor = [UIColor whiteColor];
    self.menu.highlightedBackgroundColor = [UIColor colorWithRed:74/255.0 green:74/255.0 blue:74/255.0 alpha:1.0];
    
    self.menu.imageOffset = CGSizeMake(5, -1);
    self.menu.waitUntilAnimationIsComplete = NO;
    self.menu.badgeLabelConfigurationBlock = ^(UILabel *badgeLabel, REMenuItem *item) {
        badgeLabel.backgroundColor = [UIColor colorWithRed:0 green:179/255.0 blue:134/255.0 alpha:1];
        badgeLabel.layer.borderColor = [UIColor colorWithRed:0.000 green:0.648 blue:0.507 alpha:1.000].CGColor;
    };
}

- (void)setViewController:(UIViewController *)viewController
{
     [self setViewControllers:@[viewController] animated:NO];
}

// Needed to flip the button to close if the
// button OR the view is pressed
- (void)flipButtonToMenu
{
    [button animateToMenu];
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [UIFont navTitleFont], NSFontAttributeName,nil];
    [[UINavigationBar appearance] setTitleTextAttributes: fontDict];
}

- (void)toggleMenu
{
    if (self.menu.isOpen) {
        return [self.menu close];
    }
    [self.menu showFromNavigationController:self];
    
    // The animation does not occur when calling [self dropView] or with an afterDelay of 0-0.000.
    // Possibly due to the navigationController not having shown yet (showFromNavigationController)?
    // But a delay to the millionth place works. Is this an Objective-C bug?
    [self performSelector:@selector(dropView) withObject:nil afterDelay:0.001];
    
}

- (void)dropView
{
    [button animateToClose];
    // Taken from REMenu.m
    [UIView animateWithDuration:self.menu.animationDuration+self.menu.bounceAnimationDuration
                          delay:0.0
         usingSpringWithDamping:0.6
          initialSpringVelocity:4.0
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect frame = self.view.frame;
                         frame.origin.y = self.view.frame.origin.y + self.menu.combinedHeight - self.navigationBar.frame.size.height;
                         for (UIViewController *viewController in self.viewControllers) {
                             viewController.view.frame = frame;
                         }
                         
                     } completion:nil];
}

- (void)raiseView
{
    // Taken from the REMenu
    void (^closeMenu)(void) = ^{
        [UIView animateWithDuration:self.menu.retractAnimationDuration
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                         animations:^ {
                             [self flipButtonToMenu];
                             CGRect frame = self.view.frame;
                             frame.origin.y = self.view.frame.origin.y;
                             for (UIViewController *viewController in self.viewControllers) {
                                 viewController.view.frame = frame;
                             }
                         } completion:nil];
        
    };
    
    [UIView animateWithDuration:self.menu.bounceAnimationDuration animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y = self.menu.combinedHeight - self.navigationBar.frame.size.height + 20.0;
        for (UIViewController *viewController in self.viewControllers) {
            viewController.view.frame = frame;
        }
    } completion:^(BOOL finished) {
        closeMenu();
    }];
}

@end
