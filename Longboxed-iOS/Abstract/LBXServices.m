//
//  LBXServices.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/13/15.
//  Copyright © 2015 Longboxed. All rights reserved.
//

#import "LBXServices.h"

@implementation LBXServices

#pragma mark Public Methods

+ (void)setSessionUUID {
    [[NSUserDefaults standardUserDefaults] setObject:[[NSUUID UUID] UUIDString] forKey:@"SessionUUID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)getSessionUUID {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"SessionUUID"];
}

// Only set the UserID if we haven't done so yet
+ (void)setUserID {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"UserID"] == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:[[NSUUID UUID] UUIDString] forKey:@"UserID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (NSString *)getUserID {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"UserID"];
}

+ (NSString *)crashFilePath {
    NSString *pathForFile = [[self documentsDirectory] stringByAppendingPathComponent:@"crash.log"];
    return pathForFile;
}

#pragma mark Private Methods

+ (NSString *)documentsDirectory {
    NSString *documentsDir = (NSString *)[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return documentsDir;
}

@end
