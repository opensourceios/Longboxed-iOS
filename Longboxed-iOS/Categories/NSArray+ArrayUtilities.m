//
//  NSArray+ArrayUtilities.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "NSArray+ArrayUtilities.h"

@implementation NSArray (ArrayUtilities)

+ (NSArray *)sortedArray:(NSArray *)array basedOffObjectProperty:(NSString *)property
{
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:property
                                                 ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    return [array sortedArrayUsingDescriptors:sortDescriptors];
}

@end
