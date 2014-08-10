//
//  NSDate+LBXUtilities.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "NSDate+DateUtilities.h"

@implementation NSDate (DateUtilities)

+ (NSString *)fuzzyTimeBetweenStartDate:(NSDate *)startDate andEndDate:(NSDate *)endDate
{
#define SECOND 1
#define MINUTE (60 * SECOND)
#define HOUR (60 * MINUTE)
#define DAY (24 * HOUR)
#define MONTH (30 * DAY)
    
    //http://stackoverflow.com/questions/1052951/fuzzy-date-algorithm-in-objective-c
    //Calculate the delta in seconds between the two dates
    NSTimeInterval delta = [endDate timeIntervalSinceDate:startDate];
    
    if (delta < 0) {
        int days = floor((double)delta/DAY);
        return days >= -1 ? @"in 1 day" : [NSString stringWithFormat:@"in %d days", abs(days)];
    }
    
    if (delta < 24 * HOUR)
    {
        return @"Today";
    }
    if (delta < 48 * HOUR)
    {
        return @"Yesterday";
    }
    if (delta < 30 * DAY)
    {
        int days = floor((double)delta/DAY);
        return [NSString stringWithFormat:@"%d days ago", days];
    }
    if (delta < 12 * MONTH)
    {
        int months = floor((double)delta/MONTH);
        return months <= 1 ? @"1 month ago" : [NSString stringWithFormat:@"%d months ago", months];
    }
    else
    {
        int years = floor((double)delta/MONTH/12.0);
        return years <= 1 ? @"1 year ago" : [NSString stringWithFormat:@"%d years ago", years];
    }
}



@end
