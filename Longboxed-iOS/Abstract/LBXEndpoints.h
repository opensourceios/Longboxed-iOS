//
//  LBXEndpoints.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBXEndpoints : NSObject

+ (NSString *)baseURLString;

// Dictionary with all the endpoints and the respective titles from
// http://docs.longboxed.apiary.io
+ (NSDictionary *)endpoints;

@end
