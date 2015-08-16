//
//  LBXIssue.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/6/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXIssue.h"
#import "NSDate+DateUtilities.h"

@implementation LBXIssue

@dynamic completeTitle;
@dynamic coverImage;
@dynamic issueDescription;
@dynamic diamondID;
@dynamic issueID;
@dynamic alternates;
@dynamic isParent;
@dynamic issueNumber;
@dynamic subtitle;
@dynamic price;
@dynamic publisher;
@dynamic releaseDate;
@dynamic title;

- (NSString *)description
{
    return [NSString stringWithFormat:@"Complete Title: %@\nID: %@\nPublisher: %@\nRelease Date: %@", self.completeTitle, self.issueID, self.publisher.name, self.releaseDate];
}

- (BOOL)isBeingReleasedThisWeek {
    NSDate *currentDate = [NSDate localDate];
    if (self.releaseDate > [[NSDate thisWednesdayOfDate:currentDate] dateByAddingTimeInterval:-1*DAY] && self.releaseDate < [[NSDate nextWednesdayOfDate:currentDate] dateByAddingTimeInterval:-1*DAY]) {
        NSLog(@"Being Released This Week: %@", self.completeTitle);
        return YES;
    }
    return NO;
}

- (BOOL)isBeingReleasedNextWeek {
    NSDate *currentDate = [NSDate localDate];
    if (self.releaseDate > [[NSDate nextWednesdayOfDate:currentDate] dateByAddingTimeInterval:-1*DAY] && self.releaseDate < [[NSDate nextWednesdayOfDate:[NSDate localDate]] dateByAddingTimeInterval:6*DAY]) {
        NSLog(@"Being Released Next Week: %@", self.completeTitle);
        return YES;
    }
    return NO;
}

@end
