//
//  LBXServices.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/13/15.
//  Copyright © 2015 Longboxed. All rights reserved.
//

#import "LBXServices.h"
#import "NSDate+DateUtilities.h"

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

+ (NSPredicate *)thisWeekPredicateWithParentCheck:(BOOL)parent {
    NSDate *currentDate = [NSDate localDate];
    if (parent) {
        return [NSPredicate predicateWithFormat:@"(releaseDate > %@) AND (releaseDate < %@) AND (isParent == %@)", [[NSDate thisWednesdayOfDate:currentDate] dateByAddingTimeInterval:-1*DAY], [[NSDate nextWednesdayOfDate:currentDate] dateByAddingTimeInterval:-1*DAY], @1];
    }
    return [NSPredicate predicateWithFormat:@"(releaseDate > %@) AND (releaseDate < %@)", [[NSDate thisWednesdayOfDate:currentDate] dateByAddingTimeInterval:-1*DAY], [[NSDate nextWednesdayOfDate:currentDate] dateByAddingTimeInterval:-1*DAY]];
}

+ (NSPredicate *)nextWeekPredicateWithParentCheck:(BOOL)parent {
    NSDate *currentDate = [NSDate localDate];
    if (parent) {
        return [NSPredicate predicateWithFormat: @"(releaseDate > %@) AND (releaseDate < %@) AND (isParent == %@)", [[NSDate nextWednesdayOfDate:currentDate] dateByAddingTimeInterval:-1*DAY], [[NSDate nextWednesdayOfDate:[NSDate localDate]] dateByAddingTimeInterval:6*DAY], @1];
    }
    return [NSPredicate predicateWithFormat: @"(releaseDate > %@) AND (releaseDate < %@)", [[NSDate nextWednesdayOfDate:currentDate] dateByAddingTimeInterval:-1*DAY], [[NSDate nextWednesdayOfDate:[NSDate localDate]] dateByAddingTimeInterval:6*DAY]];
}

#pragma mark Private Methods

+ (NSString *)documentsDirectory {
    NSString *documentsDir = (NSString *)[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return documentsDir;
}

@end
