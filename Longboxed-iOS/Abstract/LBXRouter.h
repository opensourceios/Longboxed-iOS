//
//  LBXRouter.h
//  Longboxed-iOS
//
//  Created by johnrhickey on 7/8/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit.h>

@interface LBXRouter : NSObject

@property (nonatomic, copy) NSString *baseURLString;

- (RKRouter *)routerWithQueryParameters:(NSDictionary *)parameters;

@end
