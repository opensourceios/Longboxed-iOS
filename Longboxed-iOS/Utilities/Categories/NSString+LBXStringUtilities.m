//
//  NSString+LBXStringUtilities.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 12/9/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "NSString+LBXStringUtilities.h"
#import "NSDate+DateUtilities.h"
#import "LBXControllerServices.h"

@implementation NSString (LBXStringUtilities)

// This is for the pull list view and title view
+ (NSString *)timeStringSinceLastIssueForTitle:(LBXTitle *)title
{
    LBXIssue *issue = [NSString closestIssueForTitle:title];
    
    if (issue != nil) {
        return [NSString stringWithFormat:@"%@", [NSDate fuzzyTimeBetweenStartDate:issue.releaseDate andEndDate:[NSDate localDate]]];
    }
    return @"";
}

+ (NSString *)getSubtitleStringWithTitle:(LBXTitle *)title uppercase:(BOOL)uppercase
{
    NSString *subtitleString = [NSString new];
    switch ([title.subscribers integerValue]) {
        case 1: {
            subtitleString = [NSString stringWithFormat:@"%@ Subscriber", title.subscribers];
            break;
        }
        default: {
            subtitleString = [NSString stringWithFormat:@"%@ Subscribers", title.subscribers];
            break;
        }
    }
    if (uppercase) {
        return subtitleString.uppercaseString;
    }
    return subtitleString;
}

# pragma mark Private Methods
// This is for the pull list view
+ (LBXIssue *)closestIssueForTitle:(LBXTitle *)title
{
    if ([title.titleID  isEqual: @586]) {
        
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title.titleID == %@", title.titleID];
    NSArray *issuesArray = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    if (issuesArray.count != 0) {
        
        LBXIssue *newestIssue = issuesArray[0];
        
        if (issuesArray.count > 1) {
            LBXIssue *secondNewestIssue = issuesArray[1];
            // Check if the latest issue is next week and the second latest issue is this week
            
            // If the second newest issues release date is more recent than 4 days ago
            if ([secondNewestIssue.releaseDate timeIntervalSinceDate:[NSDate date]] > -4*DAY) {
                return secondNewestIssue;
            }
            return newestIssue;
        }
        return newestIssue;
    }
    return nil;
}

@end
