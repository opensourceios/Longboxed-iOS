//
//  DatabaseManager.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/7/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBXDatabaseManager : NSObject

+ (void)flushDatabase;
+ (void)setupRestKit;

@end
