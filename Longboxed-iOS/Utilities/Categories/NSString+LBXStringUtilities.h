//
//  NSString+LBXStringUtilities.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 12/9/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBXTitle.h"

@interface NSString (LBXStringUtilities)

+ (NSString *)timeStringSinceLastIssueForTitle:(LBXTitle *)title;
+ (NSString *)getSubtitleStringWithTitle:(LBXTitle *)title uppercase:(BOOL)uppercase;

@end
