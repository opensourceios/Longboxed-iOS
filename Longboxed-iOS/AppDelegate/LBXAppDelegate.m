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
#import "LBXControllerServices.h"

#import "UIFont+LBXCustomFonts.h"

// Logging
#import "DDLog.h"
#import "DDNSLoggerLogger.h"
#import "DDTTYLogger.h"
#import "NSLogger.h"
#import "PSDDFormatter.h"

#import <Crashlytics/Crashlytics.h>
#import <CrashReporter/CrashReporter.h>

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
    // Override point for customization after application launch.
    
    _dashboardViewController = [LBXDashboardViewController new];
    
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:_dashboardViewController];
    _dashboardViewController.managedObjectContext = [NSManagedObjectContext MR_defaultContext];
    
    [self.window makeKeyAndVisible];
    
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSError *error;
    
    // Check if we previously crashed
    if ([crashReporter hasPendingCrashReport])
        [LBXControllerServices showCrashAlertWithDelegate:_dashboardViewController];
    
    // Enable the Crash Reporter
    if (![crashReporter enableCrashReporterAndReturnError: &error])
        [LBXLogging logMessage:[NSString stringWithFormat:@"Warning: Could not enable crash reporter: %@", error]];
    
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
    
    // initialize before HockeySDK, so the delegate can access the file logger!
    _fileLogger = [[DDFileLogger alloc] init];
    _fileLogger.maximumFileSize = (1024 * 500); // 500 KByte
    _fileLogger.logFileManager.maximumNumberOfLogFiles = 1;
    [_fileLogger rollLogFileWithCompletionBlock:nil];
    [DDLog addLogger:_fileLogger];
    
    // Crashlytics
    [Crashlytics startWithAPIKey:@"16ebe072876d720b57b612526b0b6f214e2c3cf5"];
    
    // Hockey app needs to be the last 3rd party integration in this method
    // Alpha Version
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"4064359702d9b0088c5ccb88d7d897b5"];
    
    // add Xcode console logger if not running in the App Store
    if (![[BITHockeyManager sharedHockeyManager] isAppStoreEnvironment]) {
        PSDDFormatter *psLogger = [[PSDDFormatter alloc] init];
        [[DDTTYLogger sharedInstance] setLogFormatter:psLogger];
        
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        [DDLog addLogger:[DDNSLoggerLogger sharedInstance]];
    }
    
    [LBXLogging beginLogging];
    
    // Automatically send crash reports
    [[BITHockeyManager sharedHockeyManager].crashManager setCrashManagerStatus:BITCrashManagerStatusAutoSend];
    
    [[BITHockeyManager sharedHockeyManager] setDelegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    
    return YES;
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

#pragma mark - BITCrashManagerDelegate

- (NSString *)applicationLogForCrashManager:(BITCrashManager *)crashManager {
    NSString *description = [self getLogFilesContentWithMaxSize:5000]; // 5000 bytes should be enough!
    if ([description length] == 0) {
        return nil;
    } else {
        return description;
    }
}

#pragma mark - Background Refreshing

// Background refresh
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    LBXClient *client = [LBXClient new];
    // Fetch popular issues
    [client fetchPopularIssuesWithCompletion:^(NSArray *popularIssuesArray, RKObjectRequestOperation *response, NSError *error) {
        [LBXLogging logMessage:@"Fetched popular titles"];
        if (!error) {
            for (LBXIssue *issue in popularIssuesArray) {
                [client fetchTitle:issue.title.titleID withCompletion:^(LBXTitle *title, RKObjectRequestOperation *response, NSError *error) {
                    if (error) {
                        [LBXLogging logMessage:@"Failed fetching popular titles"];
                        completionHandler(UIBackgroundFetchResultFailed);
                    }
                }];
            }
        }
        else {
            [LBXLogging logMessage:@"Failed fetching titles"];
            completionHandler(UIBackgroundFetchResultFailed);
        }
    }];
    
    if ([LBXControllerServices isLoggedIn]) {
        // Fetch the users bundles
        [client fetchBundleResourcesWithCompletion:^(NSArray *bundleArray, RKObjectRequestOperation *response, NSError *error) {
            if (!error) {
                [LBXLogging logMessage:@"Fetched users bundles"];
                completionHandler(UIBackgroundFetchResultNewData);
            }
            else {
                [LBXLogging logMessage:@"Failed fetching users bundles"];
                completionHandler(UIBackgroundFetchResultFailed);
            }
        }];
    }
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
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
