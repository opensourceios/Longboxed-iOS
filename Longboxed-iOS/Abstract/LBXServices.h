//
//  LBXServices.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/13/15.
//  Copyright © 2015 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBXServices : NSObject

+ (void)setSessionUUID;
+ (NSString *)getSessionUUID;
+ (void)setUserID;
+ (NSString *)getUserID;
+ (NSString *)crashFilePath;

+ (NSPredicate *)thisWeekPredicateWithParentCheck:(BOOL)parent;
+ (NSPredicate *)nextWeekPredicateWithParentCheck:(BOOL)parent;

@end
