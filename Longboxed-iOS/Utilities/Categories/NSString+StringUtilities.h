//
//  NSString+StringUtilities.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 12/9/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (StringUtilities)

+ (NSString *)getHashOfImage:(UIImage *)image;
+ (NSString *)localTimeZoneStringWithDate:(NSDate *)date;
+ (NSString *)regexOutHTMLJunk:(NSString *)string;

@end
