//
//  NSDate+LBXUtilities.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (DateUtilities)

+ (NSString *)fuzzyTimeBetweenStartDate:(NSDate *)startDate andEndDate:(NSDate *)endDate;
+ (NSDate *)getLocalDate;
+ (NSDate *)getThisWednesdayOfDate:(NSDate *)date;
+ (NSDate *)getNextWednesdayOfDate:(NSDate *)date;

@end
