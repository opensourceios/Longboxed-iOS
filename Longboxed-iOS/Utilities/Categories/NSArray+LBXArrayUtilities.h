//
//  NSArray+ArrayUtilities.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (LBXArrayUtilities)

+ (NSArray *)sortedArray:(NSArray *)array basedOffObjectProperty:(NSString *)property;
+ (NSArray *)getPublisherTableViewSectionArrayForArray:(NSArray *)array;
+ (NSArray *)getBundleTableViewSectionArrayForArray:(NSArray *)array;
+ (NSArray *)getAlphabeticalTableViewSectionArrayForArray:(NSArray *)array;

@end
