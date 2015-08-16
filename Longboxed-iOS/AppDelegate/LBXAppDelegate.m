//
//  LBXAppDelegate.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 6/29/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//
#import "LBXDatabaseManager.h"
#import "LBXAppDelegate.h"
#import "LBXDashboardViewController.h"
#import "LBXClient.h"
#import "LBXLogging.h"
#import "LBXServices.h"
#import "LBXControllerServices.h"
#import "LBXWeekViewController.h"
#import "UIColor+LBXCustomColors.h"

#import "UIFont+LBXCustomFonts.h"
#import "PaintCodeImages.h"

// Logging
#import "DDLog.h"
#import "DDNSLoggerLogger.h"
#import "DDTTYLogger.h"
#import "NSLogger.h"
#import "PSDDFormatter.h"

#import <Crashlytics/Crashlytics.h>
#import <CrashReporter/CrashReporter.h>
#import <Fabric/Fabric.h>
#import "FAKFontAwesome.h"
#import "TSMessage.h"
#import "OnboardingContentViewController.h"
#import "LBXLoginViewController.h"
#import "LBXSignupViewController.h"
#import "SIAlertView.h"
#import <JRHUtilities/NSDate+DateUtilities.h>

static NSString * const kUserHasOnboardedKey = @"userHasOnboarded";


@interface LBXAppDelegate ()

@property (nonatomic) LBXDashboardViewController *dashboardViewController;

@end

@implementation LBXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Fetch in the background as often as possible
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [LBXDatabaseManager setupRestKit];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // OnBoard if necessary
    BOOL userHasOnboarded = [[NSUserDefaults standardUserDefaults] boolForKey:kUserHasOnboardedKey];
    
    // If the user has already onboarded, just set up the normal root view controller
    // for the application, but don't animate it because there's no transition in this case
    _dashboardViewController = [LBXDashboardViewController new];
    if (userHasOnboarded) {
        [self setupNormalRootViewControllerAnimated:NO];
    }
    else {
        self.window.rootViewController = [self generateOnboardingVC];
    }
    
    [self.window makeKeyAndVisible];
    
    
    // Set the font for all UIBarButtonItems
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = CGSizeMake(0.0, 1.0);
    shadow.shadowColor = [UIColor whiteColor];
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]
     setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor blackColor],
       NSShadowAttributeName:shadow,
       NSFontAttributeName:[UIFont navSubtitleFont]
       }
     forState:UIControlStateNormal];
    
    // Set a UUID for the user
    [LBXServices setUserID];
    
    // Start up the crash reporting
    CrashlyticsKit.delegate = _dashboardViewController;
    [Fabric with:@[CrashlyticsKit]];
    // Set a UUID for the session
    [LBXServices setSessionUUID];
    
    // Apply the UUIDs to Crashlytics — so that the crash report has this metadata
    [CrashlyticsKit setUserName:[LBXServices getUserID]];
    [CrashlyticsKit setUserIdentifier:[LBXServices getSessionUUID]];
    
    // Launched from local notification
    NSDictionary *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotif != nil) [self pushToBundleView];
    
    return YES;
}

// Launched from local notification
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if ([application applicationState] == UIApplicationStateInactive) [self pushToBundleView];
}

- (void)pushToBundleView
{
    LBXWeekViewController *controller = [[LBXWeekViewController alloc] initWithIssues:[LBXBundle MR_findAllSortedBy:@"releaseDate" ascending:NO] andTitle:@"Bundles"];
    [((UINavigationController *)self.window.rootViewController) pushViewController:controller animated:YES];
}

- (void)externallySetRootViewController:(id)viewController {
    [UIView transitionWithView:self.window duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.window.rootViewController = viewController;
    } completion:nil];

}

- (void)setupNormalRootViewControllerAnimated:(BOOL)animated {
    // Override point for customization after application launch
    if (animated) {
        [UIView transitionWithView:self.window duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:_dashboardViewController];
        } completion:nil];
    }
    // otherwise just set the root view controller normally without animation
    else {
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:_dashboardViewController];
    }
    
    _dashboardViewController.managedObjectContext = [NSManagedObjectContext MR_defaultContext];
}

- (void)handleOnboardingCompletion {
    // Set that we have completed onboarding so we only do it once.
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserHasOnboardedKey];
    
    // animate the transition to the main application
    [self setupNormalRootViewControllerAnimated:YES];
    
    [_dashboardViewController fetchBundle];
}

// get the log content with a maximum byte size
- (NSString *) getLogFilesContentWithMaxSize:(NSInteger)maxSize {
    NSMutableString *description = [NSMutableString string];
    
    NSArray *sortedLogFileInfos = [[_fileLogger logFileManager] sortedLogFileInfos];
    NSInteger count = [sortedLogFileInfos count];
    // we start from the last one
    for (NSInteger index = count - 1; index >= 0; index--) {
        DDLogFileInfo *logFileInfo = [sortedLogFileInfos objectAtIndex:index];
        NSData *logData = [[NSFileManager defaultManager] contentsAtPath:[logFileInfo filePath]];
        if ([logData length] > 0) {
            NSString *result = [[NSString alloc] initWithBytes:[logData bytes]
                                                        length:[logData length]
                                                      encoding: NSUTF8StringEncoding];
            
            [description appendString:result];
        }
    }
    
    if ((long)[description length] > maxSize) {
        description = (NSMutableString *)[description substringWithRange:NSMakeRange([description length]-maxSize-1, maxSize)];
    }
    
    return description;
}

#pragma mark - Background Refreshing

// Background refresh
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    LBXClient *client = [LBXClient new];
    
    if ([LBXControllerServices isLoggedIn]) {
        // Fetch the users bundles
        [client fetchBundleResourcesWithDate:[NSDate thisWednesdayOfDate:[NSDate localDate]] page:@1 count:@1 completion:^(NSArray *bundleArray, RKObjectRequestOperation *response, NSError *error) {
            if (!error) {
                [LBXLogging logMessage:@"Fetched users latest bundle"];
                
                // Fetch popular issues
                [client fetchPopularIssuesWithDate:[NSDate thisWednesdayOfDate:[NSDate localDate]] completion:^(NSArray *popularIssuesArray, RKObjectRequestOperation *response, NSError *error) {
                    [LBXLogging logMessage:@"Fetched popular titles"];
                    if (!error) {
                        completionHandler(UIBackgroundFetchResultFailed);
                    }
                    else {
                        [LBXLogging logMessage:@"Failed fetching titles"];
                        completionHandler(UIBackgroundFetchResultFailed);
                    }
                }];
            }
            else {
                [LBXLogging logMessage:@"Failed fetching users latest bundle"];
                completionHandler(UIBackgroundFetchResultFailed);
            }
        }];
    }
    else completionHandler(UIBackgroundFetchResultNewData);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    // Hide any error messages that may have come up
    [self setAPIErrorMessageVisible:NO withError:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // Hide any error messages that may have come up
    [self setAPIErrorMessageVisible:NO withError:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [MagicalRecord cleanUp];
}


// http://oleb.net/blog/2009/09/managing-the-network-activity-indicator/
- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible {
    static NSUInteger kNetworkIndicatorCount = 0;
    
    if (setVisible) {
        kNetworkIndicatorCount++;
    }
    else {
        kNetworkIndicatorCount--;
    }
    
    // Display the indicator as long as our static counter is > 0.
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(kNetworkIndicatorCount > 0)];
    });
}

- (void)setAPIErrorMessageVisible:(BOOL)setVisible withError:(NSError *)error {
    NSString *localizedErrorString = error.userInfo[@"NSLocalizedDescription"];
    NSString *errorMessage = (localizedErrorString) ? [localizedErrorString stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[localizedErrorString substringToIndex:1] uppercaseString]] : @"Unable to connect to Longboxed servers.";

    [TSMessage addCustomDesignFromFileWithName:@"LBXErrorDesign.json"];
    
    if (setVisible) {
        [TSMessage showNotificationInViewController:self.window.rootViewController
                                              title:@"Error"
                                           subtitle:errorMessage
                                              image:nil
                                               type:TSMessageNotificationTypeError
                                           duration:3.0f
                                           callback:nil
                                        buttonTitle:nil 
                                     buttonCallback:nil
                                         atPosition:TSMessageNotificationPositionNavBarOverlay
                               canBeDismissedByUser:YES];
    }
    else {
        [TSMessage dismissActiveNotification];
    }
}

#pragma mark OnBoarding

- (OnboardingViewController *)generateOnboardingVC {
    int iconSize = 1000;

    UIImage *logoImage = [PaintCodeImages imageOfLongboxedTextWithLogoTextColor:[UIColor whiteColor] logoWidth:[[UIScreen mainScreen] bounds].size.width * 0.9];
    
    OnboardingContentViewController *firstPage = [[OnboardingContentViewController alloc] initWithTitle:@"Welcome to\n" body:@"Never miss an issue again." image:logoImage buttonText:@"How it works" action:^{
            [((OnboardingViewController *)self.window.rootViewController) moveNextPage];
        }];
    firstPage.topPadding = [[UIScreen mainScreen] bounds].size.height/3;
    firstPage.iconWidth = [[UIScreen mainScreen] bounds].size.width * 0.8;
    firstPage.iconHeight = firstPage.iconWidth/8.5;
    firstPage.topPadding = firstPage.topPadding+([[UIScreen mainScreen] bounds].size.height/11);
    firstPage.underIconPadding = -100;
    firstPage.underTitlePadding = 0 - 1/([[UIScreen mainScreen] bounds].size.width/100);
    
    firstPage.titleFontName = [UIFont onboardingTitleFont].fontName;
    firstPage.titleFontSize = [UIFont onboardingTitleFont].pointSize;
    firstPage.bodyFontName = [UIFont onboardingBodyFont].fontName;
    firstPage.bodyFontSize = [UIFont onboardingBodyFont].pointSize;
    firstPage.buttonFontName = [UIFont onboardingButtonFont].fontName;
    firstPage.buttonFontSize = [UIFont onboardingButtonFont].pointSize;
    
    FAKFontAwesome *bookIcon = [FAKFontAwesome bookIconWithSize:iconSize];
    [bookIcon addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    UIImage *bookImage = [bookIcon imageWithSize:CGSizeMake(iconSize, iconSize)];
    
    OnboardingContentViewController *secondPage = [[OnboardingContentViewController alloc] initWithTitle:@"Explore Comics" body:@"Browse thousands of titles. Every issue is cataloged and tracked." image:bookImage buttonText:nil action:nil];

    secondPage.topPadding = 90;
    secondPage.iconHeight = self.window.frame.size.height/7;
    secondPage.iconWidth = self.window.frame.size.height/7;
    
    secondPage.titleFontName = [UIFont onboardingTitleFont].fontName;
    secondPage.titleFontSize = [UIFont onboardingTitleFont].pointSize;
    secondPage.bodyFontName = [UIFont onboardingBodyFont].fontName;
    secondPage.bodyFontSize = [UIFont onboardingBodyFont].pointSize;
    secondPage.buttonFontName = [UIFont onboardingButtonFont].fontName;
    secondPage.buttonFontSize = [UIFont onboardingButtonFont].pointSize;
    
    FAKFontAwesome *listIcon = [FAKFontAwesome listIconWithSize:iconSize];
    [listIcon addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    UIImage *listImage = [listIcon imageWithSize:CGSizeMake(iconSize, iconSize)];
    
    OnboardingContentViewController *thirdPage = [[OnboardingContentViewController alloc] initWithTitle:@"Create A Pull List" body:@"Add favorite titles to your pull list to keep track of upcoming issues." image:listImage buttonText:nil action:nil];
    
    thirdPage.topPadding = 90;
    thirdPage.iconHeight = self.window.frame.size.height/7;
    thirdPage.iconWidth = self.window.frame.size.height/7;
    
    thirdPage.titleFontName = [UIFont onboardingTitleFont].fontName;
    thirdPage.titleFontSize = [UIFont onboardingTitleFont].pointSize;
    thirdPage.bodyFontName = [UIFont onboardingBodyFont].fontName;
    thirdPage.bodyFontSize = [UIFont onboardingBodyFont].pointSize;
    thirdPage.buttonFontName = [UIFont onboardingButtonFont].fontName;
    thirdPage.buttonFontSize = [UIFont onboardingButtonFont].pointSize;
    
    FAKFontAwesome *bundleIcon = [FAKFontAwesome archiveIconWithSize:iconSize];
    [bundleIcon addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    UIImage *bundleImage = [PaintCodeImages imageOfLongboxedLogoWithColor:[UIColor whiteColor] width:iconSize];
    
    OnboardingContentViewController *fourthPage = [[OnboardingContentViewController alloc] initWithTitle:@"Check Your Bundles" body:@"Bundles are like shopping lists for your local comic shop. You'll never miss an issue." image:bundleImage buttonText:nil action:nil];
    
    fourthPage.topPadding = 90;
    fourthPage.iconHeight = self.window.frame.size.height/7;
    fourthPage.iconWidth = self.window.frame.size.height/7;
    
    fourthPage.titleFontName = [UIFont onboardingTitleFont].fontName;
    fourthPage.titleFontSize = [UIFont onboardingTitleFont].pointSize;
    fourthPage.bodyFontName = [UIFont onboardingBodyFont].fontName;
    fourthPage.bodyFontSize = [UIFont onboardingBodyFont].pointSize;
    fourthPage.buttonFontName = [UIFont onboardingButtonFont].fontName;
    fourthPage.buttonFontSize = [UIFont onboardingButtonFont].pointSize;

    if (![LBXControllerServices isLoggedIn]) {
        firstPage.bottomPadding = 44;
        secondPage.bottomPadding = firstPage.bottomPadding;
        thirdPage.bottomPadding = firstPage.bottomPadding;
        fourthPage.bottomPadding = firstPage.bottomPadding;
    }
    
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *moviePath = [bundle pathForResource:@"OnboardMovie" ofType:@"mp4"];
    NSURL *movieURL = [NSURL fileURLWithPath:moviePath];
    
    OnboardingViewController *onboardingVC = [[OnboardingViewController alloc] initWithBackgroundVideoURL:movieURL contents:@[firstPage, secondPage, thirdPage, fourthPage]];
    onboardingVC.shouldFadeTransitions = YES;
    onboardingVC.shouldMaskBackground = YES;
    onboardingVC.pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    onboardingVC.pageControl.pageIndicatorTintColor = [UIColor grayColor];
    onboardingVC.allowSkipping = YES;
    onboardingVC.skipButton.titleLabel.font = [UIFont onboardingSkipButtonFont];
    if (![LBXControllerServices isLoggedIn]) {
        onboardingVC.loginButtonFont = [UIFont onboardingLoginAndSignupButtonFont];
        onboardingVC.signupButtonFont = [UIFont onboardingLoginAndSignupButtonFont];
        onboardingVC.underPagingPadding = 48;
    }
    else {
        onboardingVC.hideSignupAndLoginButtons = YES;
    }
    
    onboardingVC.signupHandler = ^{
        LBXSignupViewController *signupController = [LBXSignupViewController new];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:signupController];
        [self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
    };
    onboardingVC.loginHandler = ^{
        LBXLoginViewController *loginController = [LBXLoginViewController new];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:loginController];
        [self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
    };
    onboardingVC.skipHandler = ^{
        if (![LBXControllerServices isLoggedIn]) {
            SIAlertView *alert = [[SIAlertView alloc] initWithTitle:@"Continue Without An Account?" andMessage:@"An account is required to create a pull list and track comics."];
            [alert addButtonWithTitle:@"Sign Up"
                                 type:SIAlertViewButtonTypeCancel
                              handler:^(SIAlertView *alert) {
                                  LBXSignupViewController *signupController = [LBXSignupViewController new];
                                  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:signupController];
                                  [self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
                              }];
            [alert addButtonWithTitle:@"Continue"
                                     type:SIAlertViewButtonTypeDefault
                                  handler:^(SIAlertView *alert) {
                                      [self handleOnboardingCompletion];
                                      SIAlertView *alert2 = [[SIAlertView alloc] initWithTitle:@"Enjoy Longboxed!" andMessage:@"If you change your mind, tap the gear in the top left to sign up for an account."];
                                      [alert2 addButtonWithTitle:@"OK"
                                                           type:SIAlertViewButtonTypeCancel
                                                        handler:nil];
                                      alert2.titleFont = [UIFont alertViewTitleFont];
                                      alert2.messageFont = [UIFont alertViewMessageFont];
                                      alert2.buttonFont = [UIFont alertViewButtonFont];
                                      alert2.transitionStyle = SIAlertViewTransitionStyleDropDown;
                                      [alert2 show];
                                  }];
            alert.titleFont = [UIFont alertViewTitleFont];
            alert.messageFont = [UIFont alertViewMessageFont];
            alert.buttonFont = [UIFont alertViewButtonFont];
            alert.transitionStyle = SIAlertViewTransitionStyleDropDown;
            [alert show];
        }
        else {
            [self handleOnboardingCompletion];
        }
    };
    
    return onboardingVC;
}

@end
